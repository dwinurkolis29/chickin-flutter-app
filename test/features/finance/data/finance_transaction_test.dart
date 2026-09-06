import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/finance/data/models/finance_transaction.dart';

void main() {
  group('FinanceTransaction Model', () {
    test('fromJson and toJson round-trip preserves values safely', () {
      final now = DateTime.now();
      final tx = FinanceTransaction(
        id: 'tx-123',
        periodId: 'period-456',
        type: 'income',
        category: 'main_harvest',
        amount: 50000000.0,
        date: now,
        notes: 'Penjualan ke bakul A',
        birdCount: 2000,
        weightKg: 3800.5,
        createdAt: now,
      );

      final json = tx.toJson();
      expect(json['periodId'], 'period-456');
      expect(json['type'], 'income');
      expect(json['category'], 'main_harvest');
      expect(json['amount'], 50000000.0);
      expect(json['birdCount'], 2000);
      expect(json['weightKg'], 3800.5);
      expect(json['notes'], 'Penjualan ke bakul A');
      expect(json['date'], isA<Timestamp>());

      final parsed = FinanceTransaction.fromJson(json, docId: 'tx-123');
      expect(parsed.id, 'tx-123');
      expect(parsed.periodId, 'period-456');
      expect(parsed.type, 'income');
      expect(parsed.category, 'main_harvest');
      expect(parsed.amount, 50000000.0);
      expect(parsed.birdCount, 2000);
      expect(parsed.weightKg, 3800.5);
      expect(parsed.notes, 'Penjualan ke bakul A');
      expect(parsed.isIncome, true);
      expect(parsed.isExpense, false);
      expect(parsed.categoryEnum, FinanceCategory.mainHarvest);
    });

    test('fromJson handles null safely without crashing', () {
      final parsed = FinanceTransaction.fromJson(null);
      expect(parsed.id, '');
      expect(parsed.periodId, '');
      expect(parsed.amount, 0.0);
      expect(parsed.isExpense, true);
    });

    test('copyWith updates fields correctly', () {
      final now = DateTime.now();
      final tx = FinanceTransaction(
        id: 'tx-1',
        periodId: 'p-1',
        type: 'expense',
        category: 'feed',
        amount: 1000000.0,
        date: now,
        createdAt: now,
      );

      final updated = tx.copyWith(amount: 2000000.0, notes: 'Tambah 5 sak');
      expect(updated.amount, 2000000.0);
      expect(updated.notes, 'Tambah 5 sak');
      expect(updated.category, 'feed');
      expect(updated.id, 'tx-1');
    });
  });
}
