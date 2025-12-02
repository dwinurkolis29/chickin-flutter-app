import 'package:recording_app/core/models/safe_convert.dart';

// model untuk menyimpan data user/peternak
class UserData {
  final String? username;
  final String? email;
  final String? phone;
  final String? address;

  const UserData ({
    this.email,
    this.phone,
    this.address,
    this.username,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(

        username: asString(json, 'username'),
        email: asString(json, 'email'),
        phone: asString(json, 'phone'),
        address: asString(json, 'address'),
    );
  }

  toJson() => {
    'email': email,
    'phone': phone,
    'address': address,
    'username': username
  };

  UserData copyWith({
    String? email,
    String? phone,
    String? address,
    String? username
  }) {
    return UserData(
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      username: username ?? this.username
    );
  }
}