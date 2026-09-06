import '../../../../core/models/safe_convert.dart';

// model untuk menyimpan data kandang (nested map di users/{uid})
class CageData {
  final String name;
  final String type;
  final int capacity;
  final String location;
  final String? imageUrl;

  const CageData({
    this.name = 'Kandang Utama',
    this.type = '',
    this.capacity = 0,
    this.location = '',
    this.imageUrl,
  });

  factory CageData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CageData();
    }

    return CageData(
      name: asString(json, 'name', defaultValue: 'Kandang Utama'),
      type: asString(json, 'type'),
      capacity: asInt(json, 'capacity'),
      location: asString(json, 'location'),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'capacity': capacity,
    'location': location,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  CageData copyWith({
    String? name,
    String? type,
    int? capacity,
    String? location,
    String? imageUrl,
  }) {
    return CageData(
      name: name ?? this.name,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'CageData(name: $name, type: $type, capacity: $capacity, location: $location, imageUrl: $imageUrl)';
  }
}

