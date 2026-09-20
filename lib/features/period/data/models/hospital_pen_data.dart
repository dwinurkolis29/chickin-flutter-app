import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/safe_convert.dart';

/// Model snapshot data sekat seleksian (Hospital Pen) pada periode pemeliharaan.
/// Mewakili sub-populasi ayam sakit, kerdil, atau kalah bersaing yang dipisah.
class HospitalPenData {
  final int count; // Jumlah ekor di sekat (misal: 150)
  final int avgWeightGram; // Bobot rata-rata sekat (misal: 1206 g)
  final int day; // Umur ayam saat dicatat/timbang (misal: 28 hari)
  final List<String> conditions; // Gejala/kondisi (misal: 'Kerdil', 'Pincang')
  final String notes; // Catatan bebas peternak
  final DateTime? updatedAt;

  const HospitalPenData({
    this.count = 0,
    this.avgWeightGram = 0,
    this.day = 0,
    this.conditions = const [],
    this.notes = '',
    this.updatedAt,
  });

  /// Factory untuk membuat snapshot kosong / reset
  factory HospitalPenData.empty() => const HospitalPenData(
        count: 0,
        avgWeightGram: 0,
        day: 0,
        conditions: [],
        notes: '',
        updatedAt: null,
      );

  bool get isEmpty => count <= 0;
  bool get isNotEmpty => count > 0;

  factory HospitalPenData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HospitalPenData.empty();

    DateTime? parseUpdatedDate() {
      final raw = json['updatedAt'];
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    final rawConditions = asList(json, 'conditions');
    final conditionsList =
        rawConditions.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();

    return HospitalPenData(
      count: asInt(json, 'count'),
      avgWeightGram: asInt(json, 'avgWeightGram'),
      day: asInt(json, 'day'),
      conditions: conditionsList,
      notes: asString(json, 'notes'),
      updatedAt: parseUpdatedDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'count': count,
        'avgWeightGram': avgWeightGram,
        'day': day,
        'conditions': conditions,
        'notes': notes,
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };

  HospitalPenData copyWith({
    int? count,
    int? avgWeightGram,
    int? day,
    List<String>? conditions,
    String? notes,
    DateTime? updatedAt,
  }) {
    return HospitalPenData(
      count: count ?? this.count,
      avgWeightGram: avgWeightGram ?? this.avgWeightGram,
      day: day ?? this.day,
      conditions: conditions ?? this.conditions,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'HospitalPenData(count: $count, avgWeightGram: $avgWeightGram, day: $day, conditions: $conditions, notes: $notes)';
  }
}
