import 'dart:convert';

enum SafeHavenCategory {
  all,
  police,
  hospital,
  pharmacy,
  womenCenter,
  verifiedPlace,
}

extension SafeHavenCategoryExt on SafeHavenCategory {
  String get displayName {
    switch (this) {
      case SafeHavenCategory.all:
        return 'All';
      case SafeHavenCategory.police:
        return 'Police';
      case SafeHavenCategory.hospital:
        return 'Hospital';
      case SafeHavenCategory.pharmacy:
        return 'Pharmacy';
      case SafeHavenCategory.womenCenter:
        return 'Women Help Center';
      case SafeHavenCategory.verifiedPlace:
        return 'Verified Safe Place';
    }
  }
}

class SafeHavenPlace {
  final String id;
  final String name;
  final SafeHavenCategory category;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final bool isVerified;
  final bool isOpen24Hours;
  final String operatingHours;
  final double distanceKm;
  final double rating;
  final String? verificationSource;
  final String? imageUrl;

  const SafeHavenPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.isVerified = true,
    this.isOpen24Hours = true,
    this.operatingHours = 'Open 24 hours',
    this.distanceKm = 1.2,
    this.rating = 4.8,
    this.verificationSource = 'AP Police & Health Dept Verified',
    this.imageUrl,
  });

  SafeHavenPlace copyWith({
    String? id,
    String? name,
    SafeHavenCategory? category,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isOpen24Hours,
    String? operatingHours,
    double? distanceKm,
    double? rating,
    String? verificationSource,
    String? imageUrl,
  }) {
    return SafeHavenPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isOpen24Hours: isOpen24Hours ?? this.isOpen24Hours,
      operatingHours: operatingHours ?? this.operatingHours,
      distanceKm: distanceKm ?? this.distanceKm,
      rating: rating ?? this.rating,
      verificationSource: verificationSource ?? this.verificationSource,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isOpen24Hours': isOpen24Hours,
      'operatingHours': operatingHours,
      'distanceKm': distanceKm,
      'rating': rating,
      'verificationSource': verificationSource,
      'imageUrl': imageUrl,
    };
  }

  factory SafeHavenPlace.fromMap(Map<String, dynamic> map) {
    return SafeHavenPlace(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: SafeHavenCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => SafeHavenCategory.verifiedPlace,
      ),
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 13.6288,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 79.4192,
      isVerified: map['isVerified'] as bool? ?? true,
      isOpen24Hours: map['isOpen24Hours'] as bool? ?? true,
      operatingHours: map['operatingHours'] as String? ?? 'Open 24 hours',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 1.2,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      verificationSource: map['verificationSource'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory SafeHavenPlace.fromJson(String source) =>
      SafeHavenPlace.fromMap(json.decode(source) as Map<String, dynamic>);
}

class CommunityReport {
  final String id;
  final String userId;
  final String title;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final bool isVerified;
  final String category;
  final String? notes;

  const CommunityReport({
    required this.id,
    required this.userId,
    required this.title,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.isVerified = false,
    required this.category,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
      'category': category,
      'notes': notes,
    };
  }

  factory CommunityReport.fromMap(Map<String, dynamic> map) {
    return CommunityReport(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      locationName: map['locationName'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 13.6288,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 79.4192,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isVerified: map['isVerified'] as bool? ?? false,
      category: map['category'] as String? ?? 'lighting',
      notes: map['notes'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory CommunityReport.fromJson(String source) =>
      CommunityReport.fromMap(json.decode(source) as Map<String, dynamic>);
}
