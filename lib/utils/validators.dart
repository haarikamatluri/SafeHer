class AppValidators {
  /// Validates contact or user full name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (trimmed.length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    return null;
  }

  /// Validates standard phone numbers (international or local format)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Enter a valid phone number (7-15 digits)';
    }
    return null;
  }

  /// Optional email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Normalizes phone number for duplicate checking (strips symbols and +)
  static String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
  }

  /// Safely normalizes phone number for SMS dispatch, PRESERVING valid international '+' prefix
  static String normalizeForSms(String phone) {
    final trimmed = phone.trim();
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    return hasPlus ? '+$digits' : digits;
  }

  /// Validates check-in duration in minutes
  static String? validateCheckinMinutes(int minutes) {
    if (minutes < 1) {
      return 'Duration must be at least 1 minute';
    }
    if (minutes > 1440) {
      return 'Duration cannot exceed 24 hours (1440 mins)';
    }
    return null;
  }
}
