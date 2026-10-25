import 'package:flutter/foundation.dart';

/// Structured diagnostic logger for SafeHer emergency and journey pipelines.
/// Logs timestamped events with elapsed milliseconds from trigger.
/// NEVER logs passwords, auth tokens, or private credentials.
class DiagnosticLogger {
  static final DiagnosticLogger _instance = DiagnosticLogger._internal();
  factory DiagnosticLogger() => _instance;
  DiagnosticLogger._internal();

  DateTime? _sosStartTime;

  void logSosTapped({String source = 'sos_button'}) {
    _sosStartTime = DateTime.now();
    _log('SOS_TAPPED', {
      'source': source,
      'timestamp': _sosStartTime!.toIso8601String(),
    });
  }

  void logIncidentCreated({
    required String incidentId,
    required String userId,
    required bool isSynced,
  }) {
    _log('INCIDENT_CREATED', {
      'incidentId': incidentId,
      'userId': userId,
      'isSynced': isSynced,
    });
  }

  void logLocationRequested({required Duration timeout}) {
    _log('LOCATION_REQUESTED', {
      'timeoutSeconds': timeout.inSeconds,
    });
  }

  void logLocationFixReceived({
    required bool isFresh,
    required String source,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    Duration? age,
  }) {
    _log('LOCATION_FIX_RECEIVED', {
      'isFresh': isFresh,
      'source': source,
      'lat': latitude != null ? double.parse(latitude.toStringAsFixed(5)) : null,
      'lng': longitude != null ? double.parse(longitude.toStringAsFixed(5)) : null,
      'accuracyMeters': accuracyMeters,
      'ageSeconds': age?.inSeconds,
    });
  }

  void logSmsDispatchStarted({
    required String incidentId,
    required int recipientCount,
  }) {
    _log('SMS_DISPATCH_STARTED', {
      'incidentId': incidentId,
      'recipientCount': recipientCount,
    });
  }

  void logSmsAcceptedByRadio({
    required String recipient,
    required bool success,
    String? sentStatus,
    String? errorCode,
    int? partsCount,
  }) {
    _log('SMS_ACCEPTED_BY_RADIO', {
      'recipient': _maskPhone(recipient),
      'success': success,
      'sentStatus': sentStatus,
      'errorCode': errorCode,
      'partsCount': partsCount,
    });
  }

  void logTrackingStarted({
    required String incidentId,
    required bool isServiceEnabled,
  }) {
    _log('TRACKING_STARTED', {
      'incidentId': incidentId,
      'isServiceEnabled': isServiceEnabled,
    });
  }

  void logFirestoreSynced({
    required String collection,
    required String docId,
    required bool success,
    String? error,
  }) {
    final payload = <String, dynamic>{
      'collection': collection,
      'docId': docId,
      'success': success,
    };
    if (error != null) {
      payload['error'] = error;
    }
    _log('FIRESTORE_SYNCED', payload);
  }

  void logFailure({
    required String stage,
    required String reason,
    String? incidentId,
  }) {
    final payload = <String, dynamic>{
      'stage': stage,
      'reason': reason,
    };
    if (incidentId != null) {
      payload['incidentId'] = incidentId;
    }
    _log('FAILURE', payload);
  }

  void _log(String event, Map<String, dynamic> data) {
    final now = DateTime.now();
    final elapsedMs = _sosStartTime != null
        ? now.difference(_sosStartTime!).inMilliseconds
        : 0;

    final entry = StringBuffer()
      ..write('[SAFEHER_DIAGNOSTIC] [')
      ..write(now.toIso8601String())
      ..write('] [T+')
      ..write(elapsedMs)
      ..write('ms] ')
      ..write(event)
      ..write(': ')
      ..write(data);

    debugPrint(entry.toString());
  }

  String _maskPhone(String phone) {
    final clean = phone.trim();
    if (clean.length <= 4) return clean;
    final start = clean.substring(0, 3);
    final end = clean.substring(clean.length - 2);
    return '$start***$end';
  }
}
