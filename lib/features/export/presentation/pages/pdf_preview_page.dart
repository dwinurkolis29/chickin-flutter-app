import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../../core/components/header/app_header.dart';
import '../../../cage/data/models/cage_data.dart';
import '../../../finance/data/models/finance_summary.dart';
import '../../../reporting/domain/usecases/generate_period_report.dart';
import '../../../reporting/domain/usecases/period_comparison_calculator.dart';
import '../../domain/usecases/period_pdf_document_builder.dart';

/// Halaman Pratinjau Dokumen PDF Laporan Periode
/// Menyediakan fitur pratinjau interaktif, cetak langsung (print), dan bagikan (share) PDF.
class PdfPreviewPage extends StatelessWidget {
  final PeriodReport report;
  final FinanceSummary finance;
  final PeriodDeltaComparison comparison;
  final CageData cage;

  const PdfPreviewPage({
    super.key,
    required this.report,
    required this.finance,
    required this.comparison,
    required this.cage,
  });

  Future<Uint8List> _generatePdf() {
    return PeriodPdfDocumentBuilder().buildPdf(
      report: report,
      finance: finance,
      comparison: comparison,
      cage: cage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sanitizedFileName =
        'Laporan_${report.period.name.replaceAll(RegExp(r'\s+'), '_')}.pdf';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppHeader(
        title: 'Pratinjau Laporan PDF',
      ),
      body: SafeArea(
        child: PdfPreview(
          build: (format) => _generatePdf(),
          canChangeOrientation: false,
          canChangePageFormat: false,
          allowPrinting: true,
          allowSharing: true,
          canDebug: false,
          pdfFileName: sanitizedFileName,
          loadingWidget: const Center(
            child: CircularProgressIndicator(),
          ),
          actions: const [],
        ),
      ),
    );
  }
}
