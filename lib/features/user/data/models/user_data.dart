import 'package:recording_app/core/models/safe_convert.dart';

// model untuk menyimpan data profil user/peternak (nested map di users/{uid})
class UserProfile {
  final String name;
  final String phone;
  final String address;
  final bool hasCompletedTour;

  const UserProfile({
    this.name = '',
    this.phone = '',
    this.address = '',
    this.hasCompletedTour = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserProfile();
    }

    return UserProfile(
      name: asString(json, 'name'),
      phone: asString(json, 'phone'),
      address: asString(json, 'address'),
      hasCompletedTour: (json['hasCompletedTour'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
    'hasCompletedTour': hasCompletedTour,
  };

  UserProfile copyWith({
    String? name,
    String? phone,
    String? address,
    bool? hasCompletedTour,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      hasCompletedTour: hasCompletedTour ?? this.hasCompletedTour,
    );
  }

  @override
  String toString() {
    return 'UserProfile(name: $name, phone: $phone, address: $address, hasCompletedTour: $hasCompletedTour)';
  }
}