import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

// Note: RecordingData.fromJson depends on cloud_firestore Timestamp.
// Tests untuk fromJson dengan Timestamp dipisah ke integration test.
// Di sini kita uji constructor, copyWith, toJson (tanpa Firestore Timestamp),
// dan default values menggunakan constructor langsung.

void main() {
  final baseDate = DateTime(2025, 6, 1, 8, 0, 0);

  // ─────────────────────────────────────────────────────────────────────────
  // RecordingData — constructor defaults
  // ─────────────────────────────────────────────────────────────────────────
  group('RecordingData', () {
    group('default values', () {
      test('id default empty string', () {
        final r = RecordingData(createdAt: baseDate);
        expect(r.id, '');
      });

      test('day default 0', () {
        final r = RecordingData(createdAt: baseDate);
        expect(r.day, 0);
      });

      test('avgWeightGram default 0', () {
        final r = RecordingData(createdAt: baseDate);
        expect(r.avgWeightGram, 0);
      });

      test('feedSack default 0', () {
        final r = RecordingData(createdAt: baseDate);
        expect(r.feedSack, 0);
      });

      test('mortality default 0', () {
        final r = RecordingData(createdAt: baseDate);
        expect(r.mortality, 0);
      });
    });

    group('constructor happy path', () {
      test('seluruh field terisi dengan benar', () {
        final r = RecordingData(
          id: 'rec-001',
          day: 14,
          avgWeightGram: 850,
          feedSack: 8,
          mortality: 2,
          createdAt: baseDate,
        );

        expect(r.id, 'rec-001');
        expect(r.day, 14);
        expect(r.avgWeightGram, 850);
        expect(r.feedSack, 8);
        expect(r.mortality, 2);
        expect(r.createdAt, baseDate);
      });
    });

    group('copyWith', () {
      late RecordingData base;

      setUp(() {
        base = RecordingData(
          id: 'rec-001',
          day: 14,
          avgWeightGram: 850,
          feedSack: 8,
          mortality: 2,
          createdAt: baseDate,
        );
      });

      test('tanpa argumen → identik', () {
        final copy = base.copyWith();
        expect(copy.id, base.id);
        expect(copy.day, base.day);
        expect(copy.avgWeightGram, base.avgWeightGram);
        expect(copy.feedSack, base.feedSack);
        expect(copy.mortality, base.mortality);
        expect(copy.createdAt, base.createdAt);
      });

      test('update day saja', () {
        final copy = base.copyWith(day: 21);
        expect(copy.day, 21);
        expect(copy.id, base.id); // field lain tidak berubah
        expect(copy.avgWeightGram, base.avgWeightGram);
      });

      test('update avgWeightGram', () {
        final copy = base.copyWith(avgWeightGram: 2150);
        expect(copy.avgWeightGram, 2150);
        expect(copy.day, base.day);
      });

      test('update mortality ke 0 (boundary)', () {
        final copy = base.copyWith(mortality: 0);
        expect(copy.mortality, 0);
      });

      test('update feedSack ke nilai besar', () {
        final copy = base.copyWith(feedSack: 64);
        expect(copy.feedSack, 64);
      });

      test('update createdAt', () {
        final newDate = DateTime(2025, 6, 15);
        final copy = base.copyWith(createdAt: newDate);
        expect(copy.createdAt, newDate);
      });
    });

    group('fromJson — null input', () {
      // Tidak bisa test fromJson penuh tanpa Timestamp mock,
      // tapi kita bisa verifikasi null-safety behavior via constructor default.
      // Regression: fromJson(null) tidak boleh throw, harus return default object.
      test('fromJson(null) returns default object without throwing', () {
        expect(() => RecordingData.fromJson(null), returnsNormally);
        final result = RecordingData.fromJson(null);
        expect(result.id, '');
        expect(result.day, 0);
        expect(result.avgWeightGram, 0);
        expect(result.feedSack, 0);
        expect(result.mortality, 0);
      });
    });

    group('fromJson — partial json (no Timestamp)', () {
      test('json kosong {} → semua default (kecuali createdAt dari DateTime.now)', () {
        // createdAt akan jatuh ke DateTime.now() karena Timestamp null
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final result = RecordingData.fromJson({});
        final after = DateTime.now().add(const Duration(seconds: 1));

        expect(result.id, '');
        expect(result.day, 0);
        expect(result.avgWeightGram, 0);
        expect(result.feedSack, 0);
        expect(result.mortality, 0);
        // createdAt harus antara before dan after
        expect(result.createdAt.isAfter(before), true);
        expect(result.createdAt.isBefore(after), true);
      });

      test('json dengan field day dan feedSack saja', () {
        final result = RecordingData.fromJson({'day': 7, 'feedSack': 4});
        expect(result.day, 7);
        expect(result.feedSack, 4);
        expect(result.mortality, 0);
        expect(result.avgWeightGram, 0);
      });

      test('docId override id', () {
        final result = RecordingData.fromJson({'day': 1}, docId: 'override-id');
        expect(result.id, 'override-id');
      });

      test('invalid type di day → safe_convert fallback 0', () {
        final result = RecordingData.fromJson({'day': 'bukan-angka'});
        expect(result.day, 0);
      });

      test('string numeric day → parsed', () {
        final result = RecordingData.fromJson({'day': '14'});
        expect(result.day, 14);
      });
    });

    group('toString', () {
      test('format mencantumkan semua field penting', () {
        final r = RecordingData(
          id: 'rec-001',
          day: 14,
          avgWeightGram: 850,
          feedSack: 8,
          mortality: 2,
          createdAt: baseDate,
        );
        final s = r.toString();
        expect(s.contains('rec-001'), true);
        expect(s.contains('14'), true);
        expect(s.contains('850'), true);
        expect(s.contains('8'), true);
        expect(s.contains('2'), true);
      });
    });
  });
}
