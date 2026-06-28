import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // UserProfile
  // ─────────────────────────────────────────────────────────────────────────
  group('UserProfile', () {
    group('default values', () {
      test('name default ""', () => expect(const UserProfile().name, ''));
      test('phone default ""', () => expect(const UserProfile().phone, ''));
      test('address default ""', () => expect(const UserProfile().address, ''));
      test('hasCompletedTour default false', () => expect(const UserProfile().hasCompletedTour, false));
      test('avatarUrl default null', () => expect(const UserProfile().avatarUrl, null));
    });

    group('fromJson — null', () {
      test('null → default object tanpa throw', () {
        expect(() => UserProfile.fromJson(null), returnsNormally);
        final result = UserProfile.fromJson(null);
        expect(result.name, '');
        expect(result.phone, '');
        expect(result.address, '');
        expect(result.hasCompletedTour, false);
        expect(result.avatarUrl, null);
      });
    });

    group('fromJson — empty {}', () {
      test('{} → semua default', () {
        final result = UserProfile.fromJson({});
        expect(result.name, '');
        expect(result.phone, '');
        expect(result.address, '');
        expect(result.hasCompletedTour, false);
        expect(result.avatarUrl, null);
      });
    });

    group('fromJson — happy path', () {
      test('seluruh field terisi', () {
        final json = {
          'name': 'Budi Santoso',
          'phone': '081234567890',
          'address': 'Jl. Kandang No.1, Bogor',
          'hasCompletedTour': true,
          'avatarUrl': 'https://storage.example.com/avatar/budi.jpg',
        };
        final result = UserProfile.fromJson(json);
        expect(result.name, 'Budi Santoso');
        expect(result.phone, '081234567890');
        expect(result.address, 'Jl. Kandang No.1, Bogor');
        expect(result.hasCompletedTour, true);
        expect(result.avatarUrl, 'https://storage.example.com/avatar/budi.jpg');
      });

      test('hasCompletedTour false secara eksplisit', () {
        final result = UserProfile.fromJson({'hasCompletedTour': false});
        expect(result.hasCompletedTour, false);
      });
    });

    group('fromJson — partial / invalid types', () {
      test('hanya name → field lain default', () {
        final result = UserProfile.fromJson({'name': 'Sari Dewi'});
        expect(result.name, 'Sari Dewi');
        expect(result.phone, '');
        expect(result.hasCompletedTour, false);
      });

      test('hasCompletedTour sebagai string "true"', () {
        final result = UserProfile.fromJson({'hasCompletedTour': 'true'});
        expect(result.hasCompletedTour, true);
      });

      test('hasCompletedTour sebagai int 1', () {
        final result = UserProfile.fromJson({'hasCompletedTour': 1});
        expect(result.hasCompletedTour, true);
      });

      test('name sebagai int → convert ke string', () {
        final result = UserProfile.fromJson({'name': 99});
        expect(result.name, '99');
      });

      test('avatarUrl key absent → null', () {
        final result = UserProfile.fromJson({'name': 'Budi'});
        expect(result.avatarUrl, null);
      });

      test('avatarUrl explicit null → null', () {
        final result = UserProfile.fromJson({'name': 'Budi', 'avatarUrl': null});
        expect(result.avatarUrl, null);
      });
    });

    group('toJson', () {
      test('avatarUrl null → key tidak hadir', () {
        const profile = UserProfile(name: 'Budi', phone: '081234567890');
        final json = profile.toJson();
        expect(json.containsKey('avatarUrl'), false);
      });

      test('avatarUrl ada → key hadir', () {
        const profile = UserProfile(
          name: 'Budi',
          avatarUrl: 'https://example.com/img.jpg',
        );
        final json = profile.toJson();
        expect(json['avatarUrl'], 'https://example.com/img.jpg');
      });

      test('round-trip: toJson → fromJson → sama', () {
        const original = UserProfile(
          name: 'Budi Santoso',
          phone: '081234567890',
          address: 'Jl. Kandang No.1, Bogor',
          hasCompletedTour: true,
          avatarUrl: 'https://example.com/img.jpg',
        );
        final json = original.toJson();
        final restored = UserProfile.fromJson(json);
        expect(restored.name, original.name);
        expect(restored.phone, original.phone);
        expect(restored.address, original.address);
        expect(restored.hasCompletedTour, original.hasCompletedTour);
        expect(restored.avatarUrl, original.avatarUrl);
      });

      test('4 base key selalu hadir', () {
        const profile = UserProfile(name: 'Test');
        final json = profile.toJson();
        expect(json.containsKey('name'), true);
        expect(json.containsKey('phone'), true);
        expect(json.containsKey('address'), true);
        expect(json.containsKey('hasCompletedTour'), true);
      });
    });

    group('copyWith', () {
      const base = UserProfile(
        name: 'Budi Santoso',
        phone: '081234567890',
        address: 'Jl. Kandang No.1, Bogor',
        hasCompletedTour: false,
        avatarUrl: 'https://example.com/old.jpg',
      );

      test('tanpa argumen → identik', () {
        final copy = base.copyWith();
        expect(copy.name, base.name);
        expect(copy.phone, base.phone);
        expect(copy.address, base.address);
        expect(copy.hasCompletedTour, base.hasCompletedTour);
        expect(copy.avatarUrl, base.avatarUrl);
      });

      test('update hasCompletedTour ke true', () {
        final copy = base.copyWith(hasCompletedTour: true);
        expect(copy.hasCompletedTour, true);
        expect(copy.name, base.name);
      });

      test('update name saja', () {
        final copy = base.copyWith(name: 'Sari Dewi');
        expect(copy.name, 'Sari Dewi');
        expect(copy.phone, base.phone);
      });

      test('update avatarUrl ke URL baru', () {
        final copy = base.copyWith(avatarUrl: 'https://example.com/new.jpg');
        expect(copy.avatarUrl, 'https://example.com/new.jpg');
      });

      test('update avatarUrl ke null → masih pakai lama (same bug as CageData)', () {
        // ⚠️  Potensi Bug: sama seperti CageData — tidak bisa clear avatarUrl via copyWith.
        final copy = base.copyWith(avatarUrl: null);
        expect(copy.avatarUrl, base.avatarUrl);
      });
    });

    group('toString', () {
      test('format mencantumkan semua field penting', () {
        const profile = UserProfile(
          name: 'Budi Santoso',
          phone: '081234567890',
          address: 'Jl. Kandang No.1, Bogor',
          hasCompletedTour: true,
        );
        final s = profile.toString();
        expect(s.contains('Budi Santoso'), true);
        expect(s.contains('081234567890'), true);
        expect(s.contains('Jl. Kandang No.1, Bogor'), true);
        expect(s.contains('true'), true);
      });
    });
  });
}
