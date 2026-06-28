import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // CageData
  // ─────────────────────────────────────────────────────────────────────────
  group('CageData', () {
    group('default values', () {
      test('type default ""', () => expect(const CageData().type, ''));
      test('capacity default 0', () => expect(const CageData().capacity, 0));
      test('location default ""', () => expect(const CageData().location, ''));
      test('imageUrl default null', () => expect(const CageData().imageUrl, null));
    });

    group('fromJson — null', () {
      test('null json → default object tanpa throw', () {
        expect(() => CageData.fromJson(null), returnsNormally);
        final result = CageData.fromJson(null);
        expect(result.type, '');
        expect(result.capacity, 0);
        expect(result.location, '');
        expect(result.imageUrl, null);
      });
    });

    group('fromJson — empty {}', () {
      test('{} → semua default', () {
        final result = CageData.fromJson({});
        expect(result.type, '');
        expect(result.capacity, 0);
        expect(result.location, '');
        expect(result.imageUrl, null);
      });
    });

    group('fromJson — happy path', () {
      test('seluruh field terisi', () {
        final json = {
          'type': 'Kandang Panggung',
          'capacity': 5000,
          'location': 'Desa Sukamaju, Bogor',
          'imageUrl': 'https://storage.example.com/cage/001.jpg',
        };
        final result = CageData.fromJson(json);
        expect(result.type, 'Kandang Panggung');
        expect(result.capacity, 5000);
        expect(result.location, 'Desa Sukamaju, Bogor');
        expect(result.imageUrl, 'https://storage.example.com/cage/001.jpg');
      });

      test('imageUrl null jika key tidak ada', () {
        final json = {
          'type': 'Kandang Closed House',
          'capacity': 20000,
          'location': 'Kab. Majalengka',
        };
        final result = CageData.fromJson(json);
        expect(result.imageUrl, null);
      });
    });

    group('fromJson — partial / invalid types', () {
      test('capacity sebagai string → di-parse ke int', () {
        final result = CageData.fromJson({'capacity': '3000'});
        expect(result.capacity, 3000);
      });

      test('capacity sebagai double → truncate ke int', () {
        final result = CageData.fromJson({'capacity': 5000.9});
        expect(result.capacity, 5000);
      });

      test('capacity sebagai string invalid → 0', () {
        final result = CageData.fromJson({'capacity': 'banyak'});
        expect(result.capacity, 0);
      });

      test('type sebagai int → convert ke string', () {
        final result = CageData.fromJson({'type': 42});
        expect(result.type, '42');
      });
    });

    group('toJson', () {
      test('imageUrl null → key imageUrl tidak ada di json', () {
        const data = CageData(
          type: 'Kandang Panggung',
          capacity: 5000,
          location: 'Bogor',
        );
        final json = data.toJson();
        expect(json.containsKey('imageUrl'), false);
      });

      test('imageUrl ada → key imageUrl hadir', () {
        const data = CageData(
          type: 'Kandang Panggung',
          capacity: 5000,
          location: 'Bogor',
          imageUrl: 'https://example.com/img.jpg',
        );
        final json = data.toJson();
        expect(json['imageUrl'], 'https://example.com/img.jpg');
      });

      test('round-trip: toJson → fromJson → sama', () {
        const original = CageData(
          type: 'Closed House',
          capacity: 20000,
          location: 'Kab. Majalengka',
          imageUrl: 'https://example.com/img.jpg',
        );
        final json = original.toJson();
        final restored = CageData.fromJson(json);
        expect(restored.type, original.type);
        expect(restored.capacity, original.capacity);
        expect(restored.location, original.location);
        expect(restored.imageUrl, original.imageUrl);
      });

      test('semua 3 base key selalu hadir', () {
        const data = CageData(type: 'Open', capacity: 1000, location: 'Jawa');
        final json = data.toJson();
        expect(json.containsKey('type'), true);
        expect(json.containsKey('capacity'), true);
        expect(json.containsKey('location'), true);
      });
    });

    group('copyWith', () {
      const base = CageData(
        type: 'Kandang Panggung',
        capacity: 5000,
        location: 'Desa Sukamaju, Bogor',
        imageUrl: 'https://example.com/old.jpg',
      );

      test('tanpa argumen → identik', () {
        final copy = base.copyWith();
        expect(copy.type, base.type);
        expect(copy.capacity, base.capacity);
        expect(copy.location, base.location);
        expect(copy.imageUrl, base.imageUrl);
      });

      test('update type saja', () {
        final copy = base.copyWith(type: 'Closed House');
        expect(copy.type, 'Closed House');
        expect(copy.capacity, base.capacity);
      });

      test('update capacity ke kapasitas besar', () {
        final copy = base.copyWith(capacity: 100000);
        expect(copy.capacity, 100000);
      });

      test('update imageUrl ke null — masih menggunakan nilai lama (copyWith tidak support null override)', () {
        // Note: CageData.copyWith tidak support set imageUrl ke null secara eksplisit
        // karena `imageUrl ?? this.imageUrl`. Ini adalah potensi bug — didokumentasikan di bawah.
        final copy = base.copyWith(imageUrl: null);
        // Saat ini: akan tetap pakai imageUrl lama karena null ?? old = old
        expect(copy.imageUrl, base.imageUrl);
        // ⚠️  Potensi Bug: tidak bisa menghapus imageUrl via copyWith.
        // Rekomendasi: tambah sentinel pattern seperti PeriodData.
      });
    });

    group('toString', () {
      test('format mencantumkan semua field', () {
        const data = CageData(
          type: 'Panggung',
          capacity: 5000,
          location: 'Bogor',
          imageUrl: 'https://img.jpg',
        );
        final s = data.toString();
        expect(s.contains('Panggung'), true);
        expect(s.contains('5000'), true);
        expect(s.contains('Bogor'), true);
        expect(s.contains('https://img.jpg'), true);
      });
    });
  });
}
