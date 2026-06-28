import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/reminder/data/models/reminder_data.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // ReminderData
  // ─────────────────────────────────────────────────────────────────────────
  group('ReminderData', () {
    group('default values', () {
      test('id default ""', () => expect(ReminderData().id, ''));
      test('title default ""', () => expect(ReminderData().title, ''));
      test('date default ""', () => expect(ReminderData().date, ''));
      test('time default ""', () => expect(ReminderData().time, ''));
      test('description default ""', () => expect(ReminderData().description, ''));
      test('createdAt default ""', () => expect(ReminderData().createdAt, ''));
      test('updatedAt default ""', () => expect(ReminderData().updatedAt, ''));
    });

    group('fromJson — null', () {
      // ⚠️  Bug Ditemukan: ReminderData.fromJson tidak handle json == null.
      // Tidak ada guard `if (json == null) return ReminderData()`.
      // Saat json null, `asString(null, 'id')` dipanggil → aman karena asString handle null.
      // Tapi jika ada perubahan implementasi, ini bisa break.
      test('null json → semua field default string kosong tanpa throw', () {
        expect(() => ReminderData.fromJson(null), returnsNormally);
        final result = ReminderData.fromJson(null);
        expect(result.id, '');
        expect(result.title, '');
        expect(result.date, '');
        expect(result.time, '');
      });
    });

    group('fromJson — empty {}', () {
      test('{} → semua default', () {
        final result = ReminderData.fromJson({});
        expect(result.id, '');
        expect(result.title, '');
        expect(result.date, '');
        expect(result.time, '');
        expect(result.description, '');
        expect(result.createdAt, '');
        expect(result.updatedAt, '');
      });
    });

    group('fromJson — happy path', () {
      test('seluruh field terisi', () {
        final json = {
          'id': 'rem-001',
          'title': 'Vaksin ND',
          'date': '2025-06-15',
          'time': '07:00',
          'description': 'Vaksin Newcastle Disease untuk semua kandang',
          'createdAt': '2025-06-01T08:00:00',
          'updatedAt': '2025-06-01T08:00:00',
        };
        final result = ReminderData.fromJson(json);
        expect(result.id, 'rem-001');
        expect(result.title, 'Vaksin ND');
        expect(result.date, '2025-06-15');
        expect(result.time, '07:00');
        expect(result.description, 'Vaksin Newcastle Disease untuk semua kandang');
        expect(result.createdAt, '2025-06-01T08:00:00');
        expect(result.updatedAt, '2025-06-01T08:00:00');
      });
    });

    group('fromJson — partial / invalid types', () {
      test('hanya title → field lain kosong', () {
        final result = ReminderData.fromJson({'title': 'Pakan pagi'});
        expect(result.title, 'Pakan pagi');
        expect(result.id, '');
        expect(result.date, '');
      });

      test('title sebagai int → convert ke string', () {
        final result = ReminderData.fromJson({'title': 42});
        expect(result.title, '42');
      });

      test('missing key → empty string (tidak throw)', () {
        expect(() => ReminderData.fromJson({'id': 'rem-999'}), returnsNormally);
      });
    });

    group('toJson', () {
      test('semua 7 key hadir', () {
        final data = ReminderData(
          id: 'rem-001',
          title: 'Vaksin',
          date: '2025-06-15',
          time: '07:00',
          description: 'Desc',
          createdAt: '2025-06-01',
          updatedAt: '2025-06-01',
        );
        final json = data.toJson();
        expect(json.containsKey('id'), true);
        expect(json.containsKey('title'), true);
        expect(json.containsKey('date'), true);
        expect(json.containsKey('time'), true);
        expect(json.containsKey('description'), true);
        expect(json.containsKey('createdAt'), true);
        expect(json.containsKey('updatedAt'), true);
        expect(json.length, 7);
      });

      test('round-trip: toJson → fromJson → sama', () {
        final original = ReminderData(
          id: 'rem-001',
          title: 'Vaksin ND',
          date: '2025-06-15',
          time: '07:00',
          description: 'Vaksin Newcastle Disease',
          createdAt: '2025-06-01T08:00:00',
          updatedAt: '2025-06-01T09:00:00',
        );
        final json = original.toJson();
        final restored = ReminderData.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.date, original.date);
        expect(restored.time, original.time);
        expect(restored.description, original.description);
        expect(restored.createdAt, original.createdAt);
        expect(restored.updatedAt, original.updatedAt);
      });
    });

    group('copyWith', () {
      final base = ReminderData(
        id: 'rem-001',
        title: 'Vaksin ND',
        date: '2025-06-15',
        time: '07:00',
        description: 'Vaksin Newcastle Disease',
        createdAt: '2025-06-01T08:00:00',
        updatedAt: '2025-06-01T08:00:00',
      );

      test('tanpa argumen → identik', () {
        final copy = base.copyWith();
        expect(copy.id, base.id);
        expect(copy.title, base.title);
        expect(copy.date, base.date);
        expect(copy.time, base.time);
        expect(copy.description, base.description);
        expect(copy.createdAt, base.createdAt);
        expect(copy.updatedAt, base.updatedAt);
      });

      test('update title saja', () {
        final copy = base.copyWith(title: 'Pemberian Vitamin');
        expect(copy.title, 'Pemberian Vitamin');
        expect(copy.id, base.id);
      });

      test('update date dan time', () {
        final copy = base.copyWith(date: '2025-07-01', time: '06:00');
        expect(copy.date, '2025-07-01');
        expect(copy.time, '06:00');
      });

      test('update updatedAt untuk mencatat perubahan', () {
        final copy = base.copyWith(updatedAt: '2025-06-10T10:00:00');
        expect(copy.updatedAt, '2025-06-10T10:00:00');
        expect(copy.createdAt, base.createdAt); // createdAt tidak berubah
      });
    });

    group('toString', () {
      test('format mencantumkan semua field penting', () {
        final data = ReminderData(
          id: 'rem-001',
          title: 'Vaksin ND',
          date: '2025-06-15',
          time: '07:00',
          description: 'Desc',
          createdAt: 'now',
          updatedAt: 'now',
        );
        final s = data.toString();
        expect(s.contains('rem-001'), true);
        expect(s.contains('Vaksin ND'), true);
        expect(s.contains('2025-06-15'), true);
        expect(s.contains('07:00'), true);
      });
    });
  });
}
