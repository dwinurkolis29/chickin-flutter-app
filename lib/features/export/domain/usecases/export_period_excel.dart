import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:recording_app/features/export/data/exporters/excel_exporter.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';

/// Generates an Excel workbook from [PeriodReport], saves to tmp dir, and shares.
class ExportPeriodExcel {
  final ExcelExporter _exporter;

  ExportPeriodExcel({ExcelExporter? exporter})
      : _exporter = exporter ?? ExcelExporter();

  Future<void> execute(PeriodReport report) async {
    final bytes = _exporter.export(report);
    final dir = await getTemporaryDirectory();
    final safeName = report.period.name.replaceAll(RegExp(r'[^\w]'), '_');
    final file = File('${dir.path}/${safeName}_report.xlsx');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [
        XFile(
          file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        )
      ],
      subject: 'Period Report – ${report.period.name}',
    );
  }
}
