import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:recording_app/features/export/data/exporters/csv_exporter.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';

/// Generates a CSV from [PeriodReport], saves to tmp dir, and shares via OS share sheet.
class ExportPeriodCsv {
  final CsvExporter _exporter;

  ExportPeriodCsv({CsvExporter? exporter})
      : _exporter = exporter ?? CsvExporter();

  Future<void> execute(PeriodReport report) async {
    final csvString = _exporter.export(report);
    final dir = await getTemporaryDirectory();
    final safeName = report.period.name.replaceAll(RegExp(r'[^\w]'), '_');
    final file = File('${dir.path}/${safeName}_report.csv');
    await file.writeAsString(csvString);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Period Report – ${report.period.name}',
    );
  }
}
