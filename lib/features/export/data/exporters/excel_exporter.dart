import 'package:excel/excel.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';

/// Converts a [PeriodReport] into an Excel workbook ([List<int>] bytes).
///
/// Sheets:
///   - "Summary" : period KPIs in key-value layout
///   - "Daily Data" : recording rows with header
class ExcelExporter {
  List<int> export(PeriodReport report) {
    final excel = Excel.createExcel();

    // Remove default Sheet1 if it exists
    excel.delete('Sheet1');

    _buildSummarySheet(excel, report);
    _buildDailySheet(excel, report);

    final bytes = excel.save();
    return bytes ?? [];
  }

  // ── Summary Sheet ──────────────────────────────────────────────────────────
  void _buildSummarySheet(Excel excel, PeriodReport report) {
    final sheet = excel['Summary'];

    void addRow(String label, dynamic value) {
      sheet.appendRow([
        TextCellValue(label),
        TextCellValue(value.toString()),
      ]);
    }

    addRow('Period', report.period.name);
    addRow('Start Date', _fmt(report.period.startDate));
    addRow(
        'End Date',
        report.period.endDate != null
            ? _fmt(report.period.endDate!)
            : '-');
    addRow('Duration (days)', report.durationDays.toString());
    addRow('Status', report.period.isActive ? 'Active' : 'Closed');

    sheet.appendRow([TextCellValue('')]);

    addRow('--- POPULATION ---', '');
    addRow('Initial Population', report.initialPopulation.toString());
    addRow('Total Mortality', report.totalMortality.toString());
    addRow('Final Population', report.finalPopulation.toString());
    addRow('Mortality Rate (%)', report.mortalityRate.toStringAsFixed(2));

    sheet.appendRow([TextCellValue('')]);

    addRow('--- PERFORMANCE ---', '');
    addRow('Total Feed (kg)', report.totalFeedKg.toStringAsFixed(2));
    addRow('Final Avg Weight (g)', report.finalAvgWeightGram.toString());
    addRow('Total Biomass (kg)', report.totalBiomassKg.toStringAsFixed(2));
    addRow('Weight Gain (kg)', report.weightGainKg.toStringAsFixed(2));
    addRow('FCR', report.fcr.toStringAsFixed(2));

    sheet.appendRow([TextCellValue('')]);

    addRow('--- ANALYTICS ---', '');
    addRow('Avg Daily Gain (g/day)',
        report.avgDailyGainGram.toStringAsFixed(2));
    addRow('Feed per Bird (kg)', report.feedPerBird.toStringAsFixed(3));
    addRow('Survival Rate (%)', report.survivalRate.toStringAsFixed(2));

    // Style: widen column A
    sheet.setColumnWidth(0, 28);
    sheet.setColumnWidth(1, 18);
  }

  // ── Daily Data Sheet ────────────────────────────────────────────────────────
  void _buildDailySheet(Excel excel, PeriodReport report) {
    final sheet = excel['Daily Data'];

    // Header row
    sheet.appendRow([
      TextCellValue('Day'),
      TextCellValue('Mortality'),
      TextCellValue('Feed Sacks'),
      TextCellValue('Avg Weight (g)'),
    ]);

    for (final r in report.recordings) {
      sheet.appendRow([
        IntCellValue(r.day),
        IntCellValue(r.mortality),
        IntCellValue(r.feedSack),
        IntCellValue(r.avgWeightGram),
      ]);
    }

    for (int i = 0; i < 4; i++) {
      sheet.setColumnWidth(i, 16);
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
