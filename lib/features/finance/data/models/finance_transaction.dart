import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/safe_convert.dart';

/// Kategori transaksi keuangan broiler
enum FinanceCategory {
  // Pengeluaran
  feed('Pakan', 'feed'),
  doc('DOC', 'doc'),
  ovk('OVK', 'ovk'),
  operational('Operasional', 'operational'),

  // Pemasukan
  mainHarvest('Penjualan Utama', 'main_harvest'),
  reject('Afkir / Reject', 'reject');

  final String label;
  final String code;

  const FinanceCategory(this.label, this.code);

  static FinanceCategory fromCode(String code) {
    for (final cat in FinanceCategory.values) {
      if (cat.code == code) return cat;
    }
    return FinanceCategory.operational;
  }

  bool get isIncome =>
      this == FinanceCategory.mainHarvest || this == FinanceCategory.reject;
  bool get isExpense => !isIncome;
}

/// Model transaksi keuangan (pemasukan / pengeluaran) per periode
class FinanceTransaction {
  final String id;
  final String periodId;
  final String type; // 'income' | 'expense'
  final String category; // feed, doc, ovk, operational, main_harvest, reject
  final double amount; // Nominal Rp
  final DateTime date;
  final String notes;
  final int? birdCount; // Opsional: ekor ayam terjual
  final double? weightKg; // Opsional: total kg terjual
  final DateTime createdAt;

  const FinanceTransaction({
    this.id = '',
    required this.periodId,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.notes = '',
    this.birdCount,
    this.weightKg,
    required this.createdAt,
  });

  FinanceCategory get categoryEnum => FinanceCategory.fromCode(category);
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory FinanceTransaction.fromJson(
    Map<String, dynamic>? json, {
    String? docId,
  }) {
    if (json == null) {
      return FinanceTransaction(
        periodId: '',
        type: 'expense',
        category: 'operational',
        amount: 0.0,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }

    return FinanceTransaction(
      id: docId ?? asString(json, 'id'),
      periodId: asString(json, 'periodId'),
      type: asString(json, 'type', defaultValue: 'expense'),
      category: asString(json, 'category', defaultValue: 'operational'),
      amount: asDouble(json, 'amount'),
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: asString(json, 'notes'),
      birdCount: asIntOrNull(json, 'birdCount'),
      weightKg: asDoubleOrNull(json, 'weightKg'),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'periodId': periodId,
    'type': type,
    'category': category,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'notes': notes,
    if (birdCount != null) 'birdCount': birdCount,
    if (weightKg != null) 'weightKg': weightKg,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  FinanceTransaction copyWith({
    String? id,
    String? periodId,
    String? type,
    String? category,
    double? amount,
    DateTime? date,
    String? notes,
    int? birdCount,
    double? weightKg,
    DateTime? createdAt,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      birdCount: birdCount ?? this.birdCount,
      weightKg: weightKg ?? this.weightKg,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
