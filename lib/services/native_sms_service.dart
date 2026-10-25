import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/validators.dart';
import 'diagnostic_logger.dart';

class NativeSmsResult {
  final bool success;
  final String recipient;
  final String sentStatus; // 'sent_to_network', 'sent_unacknowledged', 'delivered_confirmed', 'failed', 'permission_denied'
  final bool isDeliveredConfirmed; // true ONLY when verified carrier DLR is received
  final int? partsCount;
  final String? errorCode; // 'NO_SIM_CARD', 'NO_SERVICE', 'RADIO_OFF', 'PERMISSION_DENIED', etc.
  final String? error;

  NativeSmsResult({
    required this.success,
    required this.recipient,
    this.sentStatus = 'unknown',
    this.isDeliveredConfirmed = false,
    this.partsCount,
    this.errorCode,
    this.error,
  });

  bool get isAccepted => success;

  Map<String, dynamic> toMap() => {
    'success': success,
    'recipient': recipient,
    'sentStatus': sentStatus,
    'isDeliveredConfirmed': isDeliveredConfirmed,
    'partsCount': partsCount,
    'errorCode': errorCode,
    'error': error,
  };
}

class NativeSmsService {
  static final NativeSmsService _instance = NativeSmsService._internal();
  factory NativeSmsService() => _instance;
  NativeSmsService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.SafeHer.app/native_sms',
  );

  /// Check whether the Android app has SEND_SMS permission
  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    try {
      final res = await _channel.invokeMethod<bool>('hasSmsPermission');
      return res ?? false;
    } catch (e) {
      debugPrint('[NativeSmsService] hasPermission error: $e');
      return false;
    }
  }

  Future<bool> hasSmsPermission() => hasPermission();

  /// Request runtime SEND_SMS permission from the user
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      final res = await _channel.invokeMethod<bool>('requestSmsPermission');
      return res ?? false;
    } catch (e) {
      debugPrint('[NativeSmsService] requestPermission error: $e');
      return false;
    }
  }

  Future<bool> requestSmsPermission() => requestPermission();

  /// Sends a background SMS directly through the device SIM card with callbacks
  Future<NativeSmsResult> sendDirectSms({
    required String phoneNumber,
    required String message,
    String? incidentId,
  }) async {
    final cleanPhone = AppValidators.normalizeForSms(phoneNumber);
    if (cleanPhone.isEmpty) {
      return NativeSmsResult(
        success: false,
        recipient: phoneNumber,
        sentStatus: 'failed',
        errorCode: 'INVALID_PHONE',
        error: 'Phone number is empty or invalid.',
      );
    }

    if (kIsWeb) {
      return NativeSmsResult(
        success: false,
        recipient: cleanPhone,
        sentStatus: 'unsupported_web',
        errorCode: 'WEB_PLATFORM',
        error: 'Background native SMS is not supported on web platform.',
      );
    }

    try {
      final params = <String, dynamic>{
        'phoneNumber': cleanPhone,
        'message': message,
      };
      if (incidentId != null) {
        params['incidentId'] = incidentId;
      }

      final result = await _channel.invokeMapMethod<String, dynamic>(
        'sendDirectSms',
        params,
      );

      if (result != null) {
        final res = NativeSmsResult(
          success: result['success'] == true,
          recipient: cleanPhone,
          sentStatus: result['sentStatus']?.toString() ??
              (result['success'] == true ? 'sent_to_network' : 'failed'),
          isDeliveredConfirmed: result['isDeliveredConfirmed'] == true,
          partsCount: result['partsCount'] as int?,
          errorCode: result['errorCode']?.toString(),
          error: result['error']?.toString(),
        );

        DiagnosticLogger().logSmsAcceptedByRadio(
          recipient: cleanPhone,
          success: res.success,
          sentStatus: res.sentStatus,
          errorCode: res.errorCode,
          partsCount: res.partsCount,
        );

        return res;
      }

      final fallback = NativeSmsResult(
        success: false,
        recipient: cleanPhone,
        sentStatus: 'no_response',
        errorCode: 'NULL_RESULT',
        error: 'No response received from native Android SMS radio.',
      );
      DiagnosticLogger().logSmsAcceptedByRadio(
        recipient: cleanPhone,
        success: false,
        errorCode: fallback.errorCode,
      );
      return fallback;
    } catch (e) {
      debugPrint('[NativeSmsService] sendDirectSms exception for $cleanPhone: $e');
      final errRes = NativeSmsResult(
        success: false,
        recipient: cleanPhone,
        sentStatus: 'exception',
        errorCode: 'CHANNEL_EXCEPTION',
        error: e.toString(),
      );
      DiagnosticLogger().logSmsAcceptedByRadio(
        recipient: cleanPhone,
        success: false,
        errorCode: errRes.errorCode,
      );
      return errRes;
    }
  }

  /// Sends background emergency SMS to multiple recipients with bounded concurrency.
  /// If one fails, it continues with the remaining contacts.
  Future<List<NativeSmsResult>> sendEmergencyAlertBatch({
    required List<String> phoneNumbers,
    required String message,
    String? incidentId,
  }) async {
    final List<NativeSmsResult> results = [];

    // 1. Ensure permission is available
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      final granted = await requestPermission();
      if (!granted) {
        for (final phone in phoneNumbers) {
          results.add(
            NativeSmsResult(
              success: false,
              recipient: phone,
              sentStatus: 'permission_denied',
              errorCode: 'PERMISSION_DENIED',
              error: 'SEND_SMS permission was denied by user in Android settings.',
            ),
          );
        }
        return results;
      }
    }

    // 2. Dispatch SMS with short stagger to avoid radio buffer congestion
    for (final phone in phoneNumbers) {
      final clean = AppValidators.normalizeForSms(phone);
      if (clean.isEmpty) continue;

      final res = await sendDirectSms(
        phoneNumber: clean,
        message: message,
        incidentId: incidentId,
      );
      results.add(res);

      // Short 60ms non-blocking stagger so modem radio can queue each intent safely
      if (phoneNumbers.length > 1) {
        await Future.delayed(const Duration(milliseconds: 60));
      }
    }

    return results;
  }
}
