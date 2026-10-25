class TrustedContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final String? email;
  final String preferredAlertChannel; // 'sms', 'call', 'app', 'whatsapp'
  final bool smsEnabled;
  final bool pushEnabled;
  final bool whatsappEnabled;
  final bool whatsappConsent;
  final bool isAuthorized;
  final String? fcmToken;
  final String? linkedUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrustedContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.email,
    this.preferredAlertChannel = 'sms',
    this.smsEnabled = true,
    this.pushEnabled = true,
    this.whatsappEnabled = false,
    this.whatsappConsent = false,
    this.isAuthorized = true,
    this.fcmToken,
    this.linkedUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  TrustedContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    String? email,
    String? preferredAlertChannel,
    bool? smsEnabled,
    bool? pushEnabled,
    bool? whatsappEnabled,
    bool? whatsappConsent,
    bool? isAuthorized,
    String? fcmToken,
    String? linkedUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrustedContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      email: email ?? this.email,
      preferredAlertChannel:
          preferredAlertChannel ?? this.preferredAlertChannel,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
      whatsappConsent: whatsappConsent ?? this.whatsappConsent,
      isAuthorized: isAuthorized ?? this.isAuthorized,
      fcmToken: fcmToken ?? this.fcmToken,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'email': email,
      'preferredAlertChannel': preferredAlertChannel,
      'smsEnabled': smsEnabled,
      'pushEnabled': pushEnabled,
      'whatsappEnabled': whatsappEnabled,
      'whatsappConsent': whatsappConsent,
      'isAuthorized': isAuthorized,
      'fcmToken': fcmToken,
      'linkedUserId': linkedUserId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TrustedContact.fromMap(Map<String, dynamic> map, [String? docId]) {
    return TrustedContact(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relationship: map['relationship'] ?? 'Friend',
      email: map['email'],
      preferredAlertChannel: map['preferredAlertChannel'] ?? 'sms',
      smsEnabled: map['smsEnabled'] ?? true,
      pushEnabled: map['pushEnabled'] ?? true,
      whatsappEnabled: map['whatsappEnabled'] ?? false,
      whatsappConsent: map['whatsappConsent'] ?? false,
      isAuthorized: map['isAuthorized'] ?? true,
      fcmToken: map['fcmToken'],
      linkedUserId: map['linkedUserId'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrustedContact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
