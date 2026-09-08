import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/safe_convert.dart';

/// Jenis panen ayam broiler: parsial (penjarangan) atau akhir (tutup siklus).
enum HarvestType {
  partial,
  finalHarvest;

  static HarvestType fromString(String? value) {
    if (value == 'final' || value == 'finalHarvest') {
      return HarvestType.finalHarvest;
    }
    return HarvestType.partial;
  }

  String get value => this == HarvestType.finalHarvest ? 'final' : 'partial';

  String get label =>
      this == HarvestType.finalHarvest ? 'Panen Akhir' : 'Panen Parsial';
}

/// Model untuk mencatat setiap peristiwa panen ayam broiler (parsial maupun akhir).
class HarvestRecord {
  final String id;
  final HarvestType type;
  final DateTime date;
  final int day; // Umur hari saat panen dilakukan
  final int chicks; // Jumlah ekor yang dipanen
  final double weightKg; // Total bobot panen (kg)
  final double avgWeightKg; // Rata-rata bobot (kg/ekor)
  final double? pricePerKg; // Harga jual per kg (opsional)
  final double? totalRevenue; // Total rupiah penjualan (opsional)
  final String? notes; // Catatan pembeli/keterangan
  final DateTime createdAt;

  const HarvestRecord({
    this.id = '',
    this.type = HarvestType.partial,
    required this.date,
    this.day = 0,
    this.chicks = 0,
    this.weightKg = 0.0,
    this.avgWeightKg = 0.0,
    this.pricePerKg,
    this.totalRevenue,
    this.notes,
    required this.createdAt,
  });

  factory HarvestRecord.fromJson(Map<String, dynamic>? json, {String? docId}) {
    if (json == null) {
      return HarvestRecord(date: DateTime.now(), createdAt: DateTime.now());
    }

    final chicksCount = asInt(json, 'chicks');
    final totalWeight = asDouble(json, 'weightKg');
    final calculatedAvg =
        (chicksCount > 0 && totalWeight > 0)
            ? totalWeight / chicksCount
            : asDouble(json, 'avgWeightKg');

    return HarvestRecord(
      id: docId ?? asString(json, 'id'),
      type: HarvestType.fromString(asString(json, 'type')),
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      day: asInt(json, 'day'),
      chicks: chicksCount,
      weightKg: totalWeight,
      avgWeightKg: calculatedAvg,
      pricePerKg: asDoubleOrNull(json, 'pricePerKg'),
      totalRevenue: asDoubleOrNull(json, 'totalRevenue'),
      notes: json['notes']?.toString(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.value,
    'date': Timestamp.fromDate(date),
    'day': day,
    'chicks': chicks,
    'weightKg': weightKg,
    'avgWeightKg': avgWeightKg,
    if (pricePerKg != null) 'pricePerKg': pricePerKg,
    if (totalRevenue != null) 'totalRevenue': totalRevenue,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  HarvestRecord copyWith({
    String? id,
    HarvestType? type,
    DateTime? date,
    int? day,
    int? chicks,
    double? weightKg,
    double? avgWeightKg,
    double? pricePerKg,
    double? totalRevenue,
    String? notes,
    DateTime? createdAt,
  }) {
    return HarvestRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      day: day ?? this.day,
      chicks: chicks ?? this.chicks,
      weightKg: weightKg ?? this.weightKg,
      avgWeightKg: avgWeightKg ?? this.avgWeightKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'HarvestRecord(id: $id, type: ${type.value}, day: $day, chicks: $chicks, weightKg: $weightKg, avg: $avgWeightKg)';
  }
}
