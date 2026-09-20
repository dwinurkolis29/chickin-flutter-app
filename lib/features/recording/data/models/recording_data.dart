import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/safe_convert.dart';

// model untuk menyimpan data recording ayam (nested di periods/{periodId}/recordings)
class RecordingData {
  final String id;
  final int day;
  final int avgWeightGram;
  final double feedSack;
  final int mortality;
  final DateTime createdAt;

  const RecordingData({
    this.id = '',
    this.day = 0,
    this.avgWeightGram = 0,
    this.feedSack = 0.0,
    this.mortality = 0,
    required this.createdAt,
  });

  factory RecordingData.fromJson(Map<String, dynamic>? json, {String? docId}) {
    if (json == null) {
      return RecordingData(createdAt: DateTime.now());
    }

    return RecordingData(
      id: docId ?? asString(json, 'id'),
      day: asInt(json, 'day'),
      avgWeightGram: asInt(json, 'avgWeightGram'),
      feedSack: asDouble(json, 'feedSack'),
      mortality: asInt(json, 'mortality'),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    // 'id' is intentionally excluded: the Firestore document ID is the key.
    // Including it violates the isValidRecordingData hasOnly security rules.
    'day': day,
    'avgWeightGram': avgWeightGram,
    'feedSack': feedSack % 1 == 0 ? feedSack.toInt() : feedSack,
    'mortality': mortality,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  RecordingData copyWith({
    String? id,
    int? day,
    int? avgWeightGram,
    double? feedSack,
    int? mortality,
    DateTime? createdAt,
  }) {
    return RecordingData(
      id: id ?? this.id,
      day: day ?? this.day,
      avgWeightGram: avgWeightGram ?? this.avgWeightGram,
      feedSack: feedSack ?? this.feedSack,
      mortality: mortality ?? this.mortality,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'RecordingData(id: $id, day: $day, avgWeightGram: $avgWeightGram, feedSack: $feedSack, mortality: $mortality)';
  }
}
