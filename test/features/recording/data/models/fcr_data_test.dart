import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/recording/data/models/fcr_data.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // FCRData — constructor & toJson
  // ─────────────────────────────────────────────────────────────────────────
  group('FCRData', () {
    group('constructor', () {
      test('happy path — semua field terisi', () {
        const data = FCRData(
          mingguKe: 1,
          totalPakan: 160.0,
          sisaAyam: 982,
          beratAyam: 2111.3,
          fcr: 1.49,
        );

        expect(data.mingguKe, 1);
        expect(data.totalPakan, 160.0);
        expect(data.sisaAyam, 982);
        expect(data.beratAyam, 2111.3);
        expect(data.fcr, 1.49);
      });

      test('mingguKe bisa lebih dari 1', () {
        const data = FCRData(
          mingguKe: 5,
          totalPakan: 3200.0,
          sisaAyam: 950,
          beratAyam: 2042.5,
          fcr: 1.57,
        );
        expect(data.mingguKe, 5);
      });

      test('FCR nol — edge case tidak ada biomass', () {
        const data = FCRData(
          mingguKe: 1,
          totalPakan: 0,
          sisaAyam: 0,
          beratAyam: 0,
          fcr: 0,
        );
        expect(data.fcr, 0.0);
      });
    });

    group('toJson', () {
      test('semua key hadir dengan nilai benar', () {
        const data = FCRData(
          mingguKe: 2,
          totalPakan: 320.0,
          sisaAyam: 975,
          beratAyam: 2096.25,
          fcr: 1.53,
        );

        final json = data.toJson();

        expect(json['minggu_ke'], 2);
        expect(json['total_pakan'], 320.0);
        expect(json['sisa_ayam'], 975);
        expect(json['berat_ayam'], 2096.25);
        expect(json['fcr'], 1.53);
      });

      test('key names menggunakan underscore (snake_case)', () {
        const data = FCRData(
          mingguKe: 1,
          totalPakan: 50.0,
          sisaAyam: 1000,
          beratAyam: 400.0,
          fcr: 0.13,
        );
        final json = data.toJson();
        expect(json.containsKey('minggu_ke'), true);
        expect(json.containsKey('total_pakan'), true);
        expect(json.containsKey('sisa_ayam'), true);
        expect(json.containsKey('berat_ayam'), true);
        expect(json.containsKey('fcr'), true);
        // Pastikan tidak ada camelCase yang bocor
        expect(json.containsKey('mingguKe'), false);
        expect(json.containsKey('totalPakan'), false);
      });

      test('toJson menghasilkan 5 key', () {
        const data = FCRData(
          mingguKe: 1,
          totalPakan: 50.0,
          sisaAyam: 1000,
          beratAyam: 400.0,
          fcr: 0.13,
        );
        expect(data.toJson().length, 5);
      });
    });
  });
}
