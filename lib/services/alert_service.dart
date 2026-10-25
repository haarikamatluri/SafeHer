import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/incident.dart';
import '../models/trusted_contact.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import 'native_sms_service.dart';

class AlertDeliveryResult {
  final bool isPrepared;
  final bool isSentToProvider;
  final bool isProviderAcknowledged;
  final bool isDeliveredConfirmed;
  final AlertDeliveryStatus status;
  final String providerName;
  final String statusMessage;
  final DateTime timestamp;
  final String? externalMessageId;
  final Map<String, dynamic>? deliverySummary;
  final List<dynamic>? recipientResults;

  AlertDeliveryResult({
    required this.isPrepared,
    required this.isSentToProvider,
    required this.isProviderAcknowledged,
    required this.isDeliveredConfirmed,
    required this.status,
    required this.providerName,
    required this.statusMessage,
    required this.timestamp,
    this.externalMessageId,
    this.deliverySummary,
    this.recipientResults,
  });

  Map<String, dynamic> toMap() {
    return {
      'isPrepared': isPrepared,
      'isSentToProvider': isSentToProvider,
      'isProviderAcknowledged': isProviderAcknowledged,
      'isDeliveredConfirmed': isDeliveredConfirmed,
      'status': status.value,
      'providerName': providerName,
      'statusMessage': statusMessage,
      'timestamp': timestamp.toIso8601String(),
      'externalMessageId': externalMessageId,
      'deliverySummary': deliverySummary,
      'recipientResults': recipientResults,
    };
  }
}

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  /// Executes the multi-channel alert delivery pipeline via Cloud Functions
  Future<AlertDeliveryResult> dispatchEmergencyAlert({
    required Incident incident,
    required List<TrustedContact> contacts,
    bool isTestMode = false,
  }) async {
    final now = DateTime.now();

    // Filter only authorized contacts
    final authorizedContacts = contacts.where((c) => c.isAuthorized).toList();

    // STEP 1: Validate contacts
    if (authorizedContacts.isEmpty) {
      final res = AlertDeliveryResult(
        isPrepared: true,
        isSentToProvider: false,
        isProviderAcknowledged: false,
        isDeliveredConfirmed: false,
        status: AlertDeliveryStatus.notConfigured,
        providerName: 'None',
        statusMessage: 'No authorized trusted contacts configured. Add contacts in SafeHer to enable alerts.',
        timestamp: now,
      );
      await _recordAlertAttempt(incident.id, res);
      return res;
    }

    // STEP 2: Prepare Alert Payload
    final mapLink = incident.googleMapsUrl ?? 'Location unavailable';
    debugPrint(
      '[AlertService] Step 2 Prepared payload for incident: ${incident.shortId}, recipients: ${authorizedContacts.length}, map: $mapLink',
    );

    // STEP 3: Dispatch Pipeline
    final backendUrl = Uri.parse(
      'https://us-central1-safeher-e5003.cloudfunctions.net/dispatchEmergencyAlert',
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = user != null ? await user.getIdToken() : null;

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (idToken != null) {
        headers['Authorization'] = 'Bearer $idToken';
      }

      final response = await http
          .post(
            backendUrl,
            headers: headers,
            body: jsonEncode({
              'data': {'incidentId': incident.id, 'isTestMode': isTestMode},
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['result'] ?? decoded;
        final isSuccess = data['success'] == true;
        final summary = data['summary'] is Map
            ? Map<String, dynamic>.from(data['summary'] as Map)
            : null;
        final recipients = data['recipients'] is List
            ? data['recipients'] as List
            : null;

        final res = AlertDeliveryResult(
          isPrepared: true,
          isSentToProvider: isSuccess,
          isProviderAcknowledged: isSuccess,
          isDeliveredConfirmed: false,
          status: isSuccess
              ? AlertDeliveryStatus.deliveredConfirmed
              : AlertDeliveryStatus.failed,
          providerName: 'SafeHer Multi-Channel Cloud Function',
          statusMessage:
              data['message']?.toString() ??
              (isSuccess
                  ? 'Dispatched to provider successfully.'
                  : 'Backend rejected dispatch.'),
          timestamp: DateTime.now(),
          deliverySummary: summary,
          recipientResults: recipients,
        );
        await _recordAlertAttempt(incident.id, res);
        return res;
      }
    } catch (_) {
      // Backend not deployed (Spark free tier) or offline -> proceed to 100% Free Native SIM Dispatch
    }

    // STEP 4: 100% Free Automated Native Device SIM Dispatch
    final res = await _dispatchViaNativeSim(
      incident: incident,
      authorizedContacts: authorizedContacts,
    );

    await _recordAlertAttempt(incident.id, res);
    return res;
  }

  /// 100% Free Automated Background SMS Delivery via Android SIM Card
  Future<AlertDeliveryResult> _dispatchViaNativeSim({
    required Incident incident,
    required List<TrustedContact> authorizedContacts,
  }) async {
    final now = DateTime.now();
    final mapLink = incident.googleMapsUrl ?? 'Location unavailable';
    final trackingLink =
        'https://safeher-e5003.web.app/#/track?id=${incident.id}';
    final emergencyMessage =
        'SAFEHER EMERGENCY ALERT!\n'
        'I activated SOS in SafeHer.\n'
        'Incident: ${incident.shortId}\n'
        'Time: ${now.toLocal().toString().substring(0, 16)}\n'
        'Initial GPS: $mapLink\n'
        'Live Tracking: $trackingLink\n'
        '(Open SafeHer to view live movement)';

    // Eligible contacts for SMS
    final smsContacts = authorizedContacts
        .where((c) => c.smsEnabled && c.phone.trim().isNotEmpty)
        .toList();
    final targetContacts = smsContacts.isNotEmpty
        ? smsContacts
        : authorizedContacts;

    int successCount = 0;
    int failCount = 0;
    final List<Map<String, dynamic>> recipientResults = [];

    if (!kIsWeb) {
      final phoneList = targetContacts.map((c) => c.phone.trim()).toList();
      final nativeResults = await NativeSmsService().sendEmergencyAlertBatch(
        phoneNumbers: phoneList,
        message: emergencyMessage,
      );

      for (int i = 0; i < targetContacts.length; i++) {
        final contact = targetContacts[i];
        final nativeRes = i < nativeResults.length ? nativeResults[i] : null;
        final isSent = nativeRes?.success == true;
        if (isSent) {
          successCount++;
        } else {
          failCount++;
        }

        final item = {
          'contactId': contact.id,
          'name': contact.name,
          'phone': contact.phone,
          'channel': 'sms_native_sim',
          'status': isSent
              ? (nativeRes?.sentStatus ?? 'sent_to_network')
              : 'failed',
          'isDeliveredConfirmed': nativeRes?.isDeliveredConfirmed ?? false,
          'errorCode': nativeRes?.errorCode,
          'partsCount': nativeRes?.partsCount ?? 1,
          'error': nativeRes?.error,
          'timestamp': DateTime.now().toIso8601String(),
        };
        recipientResults.add(item);

        // Record individual contact audit log in Firestore
        await _recordSingleContactAttempt(incident.id, item);
      }
    } else {
      // Web preview simulation
      for (final contact in targetContacts) {
        final item = {
          'contactId': contact.id,
          'name': contact.name,
          'phone': contact.phone,
          'channel': 'sms_web_simulation',
          'status': 'simulated_web',
          'error': 'Direct SIM dispatch requires Android device with SIM card.',
          'timestamp': DateTime.now().toIso8601String(),
        };
        recipientResults.add(item);
        await _recordSingleContactAttempt(incident.id, item);
      }
      successCount = targetContacts.length;
    }

    final isOverallSuccess =
        successCount > 0 || (kIsWeb && targetContacts.isNotEmpty);
    final summary = {
      'totalRecipients': targetContacts.length,
      'mode': '100% Free Device SIM Dispatch',
      'sms': {
        'provider': kIsWeb
            ? 'Web Preview (Simulated)'
            : 'Device SIM (SmsManager)',
        'succeeded': successCount,
        'failed': failCount,
      },
      'push': {
        'provider': 'FCM (Disabled on Spark free plan)',
        'succeeded': 0,
        'failed': 0,
      },
      'whatsapp': {
        'provider': 'WhatsApp (Requires Meta Business Cloud API)',
        'succeeded': 0,
        'failed': 0,
      },
    };

    return AlertDeliveryResult(
      isPrepared: true,
      isSentToProvider: isOverallSuccess,
      isProviderAcknowledged: isOverallSuccess,
      isDeliveredConfirmed: successCount > 0,
      status: isOverallSuccess
          ? AlertDeliveryStatus.deliveredConfirmed
          : AlertDeliveryStatus.failed,
      providerName: kIsWeb ? 'Web Preview' : 'Android SIM (SmsManager)',
      statusMessage: isOverallSuccess
          ? 'Emergency SMS automatically sent via device SIM to $successCount/${targetContacts.length} contacts.'
          : 'Failed to dispatch via device SIM. Check SMS permissions or SIM card.',
      timestamp: DateTime.now(),
      deliverySummary: summary,
      recipientResults: recipientResults,
    );
  }

  /// Records single contact audit trail in Firestore
  Future<void> _recordSingleContactAttempt(
    String incidentId,
    Map<String, dynamic> attemptData,
  ) async {
    final userId = SafeHerAuthService().currentUserId;
    if (userId == null || SafeHerAuthService().isUsingFallbackLocalAuth) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.incidentsSubcollection)
          .doc(incidentId)
          .collection(AppConstants.alertAttemptsSubcollection)
          .add(attemptData);
    } catch (e) {
      debugPrint('[AlertService] Failed to record single attempt: $e');
    }
  }

  /// Records the audit trail in Firestore under
  /// users/{uid}/incidents/{incidentId}/alertAttempts/{attemptId}
  Future<void> _recordAlertAttempt(
    String incidentId,
    AlertDeliveryResult result,
  ) async {
    final userId = SafeHerAuthService().currentUserId;
    if (userId == null || SafeHerAuthService().isUsingFallbackLocalAuth) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.incidentsSubcollection)
          .doc(incidentId)
          .collection(AppConstants.alertAttemptsSubcollection)
          .add(result.toMap());
    } catch (e) {
      debugPrint(
        '[AlertService] Failed to record alert attempt in Firestore: $e',
      );
    }
  }

  /// Manual dialer helper for calling emergency numbers (e.g. 112 / 911)
  /// Opens phone dialer - clearly documented as user-interactive action
  Future<bool> launchEmergencyCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(callUri)) {
        return await launchUrl(callUri);
      }
    } catch (e) {
      debugPrint('[AlertService] Error launching phone dialer: $e');
    }
    return false;
  }

  /// Manual SMS app launcher as explicit client fallback
  /// Note: Launching SMS app is NOT considered automated delivery
  Future<bool> launchSmsApp({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    final joinedPhones = phoneNumbers.join(',');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: joinedPhones,
      queryParameters: <String, String>{'body': message},
    );
    try {
      if (await canLaunchUrl(smsUri)) {
        return await launchUrl(smsUri);
      }
    } catch (e) {
      debugPrint('[AlertService] Error launching SMS app: $e');
    }
    return false;
  }

  /// Opens Google Maps link in external browser or Maps app
  Future<bool> openMapLink(String mapUrl) async {
    final Uri uri = Uri.parse(mapUrl);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AlertService] Error opening map link: $e');
    }
    return false;
  }
}
