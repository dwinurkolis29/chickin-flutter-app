import '../../../../core/models/safe_convert.dart';

// model untuk menyimpan data kandang (nested map di users/{uid})
class CageData {
  final String type;
  final int capacity;
  final String location;
  final String? imageUrl;

  const CageData({
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
      type: asString(json, 'type'),
      capacity: asInt(json, 'capacity'),
      location: asString(json, 'location'),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'capacity': capacity,
    'location': location,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  CageData copyWith({
    String? type,
    int? capacity,
    String? location,
    String? imageUrl,
  }) {
    return CageData(
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'CageData(type: $type, capacity: $capacity, location: $location, imageUrl: $imageUrl)';
  }
}

