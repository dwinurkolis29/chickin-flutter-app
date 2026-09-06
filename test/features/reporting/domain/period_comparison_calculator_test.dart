import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/finance/data/models/finance_summary.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/domain/usecases/period_comparison_calculator.dart';

void main() {
  group('PeriodComparisonCalculator', () {
    late PeriodComparisonCalculator calculator;

    setUp(() {
      calculator = PeriodComparisonCalculator();
    });

    final currentPeriod = PeriodData(
      id: 'p-12',
      name: 'Periode 12',
      initialCapacity: 5000,
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 8, 5),
      createdAt: DateTime(2026, 7, 1),
    );

    final currentReport = PeriodReport(
      period: currentPeriod,
      recordings: [],
      initialPopulation: 5000,
      totalMortality: 150,
      finalPopulation: 4850,
      mortalityRate: 3.0,
      totalFeedKg: 14711.4,
      finalAvgWeightGram: 2020,
      totalBiomassKg: 8916.0,
      weightGainKg: 6916.0,
      fcr: 1.65,
      avgDailyGainGram: 50.0,
      feedPerBird: 3.03,
      survivalRate: 97.0,
      durationDays: 35,
      harvestedChicks: 4850,
      harvestedWeightKg: 8916.0,
      avgHarvestWeightKg: 1.838,
      ipScore: 380.0,
    );

    final currentFinance = const FinanceSummary(
      totalRevenue: 187500000.0,
      mainHarvestRevenue: 177120000.0,
      rejectRevenue: 10380000.0,
      totalExpense: 127000000.0,
      feedExpense: 76454000.0,
      docExpense: 37465000.0,
      ovkExpense: 4953000.0,
      operationalExpense: 8001000.0,
      netProfit: 60500000.0,
      hppPerKg: 14244.0,
      feedExpensePct: 60.2,
      docExpensePct: 29.5,
      ovkExpensePct: 3.9,
      operationalExpensePct: 6.3,
      totalHarvestWeightKg: 8916.0,
      totalChicksSold: 4850,
    );

    test('menghitung delta saat ada periode sebelumnya (P11)', () {
      final prevPeriod = PeriodData(
        id: 'p-11',
        name: 'Periode 11',
        initialCapacity: 5000,
        startDate: DateTime(2026, 5, 20),
        endDate: DateTime(2026, 6, 25),
        createdAt: DateTime(2026, 5, 20),
      );

      final prevReport = PeriodReport(
        period: prevPeriod,
        recordings: [],
        initialPopulation: 5000,
        totalMortality: 175,
        finalPopulation: 4825,
        mortalityRate: 3.5,
        totalFeedKg: 14500.0,
        finalAvgWeightGram: 1940,
        totalBiomassKg: 8500.0,
        weightGainKg: 6500.0,
        fcr: 1.68,
        avgDailyGainGram: 48.0,
        feedPerBird: 3.0,
        survivalRate: 96.5,
        durationDays: 35,
      );

      final prevFinance = const FinanceSummary(
        totalRevenue: 170000000.0,
        totalExpense: 118000000.0,
        netProfit: 52000000.0, // laba naik 8,5 jt
        hppPerKg: 13882.0,
      );

      final result = calculator.execute(
        currentReport: currentReport,
        currentFinance: currentFinance,
        previousReport: prevReport,
        previousFinance: prevFinance,
        recentPeriods: [
          PeriodData(id: 'p-10', name: 'Periode 10', startDate: DateTime(2026, 4, 1), createdAt: DateTime(2026, 4, 1)),
          prevPeriod,
          currentPeriod,
        ],
      );

      // Verifikasi nilai teks utama
      expect(result.netProfitText, 'Rp60,5 JT');
      expect(result.mortalityText, '3,0%');
      expect(result.weightText, '2,02 KG');
      expect(result.fcrText, '1,65');

      // Verifikasi delta panah
      expect(result.netProfitDeltaText, contains('↑'));
      expect(result.netProfitDeltaText, contains('8,5 jt'));

      expect(result.mortalityDeltaText, contains('↓'));
      expect(result.mortalityDeltaText, contains('0,5%'));

      expect(result.weightDeltaText, contains('↑'));
      expect(result.weightDeltaText, contains('0,08'));

      expect(result.fcrDeltaText, contains('↓'));
      expect(result.fcrDeltaText, contains('0,03'));

      expect(result.hppComparisonLabel, 'dibanding Periode 11');

      // Tren 3 periode
      expect(result.threePeriodSequence, 'Periode 10 → Periode 11 → Periode 12');
    });

    test('menangani kasus periode pertama tanpa periode sebelumnya secara aman', () {
      final result = calculator.execute(
        currentReport: currentReport,
        currentFinance: currentFinance,
        previousReport: null,
        previousFinance: null,
      );

      expect(result.netProfitText, 'Rp60,5 JT');
      expect(result.netProfitDeltaText, '-');
      expect(result.mortalityDeltaText, '-');
      expect(result.fcrDeltaText, '-');
      expect(result.hppComparisonLabel, 'Periode Pertama');
      expect(result.threePeriodSequence, 'Periode 12');
    });

    test('menangani data keuangan kosong secara aman (placeholder Rp0)', () {
      final result = calculator.execute(
        currentReport: currentReport,
        currentFinance: const FinanceSummary(), // no transactions
        previousReport: null,
        previousFinance: null,
      );

      expect(result.netProfitText, 'Rp0 (Belum Dicatat)');
      expect(result.mortalityText, '3,0%');
      expect(result.fcrText, '1,65');
    });
  });
}
