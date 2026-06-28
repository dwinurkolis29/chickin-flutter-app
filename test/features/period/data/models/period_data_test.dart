import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

void main() {
  final baseDate = DateTime(2025, 3, 1);
  final createdAt = DateTime(2025, 3, 1);
  final endDate = DateTime(2025, 6, 1); // 35 hari dari baseDate + creep

  // ─────────────────────────────────────────────────────────────────────────
  // WeeklyFCR
  // ─────────────────────────────────────────────────────────────────────────
  group('WeeklyFCR', () {
    group('default values', () {
      test('week default 0', () => expect(const WeeklyFCR().week, 0));
      test('fcr default 0.0', () => expect(const WeeklyFCR().fcr, 0.0));
    });

    group('fromJson — null', () {
      test('null → default tanpa throw', () {
        expect(() => WeeklyFCR.fromJson(null), returnsNormally);
        final r = WeeklyFCR.fromJson(null);
        expect(r.week, 0);
        expect(r.fcr, 0.0);
      });
    });

    group('fromJson — happy path', () {
      test('week dan fcr terisi', () {
        final r = WeeklyFCR.fromJson({'week': 3, 'fcr': 1.42});
        expect(r.week, 3);
        expect(r.fcr, 1.42);
      });
    });

    group('fromJson — invalid types', () {
      test('fcr sebagai string → parse', () {
        final r = WeeklyFCR.fromJson({'week': 1, 'fcr': '1.57'});
        expect(r.fcr, 1.57);
      });

      test('{} → semua default', () {
        final r = WeeklyFCR.fromJson({});
        expect(r.week, 0);
        expect(r.fcr, 0.0);
      });
    });

    group('toJson', () {
      test('round-trip', () {
        const original = WeeklyFCR(week: 5, fcr: 1.63);
        final json = original.toJson();
        final restored = WeeklyFCR.fromJson(json);
        expect(restored.week, original.week);
        expect(restored.fcr, original.fcr);
      });

      test('2 key hadir', () {
        const w = WeeklyFCR(week: 1, fcr: 1.4);
        final json = w.toJson();
        expect(json.containsKey('week'), true);
        expect(json.containsKey('fcr'), true);
        expect(json.length, 2);
      });
    });

    group('copyWith', () {
      test('update week', () {
        const w = WeeklyFCR(week: 1, fcr: 1.4);
        expect(w.copyWith(week: 2).week, 2);
        expect(w.copyWith(week: 2).fcr, 1.4);
      });

      test('update fcr', () {
        const w = WeeklyFCR(week: 1, fcr: 1.4);
        expect(w.copyWith(fcr: 1.65).fcr, 1.65);
      });
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PeriodSummary
  // ─────────────────────────────────────────────────────────────────────────
  group('PeriodSummary', () {
    group('default values', () {
      test('totalFeedKg 0', () => expect(const PeriodSummary().totalFeedKg, 0.0));
      test('finalPopulation 0', () => expect(const PeriodSummary().finalPopulation, 0));
      test('totalMortality 0', () => expect(const PeriodSummary().totalMortality, 0));
      test('finalBiomass 0', () => expect(const PeriodSummary().finalBiomass, 0.0));
      test('finalFCR 0', () => expect(const PeriodSummary().finalFCR, 0.0));
      test('avgDailyGain 0', () => expect(const PeriodSummary().avgDailyGain, 0.0));
      test('weeklyFCR empty list', () => expect(const PeriodSummary().weeklyFCR, []));
      test('insights empty list', () => expect(const PeriodSummary().insights, []));
    });

    group('fromJson — null', () {
      test('null → default tanpa throw', () {
        expect(() => PeriodSummary.fromJson(null), returnsNormally);
        final r = PeriodSummary.fromJson(null);
        expect(r.finalFCR, 0.0);
        expect(r.weeklyFCR, []);
      });
    });

    group('fromJson — happy path', () {
      test('data lengkap dengan weeklyFCR dan insights', () {
        final json = {
          'totalFeedKg': 3200.0,
          'finalPopulation': 982,
          'totalMortality': 18,
          'finalBiomass': 2112.3,
          'finalFCR': 1.51,
          'avgDailyGain': 57.4,
          'weeklyFCR': [
            {'week': 1, 'fcr': 0.68},
            {'week': 2, 'fcr': 1.12},
            {'week': 5, 'fcr': 1.51},
          ],
          'insights': [
            'FCR sangat baik (1.51) — efisiensi pakan optimal',
            'Mortalitas rendah (1.8%) — manajemen kesehatan baik',
          ],
        };
        final result = PeriodSummary.fromJson(json);
        expect(result.totalFeedKg, 3200.0);
        expect(result.finalPopulation, 982);
        expect(result.totalMortality, 18);
        expect(result.finalFCR, 1.51);
        expect(result.avgDailyGain, 57.4);
        expect(result.weeklyFCR.length, 3);
        expect(result.weeklyFCR.first.week, 1);
        expect(result.weeklyFCR.last.fcr, 1.51);
        expect(result.insights.length, 2);
        expect(result.insights.first.contains('FCR'), true);
      });

      test('weeklyFCR null → []', () {
        final result = PeriodSummary.fromJson({'totalFeedKg': 100.0});
        expect(result.weeklyFCR, []);
      });

      test('insights null → []', () {
        final result = PeriodSummary.fromJson({'totalFeedKg': 100.0});
        expect(result.insights, []);
      });
    });

    group('fromJson — invalid types', () {
      test('totalFeedKg sebagai string', () {
        final result = PeriodSummary.fromJson({'totalFeedKg': '3200'});
        expect(result.totalFeedKg, 3200.0);
      });

      test('finalPopulation sebagai double', () {
        final result = PeriodSummary.fromJson({'finalPopulation': 982.9});
        expect(result.finalPopulation, 982);
      });
    });

    group('toJson', () {
      test('round-trip lengkap', () {
        const original = PeriodSummary(
          totalFeedKg: 3200.0,
          finalPopulation: 982,
          totalMortality: 18,
          finalBiomass: 2112.3,
          finalFCR: 1.51,
          avgDailyGain: 57.4,
          weeklyFCR: [WeeklyFCR(week: 1, fcr: 0.68), WeeklyFCR(week: 5, fcr: 1.51)],
          insights: ['FCR baik', 'Mortalitas rendah'],
        );
        final json = original.toJson();
        final restored = PeriodSummary.fromJson(json);
        expect(restored.totalFeedKg, original.totalFeedKg);
        expect(restored.finalFCR, original.finalFCR);
        expect(restored.weeklyFCR.length, 2);
        expect(restored.insights.length, 2);
      });
    });

    group('copyWith', () {
      const base = PeriodSummary(
        totalFeedKg: 3200.0,
        finalFCR: 1.51,
        insights: ['FCR baik'],
      );

      test('update finalFCR', () {
        final copy = base.copyWith(finalFCR: 1.65);
        expect(copy.finalFCR, 1.65);
        expect(copy.totalFeedKg, base.totalFeedKg);
      });

      test('update insights', () {
        final copy = base.copyWith(insights: ['FCR tinggi', 'Cek pakan']);
        expect(copy.insights.length, 2);
        expect(copy.insights.first, 'FCR tinggi');
      });

      test('tanpa argumen → identik', () {
        final copy = base.copyWith();
        expect(copy.totalFeedKg, base.totalFeedKg);
        expect(copy.finalFCR, base.finalFCR);
        expect(copy.insights, base.insights);
      });
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PeriodData
  // ─────────────────────────────────────────────────────────────────────────
  group('PeriodData', () {
    group('default values', () {
      test('id default ""', () {
        expect(PeriodData(startDate: baseDate, createdAt: createdAt).id, '');
      });

      test('initialWeight default 0.4', () {
        expect(PeriodData(startDate: baseDate, createdAt: createdAt).initialWeight, 0.4);
      });

      test('isActive default true', () {
        expect(PeriodData(startDate: baseDate, createdAt: createdAt).isActive, true);
      });

      test('isDeleted default false', () {
        expect(PeriodData(startDate: baseDate, createdAt: createdAt).isDeleted, false);
      });

      test('endDate default null', () {
        expect(PeriodData(startDate: baseDate, createdAt: createdAt).endDate, null);
      });

      test('summary default null', () {
        expect(PeriodData(startDate: baseDate, createdAt: createdAt).summary, null);
      });
    });

    group('fromJson — null', () {
      test('null → default object tanpa throw', () {
        expect(() => PeriodData.fromJson(null), returnsNormally);
        final result = PeriodData.fromJson(null);
        expect(result.id, '');
        expect(result.initialWeight, 0.4);
        expect(result.isActive, true);
      });
    });

    group('fromJson — partial (no Timestamp)', () {
      test('{} → default dengan initialWeight 0.4', () {
        final result = PeriodData.fromJson({});
        expect(result.initialWeight, 0.4); // defaultValue dari asDouble
        expect(result.isActive, true);
        expect(result.isDeleted, false);
      });

      test('name dan initialCapacity terisi', () {
        final result = PeriodData.fromJson({
          'name': 'Periode Maret 2025',
          'initialCapacity': 1000,
          'initialWeight': 0.4,
          'isActive': true,
          'isDeleted': false,
        });
        expect(result.name, 'Periode Maret 2025');
        expect(result.initialCapacity, 1000);
      });

      test('docId override id', () {
        final result = PeriodData.fromJson({}, docId: 'period-abc');
        expect(result.id, 'period-abc');
      });

      test('isActive sebagai string "false"', () {
        final result = PeriodData.fromJson({'isActive': 'false'});
        expect(result.isActive, false);
      });

      test('initialWeight default 0.4 jika key tidak ada', () {
        final result = PeriodData.fromJson({'name': 'Test'});
        expect(result.initialWeight, 0.4);
      });

      test('summary null jika key tidak ada', () {
        final result = PeriodData.fromJson({'name': 'Test'});
        expect(result.summary, null);
      });

      test('summary di-parse jika ada', () {
        final result = PeriodData.fromJson({
          'name': 'Test',
          'summary': {
            'totalFeedKg': 3200.0,
            'finalFCR': 1.51,
          },
        });
        expect(result.summary, isNotNull);
        expect(result.summary!.totalFeedKg, 3200.0);
        expect(result.summary!.finalFCR, 1.51);
      });
    });

    group('copyWith — sentinel pattern untuk endDate & summary', () {
      final base = PeriodData(
        id: 'period-001',
        name: 'Periode Maret 2025',
        initialCapacity: 1000,
        startDate: baseDate,
        endDate: endDate,
        createdAt: createdAt,
        summary: const PeriodSummary(finalFCR: 1.51),
      );

      test('tanpa argumen → identik', () {
        final copy = base.copyWith();
        expect(copy.id, base.id);
        expect(copy.endDate, base.endDate);
        expect(copy.summary?.finalFCR, base.summary?.finalFCR);
      });

      test('update name saja', () {
        final copy = base.copyWith(name: 'Periode April 2025');
        expect(copy.name, 'Periode April 2025');
        expect(copy.endDate, base.endDate);
      });

      test('set endDate ke null secara eksplisit (sentinel)', () {
        final copy = base.copyWith(endDate: null);
        expect(copy.endDate, null);
      });

      test('set summary ke null secara eksplisit (sentinel)', () {
        final copy = base.copyWith(summary: null);
        expect(copy.summary, null);
      });

      test('update isActive ke false (close period)', () {
        final copy = base.copyWith(isActive: false, endDate: endDate);
        expect(copy.isActive, false);
        expect(copy.endDate, endDate);
      });

      test('isDeleted ke true (soft delete)', () {
        final copy = base.copyWith(isDeleted: true);
        expect(copy.isDeleted, true);
      });
    });

    group('toString', () {
      test('format mencantumkan id dan name', () {
        final p = PeriodData(
          id: 'period-001',
          name: 'Periode Maret 2025',
          startDate: baseDate,
          createdAt: createdAt,
        );
        final s = p.toString();
        expect(s.contains('period-001'), true);
        expect(s.contains('Periode Maret 2025'), true);
      });
    });
  });
}
