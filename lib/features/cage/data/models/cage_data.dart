import '../../../../core/models/safe_convert.dart';

// model untuk menyimpan data kandang
class CageData {
  final int idKandang;
  final String type;
  final int capacity;
  final String address;

  CageData({
    this.idKandang = 0,
    this.type = "",
    this.capacity = 0,
    this.address = "",
  });

  factory CageData.fromJson(Map<String, dynamic>? json) => CageData(
    idKandang: asInt(json, 'idKandang'),
    type: asString(json, 'type'),
    capacity: asInt(json, 'capacity'),
    address: asString(json, 'address'),
  );

  Map<String, dynamic> toJson() => {
    'idKandang': idKandang,
    'type': type,
    'capacity': capacity,
    'address': address,
  };

  CageData copyWith({
    int? idKandang,
    String? type,
    int? capacity,
    String? address,
  }) {
    return CageData(
      idKandang: idKandang ?? this.idKandang,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      address: address ?? this.address,
    );
  }
}

