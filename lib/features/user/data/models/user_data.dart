import 'package:recording_app/core/models/safe_convert.dart';

// model untuk menyimpan data profil user/peternak (nested map di users/{uid})
class UserProfile {
  final String name;
  final String phone;
  final String address;
  final bool hasCompletedTour;
  final String? avatarUrl;

  const UserProfile({
    this.name = '',
    this.phone = '',
    this.address = '',
    this.hasCompletedTour = false,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserProfile();
    }

    return UserProfile(
      name: asString(json, 'name'),
      phone: asString(json, 'phone'),
      address: asString(json, 'address'),
      hasCompletedTour: asBool(json, 'hasCompletedTour'),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
    'hasCompletedTour': hasCompletedTour,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };

  UserProfile copyWith({
    String? name,
    String? phone,
    String? address,
    bool? hasCompletedTour,
    String? avatarUrl,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      hasCompletedTour: hasCompletedTour ?? this.hasCompletedTour,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'UserProfile(name: $name, phone: $phone, address: $address, hasCompletedTour: $hasCompletedTour, avatarUrl: $avatarUrl)';
  }
}