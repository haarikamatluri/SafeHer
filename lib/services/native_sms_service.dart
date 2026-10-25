import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeSmsResult {
  final bool success;
  final String recipient;
  final String sentStatus; // 'sent_to_network', 'sent_unacknowledged', 'failed'
  final bool
  isDeliveredConfirmed; // true ONLY when verified carrier DLR is received
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
  }) async {
    if (kIsWeb) {
      return NativeSmsResult(
        success: false,
        recipient: phoneNumber,
        sentStatus: 'unsupported_web',
        errorCode: 'WEB_PLATFORM',
        error: 'Background native SMS is not supported on web.',
      );
    }

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'sendDirectSms',
        {'phoneNumber': phoneNumber, 'message': message},
      );

      if (result != null) {
        return NativeSmsResult(
          success: result['success'] == true,
          recipient: phoneNumber,
          sentStatus:
              result['sentStatus']?.toString() ??
              (result['success'] == true ? 'sent_to_network' : 'failed'),
          isDeliveredConfirmed: result['isDeliveredConfirmed'] == true,
          partsCount: result['partsCount'] as int?,
          errorCode: result['errorCode']?.toString(),
          error: result['error']?.toString(),
        );
      }

      return NativeSmsResult(
        success: false,
        recipient: phoneNumber,
        sentStatus: 'no_response',
        errorCode: 'NULL_RESULT',
        error: 'No response received from native Android SMS manager.',
      );
    } catch (e) {
      debugPrint(
        '[NativeSmsService] sendDirectSms exception for $phoneNumber: $e',
      );
      return NativeSmsResult(
        success: false,
        recipient: phoneNumber,
        sentStatus: 'exception',
        errorCode: 'CHANNEL_EXCEPTION',
        error: e.toString(),
      );
    }
  }

  /// Sends background emergency SMS to multiple recipients sequentially
  Future<List<NativeSmsResult>> sendEmergencyAlertBatch({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    final List<NativeSmsResult> results = [];

    // Ensure permission is available
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
              error: 'SEND_SMS permission was denied by the user in Android settings.',
            ),
          );
        }
        return results;
      }
    }

    for (final phone in phoneNumbers) {
      if (phone.trim().isEmpty) continue;
      final res = await sendDirectSms(phoneNumber: phone, message: message);
      results.add(res);
      // Small pause between multiple SMS dispatches to avoid carrier buffer congestion
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return results;
  }
}
