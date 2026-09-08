import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/period/data/models/harvest_record.dart';

void main() {
  group('HarvestRecord', () {
    test('fromJson & toJson serialize properly for partial harvest', () {
      final now = DateTime(2026, 4, 15, 10, 30);
      final json = {
        'id': 'harvest-123',
        'type': 'partial',
        'date': Timestamp.fromDate(now),
        'day': 30,
        'chicks': 2500,
        'weightKg': 3750.0,
        'avgWeightKg': 1.5,
        'pricePerKg': 21000.0,
        'totalRevenue': 78750000.0,
        'notes': 'Penjualan ke PT Mitra Unggas',
        'createdAt': Timestamp.fromDate(now),
      };

      final record = HarvestRecord.fromJson(json, docId: 'harvest-123');

      expect(record.id, 'harvest-123');
      expect(record.type, HarvestType.partial);
      expect(record.day, 30);
      expect(record.chicks, 2500);
      expect(record.weightKg, 3750.0);
      expect(record.avgWeightKg, 1.5);
      expect(record.pricePerKg, 21000.0);
      expect(record.totalRevenue, 78750000.0);
      expect(record.notes, 'Penjualan ke PT Mitra Unggas');

      final serialized = record.toJson();
      expect(serialized['type'], 'partial');
      expect(serialized['day'], 30);
      expect(serialized['chicks'], 2500);
      expect(serialized['weightKg'], 3750.0);
      expect(serialized['pricePerKg'], 21000.0);
      expect(serialized['totalRevenue'], 78750000.0);
      expect(serialized['notes'], 'Penjualan ke PT Mitra Unggas');
    });

    test('HarvestType.fromString converts final and partial strings correctly', () {
      expect(HarvestType.fromString('final'), HarvestType.finalHarvest);
      expect(HarvestType.fromString('finalHarvest'), HarvestType.finalHarvest);
      expect(HarvestType.fromString('partial'), HarvestType.partial);
      expect(HarvestType.fromString('anything_else'), HarvestType.partial);
    });

    test('auto-calculates avgWeightKg if not explicitly given in json', () {
      final now = DateTime.now();
      final json = {
        'type': 'partial',
        'day': 28,
        'chicks': 1000,
        'weightKg': 1400.0,
        'date': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      };

      final record = HarvestRecord.fromJson(json);
      expect(record.avgWeightKg, 1.4);
    });

    test('copyWith works correctly', () {
      final record = HarvestRecord(
        id: 'h1',
        type: HarvestType.partial,
        date: DateTime(2026, 3, 1),
        day: 29,
        chicks: 500,
        weightKg: 750.0,
        avgWeightKg: 1.5,
        createdAt: DateTime(2026, 3, 1),
      );

      final updated = record.copyWith(
        chicks: 600,
        weightKg: 900.0,
        avgWeightKg: 1.5,
        notes: 'Updated note',
      );

      expect(updated.id, 'h1');
      expect(updated.chicks, 600);
      expect(updated.weightKg, 900.0);
      expect(updated.notes, 'Updated note');
    });
  });
}
