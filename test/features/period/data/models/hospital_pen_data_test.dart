import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/period/data/models/hospital_pen_data.dart';

void main() {
  group('HospitalPenData', () {
    final now = DateTime(2026, 9, 20, 10, 0, 0);

    test('should construct empty instance correctly', () {
      final empty = HospitalPenData.empty();

      expect(empty.count, 0);
      expect(empty.avgWeightGram, 0);
      expect(empty.day, 0);
      expect(empty.conditions, isEmpty);
      expect(empty.notes, isEmpty);
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
    });

    test('isNotEmpty returns true when count and avgWeightGram are positive', () {
      final data = HospitalPenData(
        count: 150,
        avgWeightGram: 1206,
        day: 28,
      );

      expect(data.isEmpty, isFalse);
      expect(data.isNotEmpty, isTrue);
    });

    test('fromJson and toJson serialization work symmetrically', () {
      final data = HospitalPenData(
        count: 150,
        avgWeightGram: 1206,
        day: 28,
        conditions: const ['Kerdil', 'Kalah Bersaing'],
        notes: 'Diberikan vitamin tambahan',
        updatedAt: now,
      );

      final json = data.toJson();
      expect(json['count'], 150);
      expect(json['avgWeightGram'], 1206);
      expect(json['day'], 28);
      expect(json['conditions'], ['Kerdil', 'Kalah Bersaing']);
      expect(json['notes'], 'Diberikan vitamin tambahan');
      expect(json['updatedAt'], Timestamp.fromDate(now));

      final fromJson = HospitalPenData.fromJson(json);
      expect(fromJson.count, data.count);
      expect(fromJson.avgWeightGram, data.avgWeightGram);
      expect(fromJson.day, data.day);
      expect(fromJson.conditions, data.conditions);
      expect(fromJson.notes, data.notes);
      expect(fromJson.updatedAt, now);
    });

    test('fromJson handles null and missing fields safely with safe_convert', () {
      final emptyJson = <String, dynamic>{};
      final parsed = HospitalPenData.fromJson(emptyJson);

      expect(parsed.count, 0);
      expect(parsed.avgWeightGram, 0);
      expect(parsed.day, 0);
      expect(parsed.conditions, isEmpty);
      expect(parsed.notes, isEmpty);
      expect(parsed.updatedAt, isNull);
    });

    test('copyWith updates specified fields and preserves others', () {
      final initial = HospitalPenData(
        count: 100,
        avgWeightGram: 1100,
        day: 25,
        conditions: const ['Pincang'],
        notes: 'Kandang 1',
        updatedAt: now,
      );

      final updated = initial.copyWith(
        count: 150,
        avgWeightGram: 1206,
        day: 28,
        conditions: const ['Kerdil'],
        notes: 'Catatan baru',
      );

      expect(updated.count, 150);
      expect(updated.avgWeightGram, 1206);
      expect(updated.day, 28);
      expect(updated.conditions, ['Kerdil']);
      expect(updated.notes, 'Catatan baru');
      expect(updated.updatedAt, now);
    });
  });
}
