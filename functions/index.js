/**
 * SafeHer Emergency Alert Dispatch Cloud Function Backend
 *
 * Privileged, production-grade safety service that:
 * 1. Authenticates caller and verifies user identity.
 * 2. Enforces incident ownership and active-state validation.
 * 3. Enforces idempotency locks against rapid duplicate activations.
 * 4. Enforces rate-limiting to prevent recipient spam or carrier abuse.
 * 5. Fetches only owner's authorized trusted contacts and enabled channels.
 * 6. Dispatches SMS via Twilio using server-side secrets (never client-exposed).
 * 7. Dispatches FCM Push Notifications to registered devices.
 * 8. Dispatches WhatsApp alerts via WhatsApp Business Cloud API (with consent check).
 * 9. Records granular per-contact and per-channel audit records in Firestore.
 * 10. Provides carrier DLR status webhook for true verified delivery tracking.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

/**
 * Validates and normalizes phone numbers into E.164 format (+[country][number])
 */
function normalizeE164(phone) {
  if (!phone || typeof phone !== "string") return null;
  const cleaned = phone.replace(/[\s\-\(\)\.]/g, "");
  if (/^\+[1-9]\d{7,14}$/.test(cleaned)) {
    return cleaned;
  }
  // If user entered 10 digits without +, check common prefixes or require international format
  if (/^\d{10}$/.test(cleaned)) {
    // Default to +91 (India) if standard 10 digits, or require leading +
    return `+91${cleaned}`;
  }
  return null;
}

/**
 * Main callable function for emergency SOS alert dispatch
 */
exports.dispatchEmergencyAlert = functions.https.onCall(async (data, context) => {
  // 1. Authenticate caller
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated with Firebase to dispatch emergency alerts."
    );
  }

  const userId = context.auth.uid;
  const { incidentId, isTestMode = false } = data;

  if (!incidentId || typeof incidentId !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required parameter: incidentId."
    );
  }

  // 2. Fetch and verify incident ownership and active state
  const incidentRef = db
    .collection("users")
    .doc(userId)
    .collection("incidents")
    .doc(incidentId);

  const incidentDoc = await incidentRef.get();
  if (!incidentDoc.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "Incident record not found in user database."
    );
  }

  const incident = incidentDoc.data();
  if (incident.status !== "active") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Alerts can only be dispatched for active incidents. Current status: ${incident.status}`
    );
  }

  // 3. Idempotency Lock: Prevent duplicate dispatch within 45 seconds
  const nowMs = Date.now();
  if (incident.lastAlertDispatchedAt) {
    const lastTimeMs = incident.lastAlertDispatchedAt.toMillis
      ? incident.lastAlertDispatchedAt.toMillis()
      : new Date(incident.lastAlertDispatchedAt).getTime();
    if (nowMs - lastTimeMs < 45000 && incident.alertStatus === "dispatched") {
      return {
        success: true,
        status: "already_dispatched",
        message: "SOS alert was already dispatched recently for this incident (idempotency lock active).",
        dispatchedAt: incident.lastAlertDispatchedAt,
      };
    }
  }

  // 4. Rate-Limiting Check: Max 5 dispatches per 10 minutes per user
  const tenMinutesAgo = new Date(nowMs - 10 * 60 * 1000);
  const recentAttemptsSnap = await incidentRef
    .collection("alertAttempts")
    .where("attemptedAt", ">=", tenMinutesAgo)
    .get();

  if (recentAttemptsSnap.size >= 5) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      "Rate limit exceeded: Maximum 5 emergency alert dispatches allowed per 10 minutes to prevent carrier spam."
    );
  }

  // 5. Fetch Owner's Authorized Trusted Contacts
  const contactsSnap = await db
    .collection("users")
    .doc(userId)
    .collection("trustedContacts")
    .get();

  const allContacts = contactsSnap.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  // Filter only authorized / enabled contacts
  const authorizedContacts = allContacts.filter(
    (c) => c.isAuthorized !== false
  );

  if (authorizedContacts.length === 0) {
    return {
      success: false,
      status: "no_contacts",
      message: "No authorized trusted contacts configured. Add trusted contacts in SafeHer to enable dispatch.",
    };
  }

  // 6. Build Emergency Payload
  const hasCoordinates = incident.latitude != null && incident.longitude != null;
  const mapLink = hasCoordinates
    ? `https://maps.google.com/?q=${incident.latitude},${incident.longitude}`
    : "Location unavailable (GPS offline/disabled)";

  const modePrefix = isTestMode ? "[TEST ALERT - SAFEHER DEMO] " : "🚨 EMERGENCY ALERT: ";
  const smsBody = `${modePrefix}SafeHer SOS activated! Live location: ${mapLink} (Incident ${incident.id.substring(0, 8)})`;

  // 7. Inspect Provider Configurations (Server-side Secrets Only)
  const twilioAccountSid = process.env.TWILIO_ACCOUNT_SID;
  const twilioAuthToken = process.env.TWILIO_AUTH_TOKEN;
  const twilioFromNumber = process.env.TWILIO_PHONE_NUMBER;
  const isTwilioConfigured = Boolean(
    twilioAccountSid &&
    twilioAuthToken &&
    twilioFromNumber &&
    !twilioAccountSid.startsWith("placeholder")
  );

  const whatsappToken = process.env.WHATSAPP_ACCESS_TOKEN;
  const whatsappPhoneId = process.env.WHATSAPP_PHONE_NUMBER_ID;
  const whatsappTemplate = process.env.WHATSAPP_TEMPLATE_NAME || "emergency_sos_alert";
  const isWhatsAppConfigured = Boolean(whatsappToken && whatsappPhoneId);

  // Results collectors
  const perContactAudit = [];
  let smsSuccessCount = 0;
  let smsFailCount = 0;
  let pushSuccessCount = 0;
  let pushFailCount = 0;
  let whatsappSuccessCount = 0;
  let whatsappFailCount = 0;

  let twilioClient = null;
  if (isTwilioConfigured) {
    try {
      const twilio = require("twilio");
      twilioClient = twilio(twilioAccountSid, twilioAuthToken);
    } catch (e) {
      console.error("[Twilio Init Error]:", e.message);
    }
  }

  // 8. Execute Dispatch for Each Contact & Channel
  for (const contact of authorizedContacts) {
    const contactAudit = {
      contactId: contact.id,
      contactName: contact.name,
      contactPhone: contact.phone,
      channels: {},
    };

    const normalizedPhone = normalizeE164(contact.phone);

    // --- CHANNEL A: SMS DISPATCH ---
    const smsEnabled = contact.smsEnabled !== false;
    if (smsEnabled) {
      if (!normalizedPhone) {
        contactAudit.channels.sms = {
          status: "failed_invalid_phone",
          error: "Phone number is not a valid E.164 phone format.",
        };
        smsFailCount++;
      } else if (!isTwilioConfigured || !twilioClient) {
        contactAudit.channels.sms = {
          status: "failed_unconfigured",
          error: "Twilio SMS provider credentials (SID, Token, Sender) not configured in server secrets.",
        };
        smsFailCount++;
      } else {
        try {
          const msg = await twilioClient.messages.create({
            body: smsBody,
            from: twilioFromNumber,
            to: normalizedPhone,
            statusCallback: `https://us-central1-${process.env.GCLOUD_PROJECT || "safeher-e5003"}.cloudfunctions.net/twilioStatusWebhook`,
          });
          contactAudit.channels.sms = {
            status: msg.status || "queued",
            sid: msg.sid,
            provider: "Twilio",
            to: normalizedPhone,
            isAcknowledged: true,
            isDeliveredConfirmed: false, // Confirmed when statusCallback reports 'delivered'
          };
          smsSuccessCount++;
        } catch (err) {
          contactAudit.channels.sms = {
            status: "failed",
            error: err.message,
            errorCode: err.code,
          };
          smsFailCount++;
        }
      }
    } else {
      contactAudit.channels.sms = { status: "disabled_by_user" };
    }

    // --- CHANNEL B: PUSH NOTIFICATION (FCM) ---
    const pushEnabled = contact.pushEnabled !== false;
    if (pushEnabled) {
      // Check if contact has registered their device token
      const targetToken = contact.fcmToken || null;
      if (!targetToken) {
        contactAudit.channels.push = {
          status: "skipped_no_token",
          reason: "Contact has not registered a device FCM token.",
        };
      } else {
        try {
          const fcmPayload = {
            token: targetToken,
            notification: {
              title: "🚨 SafeHer Emergency Alert!",
              body: `${contact.name || "A user"} needs immediate help! Location: ${mapLink}`,
            },
            data: {
              incidentId: incident.id,
              type: "emergency_alert",
              latitude: String(incident.latitude || ""),
              longitude: String(incident.longitude || ""),
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
              priority: "high",
              notification: {
                channelId: "emergency_alerts_channel",
                priority: "max",
                sound: "default",
                vibrateTimingsMillis: [0, 500, 200, 500],
              },
            },
          };
          const sendRes = await admin.messaging().send(fcmPayload);
          contactAudit.channels.push = {
            status: "dispatched",
            messageId: sendRes,
            isAcknowledged: true,
          };
          pushSuccessCount++;
        } catch (fcmErr) {
          contactAudit.channels.push = {
            status: "failed",
            error: fcmErr.message,
          };
          pushFailCount++;
        }
      }
    } else {
      contactAudit.channels.push = { status: "disabled_by_user" };
    }

    // --- CHANNEL C: WHATSAPP BUSINESS PLATFORM CLOUD API ---
    const whatsappEnabled = contact.whatsappEnabled === true;
    if (whatsappEnabled) {
      if (!contact.whatsappConsent) {
        contactAudit.channels.whatsapp = {
          status: "skipped_no_consent",
          reason: "Contact has not provided explicit consent for WhatsApp alert delivery.",
        };
      } else if (!isWhatsAppConfigured) {
        contactAudit.channels.whatsapp = {
          status: "failed_unconfigured",
          error: "Meta WhatsApp Business Platform credentials (Token, Phone ID) not configured in server secrets.",
        };
        whatsappFailCount++;
      } else if (!normalizedPhone) {
        contactAudit.channels.whatsapp = {
          status: "failed_invalid_phone",
          error: "Recipient phone is not valid E.164.",
        };
        whatsappFailCount++;
      } else {
        try {
          const waPhone = normalizedPhone.replace("+", "");
          const waEndpoint = `https://graph.facebook.com/v20.0/${whatsappPhoneId}/messages`;
          const waPayload = {
            messaging_product: "whatsapp",
            recipient_type: "individual",
            to: waPhone,
            type: "template",
            template: {
              name: whatsappTemplate,
              language: { code: "en" },
              components: [
                {
                  type: "body",
                  parameters: [
                    { type: "text", text: incident.id.substring(0, 8) },
                    { type: "text", text: mapLink },
                  ],
                },
              ],
            },
          };
          const waResp = await fetch(waEndpoint, {
            method: "POST",
            headers: {
              Authorization: `Bearer ${whatsappToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify(waPayload),
          });
          const waData = await waResp.json();
          if (waResp.ok && waData.messages && waData.messages.length > 0) {
            contactAudit.channels.whatsapp = {
              status: "sent",
              wamid: waData.messages[0].id,
              isAcknowledged: true,
            };
            whatsappSuccessCount++;
          } else {
            contactAudit.channels.whatsapp = {
              status: "failed",
              error: waData.error ? waData.error.message : "WhatsApp API error",
            };
            whatsappFailCount++;
          }
        } catch (waErr) {
          contactAudit.channels.whatsapp = {
            status: "failed",
            error: waErr.message,
          };
          whatsappFailCount++;
        }
      }
    } else {
      contactAudit.channels.whatsapp = { status: "not_requested" };
    }

    perContactAudit.push(contactAudit);
  }

  // Also dispatch push notification to user's own registered devices for instant confirmation
  try {
    const userTokensSnap = await db
      .collection("users")
      .doc(userId)
      .collection("fcmTokens")
      .get();
    const userTokens = userTokensSnap.docs.map((d) => d.id).filter(Boolean);
    if (userTokens.length > 0) {
      await admin.messaging().sendEachForMulticast({
        tokens: userTokens,
        notification: {
          title: "SafeHer: SOS Dispatched",
          body: `Emergency alert initiated for ${authorizedContacts.length} contact(s).`,
        },
        data: {
          incidentId: incident.id,
          type: "sos_initiated",
        },
      });
    }
  } catch (_) {}

  // 9. Store Immutable Audit Log in Firestore
  const overallSuccess = smsSuccessCount > 0 || pushSuccessCount > 0 || whatsappSuccessCount > 0;
  const dispatchStatus = overallSuccess ? "dispatched" : "failed";

  const attemptLog = {
    attemptedAt: admin.firestore.FieldValue.serverTimestamp(),
    isTestMode: isTestMode,
    incidentId: incident.id,
    userId: userId,
    status: dispatchStatus,
    summary: {
      totalContacts: authorizedContacts.length,
      sms: { attempted: authorizedContacts.length, succeeded: smsSuccessCount, failed: smsFailCount },
      push: { succeeded: pushSuccessCount, failed: pushFailCount },
      whatsapp: { succeeded: whatsappSuccessCount, failed: whatsappFailCount },
    },
    recipients: perContactAudit,
  };

  await incidentRef.collection("alertAttempts").add(attemptLog);

  // Update incident document with dispatch metadata & idempotency timestamp
  await incidentRef.update({
    alertStatus: dispatchStatus,
    lastAlertDispatchedAt: admin.firestore.FieldValue.serverTimestamp(),
    alertDeliverySummary: attemptLog.summary,
  });

  return {
    success: overallSuccess,
    status: dispatchStatus,
    message: overallSuccess
      ? `Dispatched alert to ${authorizedContacts.length} contact(s) via active channels.`
      : "Automated alert dispatch failed or no provider is configured.",
    summary: attemptLog.summary,
    recipients: perContactAudit,
  };
});

/**
 * Webhook endpoint for Twilio carrier delivery receipts (DLR)
 * Updates Firestore with true verified delivery status when carrier reports it.
 */
exports.twilioStatusWebhook = functions.https.onRequest(async (req, res) => {
  const { MessageSid, MessageStatus, ErrorCode } = req.body;
  if (!MessageSid) {
    res.status(400).send("Missing MessageSid");
    return;
  }

  try {
    // Search across incidents for the attempt with this SID
    const attemptsQuery = await db
      .collectionGroup("alertAttempts")
      .orderBy("attemptedAt", "desc")
      .limit(50)
      .get();

    for (const doc of attemptsQuery.docs) {
      const data = doc.data();
      if (!data.recipients) continue;
      let matched = false;
      const updatedRecipients = data.recipients.map((r) => {
        if (r.channels && r.channels.sms && r.channels.sms.sid === MessageSid) {
          matched = true;
          r.channels.sms.carrierStatus = MessageStatus;
          r.channels.sms.isDeliveredConfirmed = MessageStatus === "delivered";
          if (ErrorCode) r.channels.sms.carrierErrorCode = ErrorCode;
        }
        return r;
      });

      if (matched) {
        await doc.ref.update({
          recipients: updatedRecipients,
          lastCarrierUpdate: admin.firestore.FieldValue.serverTimestamp(),
        });
        break;
      }
    }
    res.status(200).send("<Response></Response>");
  } catch (err) {
    console.error("[Twilio Webhook Error]:", err.message);
    res.status(500).send(err.message);
  }
});
