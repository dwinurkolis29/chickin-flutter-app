import '../../../../core/models/safe_convert.dart';

// model untuk menyimpan data kandang (nested map di users/{uid})
class CageData {
  final String type;
  final int capacity;
  final String location;

  const CageData({
    this.type = '',
    this.capacity = 0,
    this.location = '',
  });

  factory CageData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CageData();
    }

    return CageData(
      type: asString(json, 'type'),
      capacity: asInt(json, 'capacity'),
      location: asString(json, 'location'),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'capacity': capacity,
    'location': location,
  };

  CageData copyWith({
    String? type,
    int? capacity,
    String? location,
  }) {
    return CageData(
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      location: location ?? this.location,
    );
  }

  @override
  String toString() {
    return 'CageData(type: $type, capacity: $capacity, location: $location)';
  }
}

