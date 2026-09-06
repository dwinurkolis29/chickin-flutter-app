import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/export/domain/usecases/period_pdf_document_builder.dart';
import 'package:recording_app/features/finance/data/models/finance_summary.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/domain/usecases/period_comparison_calculator.dart';

void main() {
  group('PeriodPdfDocumentBuilder', () {
    late PeriodPdfDocumentBuilder builder;

    setUp(() {
      builder = PeriodPdfDocumentBuilder();
    });

    test('menghasilkan data bytes PDF valid tanpa error', () async {
      final period = PeriodData(
        id: 'p-12',
        name: 'Periode 12',
        initialCapacity: 5000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 8, 5),
        createdAt: DateTime(2026, 7, 1),
      );

      final report = PeriodReport(
        period: period,
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

      const finance = FinanceSummary(
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

      final comparison = PeriodComparisonCalculator().execute(
        currentReport: report,
        currentFinance: finance,
      );

      const cage = CageData(
        name: 'Kandang Sumber Rejeki',
        capacity: 5000,
        type: 'Closed House',
        location: 'Malang',
      );

      final pdfBytes = await builder.buildPdf(
        report: report,
        finance: finance,
        comparison: comparison,
        cage: cage,
      );

      expect(pdfBytes, isNotEmpty);
      // Valid PDF files start with '%PDF-' header
      final headerStr = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(headerStr, '%PDF-');
    });
  });
}
