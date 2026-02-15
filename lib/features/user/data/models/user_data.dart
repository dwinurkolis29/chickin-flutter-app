import 'package:recording_app/core/models/safe_convert.dart';

// model untuk menyimpan data profil user/peternak (nested map di users/{uid})
class UserProfile {
  final String name;
  final String phone;
  final String address;

  const UserProfile({
    this.name = '',
    this.phone = '',
    this.address = '',
  });

  factory UserProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserProfile();
    }

    return UserProfile(
      name: asString(json, 'name'),
      phone: asString(json, 'phone'),
      address: asString(json, 'address'),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
  };

  UserProfile copyWith({
    String? name,
    String? phone,
    String? address,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  @override
  String toString() {
    return 'UserProfile(name: $name, phone: $phone, address: $address)';
  }
}