import 'package:csv/csv.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';

/// Converts a [PeriodReport] into a CSV-formatted [String].
///
/// Output sections:
///   1. Period Summary (key-value pairs)
///   2. Daily Recordings table
class CsvExporter {
  String export(PeriodReport report) {
    final List<List<dynamic>> rows = [];

    // ── Section 1: Summary ─────────────────────────────────────────────────────
    rows.add(['PERIOD REPORT']);
    rows.add(['Period', report.period.name]);
    rows.add(['Start Date', _fmt(report.period.startDate)]);
    rows.add([
      'End Date',
      report.period.endDate != null ? _fmt(report.period.endDate!) : '-'
    ]);
    rows.add(['Duration (days)', report.durationDays]);
    rows.add([
      'Status',
      report.period.isActive ? 'Active' : 'Closed'
    ]);
    rows.add([]);

    // Population
    rows.add(['--- POPULATION ---']);
    rows.add(['Initial Population', report.initialPopulation]);
    rows.add(['Total Mortality', report.totalMortality]);
    rows.add(['Final Population', report.finalPopulation]);
    rows.add(['Mortality Rate (%)', report.mortalityRate.toStringAsFixed(2)]);
    rows.add([]);

    // Performance
    rows.add(['--- PERFORMANCE ---']);
    rows.add(['Total Feed (kg)', report.totalFeedKg.toStringAsFixed(2)]);
    rows.add(['Final Avg Weight (g)', report.finalAvgWeightGram]);
    rows.add(['Total Biomass (kg)', report.totalBiomassKg.toStringAsFixed(2)]);
    rows.add(['Weight Gain (kg)', report.weightGainKg.toStringAsFixed(2)]);
    rows.add(['FCR', report.fcr.toStringAsFixed(2)]);
    rows.add([]);

    // Analytics
    rows.add(['--- ANALYTICS ---']);
    rows.add([
      'Avg Daily Gain (g/day)',
      report.avgDailyGainGram.toStringAsFixed(2)
    ]);
    rows.add(['Feed per Bird (kg)', report.feedPerBird.toStringAsFixed(3)]);
    rows.add(['Survival Rate (%)', report.survivalRate.toStringAsFixed(2)]);
    rows.add([]);

    // ── Section 2: Daily Recordings ────────────────────────────────────────────
    rows.add(['--- DAILY RECORDINGS ---']);
    rows.add(['Day', 'Mortality', 'Feed Sacks', 'Avg Weight (g)']);
    for (final r in report.recordings) {
      rows.add([r.day, r.mortality, r.feedSack, r.avgWeightGram]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
