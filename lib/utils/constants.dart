class AppConstants {
  static const String appName = 'SafeHer';
  static const String appTagline = 'Your safety. Your control.';
  static const String appVersion = '1.0.0 (Hackathon MVP)';

  // Emergency numbers (India 112, US 911, Universal fallback 112)
  static const String defaultEmergencyNumber = '112';
  static const String womenHelplineNumber = '1091';

  // Firestore Collection paths
  static const String usersCollection = 'users';
  static const String contactsSubcollection = 'trustedContacts';
  static const String incidentsSubcollection = 'incidents';
  static const String checkinsSubcollection = 'checkins';
  static const String alertAttemptsSubcollection = 'alertAttempts';

  // Shared preferences keys
  static const String prefOnboardingCompleted = 'onboarding_completed';
  static const String prefActiveCheckin = 'active_checkin_data';
  static const String prefEmergencyNumber = 'emergency_number';
  static const String prefLocalIncidents = 'local_incidents_cache';
  static const String prefLocalContacts = 'local_contacts_cache';

  // Disclaimer text for honest safety reporting
  static const String honestyDisclaimer =
      'SafeHer logs your incidents and prepares map links for your trusted contacts. '
      'It does NOT automatically dispatch municipal emergency services (911/112) '
      'unless integrated with a verified public safety answering point (PSAP). '
      'In immediate danger, always dial your national emergency number directly.';
}

enum IncidentStatus {
  active,
  resolvedByUser,
  cancelled;

  String get value {
    switch (this) {
      case IncidentStatus.active:
        return 'active';
      case IncidentStatus.resolvedByUser:
        return 'resolved_by_user';
      case IncidentStatus.cancelled:
        return 'cancelled';
    }
  }

  static IncidentStatus fromString(String? val) {
    switch (val) {
      case 'resolved_by_user':
        return IncidentStatus.resolvedByUser;
      case 'cancelled':
        return IncidentStatus.cancelled;
      case 'active':
      default:
        return IncidentStatus.active;
    }
  }

  String get displayName {
    switch (this) {
      case IncidentStatus.active:
        return 'Active Emergency';
      case IncidentStatus.resolvedByUser:
        return 'Resolved Safely';
      case IncidentStatus.cancelled:
        return 'Cancelled / False Alarm';
    }
  }
}

enum AlertDeliveryStatus {
  notConfigured,
  preparing,
  simulatedSent,
  deliveredConfirmed,
  failed;

  String get value {
    switch (this) {
      case AlertDeliveryStatus.notConfigured:
        return 'not_configured';
      case AlertDeliveryStatus.preparing:
        return 'preparing';
      case AlertDeliveryStatus.simulatedSent:
        return 'simulated_sent';
      case AlertDeliveryStatus.deliveredConfirmed:
        return 'delivered_confirmed';
      case AlertDeliveryStatus.failed:
        return 'failed';
    }
  }

  static AlertDeliveryStatus fromString(String? val) {
    switch (val) {
      case 'preparing':
        return AlertDeliveryStatus.preparing;
      case 'simulated_sent':
        return AlertDeliveryStatus.simulatedSent;
      case 'delivered_confirmed':
        return AlertDeliveryStatus.deliveredConfirmed;
      case 'failed':
        return AlertDeliveryStatus.failed;
      case 'not_configured':
      default:
        return AlertDeliveryStatus.notConfigured;
    }
  }

  String get displayName {
    switch (this) {
      case AlertDeliveryStatus.notConfigured:
        return 'Alerts Demo Mode (No SMS Gateway)';
      case AlertDeliveryStatus.preparing:
        return 'Preparing Alert Dispatch';
      case AlertDeliveryStatus.simulatedSent:
        return 'Alert Sent (Simulated)';
      case AlertDeliveryStatus.deliveredConfirmed:
        return 'Delivered & Confirmed';
      case AlertDeliveryStatus.failed:
        return 'Dispatch Failed';
    }
  }
}

enum CheckinStatus {
  active,
  completedSafe,
  cancelled,
  missed;

  String get value {
    switch (this) {
      case CheckinStatus.active:
        return 'active';
      case CheckinStatus.completedSafe:
        return 'completed_safe';
      case CheckinStatus.cancelled:
        return 'cancelled';
      case CheckinStatus.missed:
        return 'missed';
    }
  }

  static CheckinStatus fromString(String? val) {
    switch (val) {
      case 'completed_safe':
        return CheckinStatus.completedSafe;
      case 'cancelled':
        return CheckinStatus.cancelled;
      case 'missed':
        return CheckinStatus.missed;
      case 'active':
      default:
        return CheckinStatus.active;
    }
  }
}
