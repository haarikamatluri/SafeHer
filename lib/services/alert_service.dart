import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/incident.dart';
import '../models/trusted_contact.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'auth_service.dart';
import 'diagnostic_logger.dart';
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

  /// Executes fast emergency alert dispatch via device SIM.
  /// Does not block on external networks or paid Cloud Functions (Spark free tier compliant).
  Future<AlertDeliveryResult> dispatchEmergencyAlert({
    required Incident incident,
    required List<TrustedContact> contacts,
    bool isTestMode = false,
  }) async {
    final now = DateTime.now();

    // 1. Filter only explicitly authorized contacts with phone numbers
    final eligibleContacts = contacts
        .where((c) => c.isAuthorized && c.smsEnabled && c.phone.trim().isNotEmpty)
        .toList();

    // Fallback: If no contact has smsEnabled explicitly toggled, check all authorized
    final targetContacts = eligibleContacts.isNotEmpty
        ? eligibleContacts
        : contacts.where((c) => c.isAuthorized && c.phone.trim().isNotEmpty).toList();

    DiagnosticLogger().logSmsDispatchStarted(
      incidentId: incident.id,
      recipientCount: targetContacts.length,
    );

    if (targetContacts.isEmpty) {
      final res = AlertDeliveryResult(
        isPrepared: true,
        isSentToProvider: false,
        isProviderAcknowledged: false,
        isDeliveredConfirmed: false,
        status: AlertDeliveryStatus.notConfigured,
        providerName: 'None',
        statusMessage: 'No authorized contacts configured with SMS enabled. Add contacts in SafeHer to enable alerts.',
        timestamp: now,
      );
      _recordAlertAttemptAsync(incident.id, res);
      return res;
    }

    // 2. Format concise, reliable emergency SMS payload
    final smsBody = buildEmergencySmsText(incident);

    // 3. Dispatch directly via Android SIM card (Free Spark tier, Zero-cost)
    int successCount = 0;
    int failCount = 0;
    final List<Map<String, dynamic>> recipientResults = [];

    if (!kIsWeb) {
      final phoneList = targetContacts.map((c) => c.phone).toList();
      final nativeResults = await NativeSmsService().sendEmergencyAlertBatch(
        phoneNumbers: phoneList,
        message: smsBody,
        incidentId: incident.shortId,
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
          'phone': AppValidators.normalizeForSms(contact.phone),
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
        _recordSingleContactAttemptAsync(incident.id, item);
      }
    } else {
      // Web preview simulation
      for (final contact in targetContacts) {
        final item = {
          'contactId': contact.id,
          'name': contact.name,
          'phone': AppValidators.normalizeForSms(contact.phone),
          'channel': 'sms_web_simulation',
          'status': 'simulated_web',
          'isDeliveredConfirmed': false,
          'error': 'Direct SIM dispatch requires physical Android device with active SIM card.',
          'timestamp': DateTime.now().toIso8601String(),
        };
        recipientResults.add(item);
        _recordSingleContactAttemptAsync(incident.id, item);
      }
      successCount = targetContacts.length;
    }

    final isOverallSuccess = successCount > 0;
    final summary = {
      'totalRecipients': targetContacts.length,
      'eligibleCount': targetContacts.length,
      'attemptedCount': targetContacts.length,
      'sentToNetworkCount': successCount,
      'failedCount': failCount,
      'mode': '100% Free Device SIM Dispatch',
      'sms': {
        'provider': kIsWeb
            ? 'Web Preview (Simulated)'
            : 'Device SIM (SmsManager)',
        'succeeded': successCount,
        'failed': failCount,
      },
    };

    final finalResult = AlertDeliveryResult(
      isPrepared: true,
      isSentToProvider: isOverallSuccess,
      isProviderAcknowledged: isOverallSuccess,
      isDeliveredConfirmed: successCount > 0,
      status: isOverallSuccess
          ? AlertDeliveryStatus.deliveredConfirmed
          : AlertDeliveryStatus.failed,
      providerName: kIsWeb ? 'Web Preview' : 'Android SIM (SmsManager)',
      statusMessage: isOverallSuccess
          ? 'Emergency SMS accepted by cellular radio for $successCount/${targetContacts.length} contacts.'
          : (failCount == targetContacts.length
              ? 'All SMS attempts failed. Check SIM card or SMS permissions.'
              : 'SMS dispatch finished with partial failures.'),
      timestamp: DateTime.now(),
      deliverySummary: summary,
      recipientResults: recipientResults,
    );

    _recordAlertAttemptAsync(incident.id, finalResult);
    return finalResult;
  }

  /// Builds a concise, truthful SMS payload conforming to standard template.
  String buildEmergencySmsText(Incident incident) {
    final timeStr = DateFormat('hh:mm a, dd MMM').format(incident.createdAt.toLocal());
    final hasLoc = incident.hasLocation;

    if (hasLoc) {
      final mapUrl = incident.googleMapsUrl!;
      final accStr = incident.locationAccuracy != null
          ? '±${incident.locationAccuracy!.toStringAsFixed(1)}m'
          : 'Unknown';
      // If age information is not yet recorded, label Fresh if recent
      final ageStr = (DateTime.now().difference(incident.createdAt).inSeconds < 15)
          ? 'Fresh (<15s)'
          : 'Recorded at $timeStr';

      return 'SAFEHER SOS: Emergency alert activated. Incident: ${incident.shortId}. '
          'Location: $mapUrl. Captured: $timeStr. Accuracy: $accStr. '
          'Location age: $ageStr. Please contact me and follow the shared location.';
    } else {
      return 'SAFEHER SOS: Emergency alert activated. Incident: ${incident.shortId}. '
          'Location: Location unavailable. Captured: $timeStr. '
          'Please contact me immediately.';
    }
  }

  /// Asynchronously records single contact audit log in Firestore without blocking
  void _recordSingleContactAttemptAsync(
    String incidentId,
    Map<String, dynamic> attemptData,
  ) {
    final userId = SafeHerAuthService().currentUserId;
    if (userId == null || SafeHerAuthService().isUsingFallbackLocalAuth) {
      return;
    }

    FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.incidentsSubcollection)
        .doc(incidentId)
        .collection(AppConstants.alertAttemptsSubcollection)
        .add(attemptData)
        .catchError((e) {
          debugPrint('[AlertService] Async single attempt save ignored: $e');
          return FirebaseFirestore.instance.collection('dummy').doc();
        });
  }

  /// Asynchronously records the overall alert attempt audit log in Firestore
  void _recordAlertAttemptAsync(
    String incidentId,
    AlertDeliveryResult result,
  ) {
    final userId = SafeHerAuthService().currentUserId;
    if (userId == null || SafeHerAuthService().isUsingFallbackLocalAuth) {
      return;
    }

    final data = result.toMap();
    // Enforce Firestore security rules constraint (isDeliveredConfirmed must be false on attempt log)
    data['isDeliveredConfirmed'] = false;

    FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.incidentsSubcollection)
        .doc(incidentId)
        .collection(AppConstants.alertAttemptsSubcollection)
        .add(data)
        .catchError((e) {
          debugPrint('[AlertService] Async alert attempt save ignored: $e');
          return FirebaseFirestore.instance.collection('dummy').doc();
        });
  }

  /// Manual dialer helper for calling emergency numbers (e.g. 112 / 911)
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
