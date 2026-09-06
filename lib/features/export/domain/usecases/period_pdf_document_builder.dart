import 'dart:typed_data';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/finance/data/models/finance_summary.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/domain/usecases/period_comparison_calculator.dart';

/// Builder untuk menghasilkan dokumen Laporan Periode PDF A4 1 Halaman
/// sesuai format wireframe Chickin (BroilerKu).
class PeriodPdfDocumentBuilder {
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF1A47E5);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF0A1128);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF5A6680);
  static const PdfColor _cardBg = PdfColor.fromInt(0xFFF5F7FF);
  static const PdfColor _cardBorder = PdfColor.fromInt(0xFFCDD5EE);
  static const PdfColor _dividerColor = PdfColor.fromInt(0xFFE8ECFB);
  static const PdfColor _successGreen = PdfColor.fromInt(0xFF16A34A);
  static const PdfColor _warningAmber = PdfColor.fromInt(0xFFD97706);

  String _clean(String text) {
    return text
        .replaceAll('✓', '[OK]')
        .replaceAll('⚠', '[!]')
        .replaceAll('•', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('↑', '+')
        .replaceAll('↓', '-')
        .replaceAll('→', '->');
  }

  Future<Uint8List> buildPdf({
    required PeriodReport report,
    required FinanceSummary finance,
    required PeriodDeltaComparison comparison,
    required CageData cage,
  }) async {
    await initializeDateFormatting('id_ID', null);
    final pdf = pw.Document();

    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');
    final startDateStr = dateFmt.format(report.period.startDate);
    final endDateStr = report.period.endDate != null
        ? dateFmt.format(report.period.endDate!)
        : 'Aktif';
    final dateRangeStr = '$startDateStr - $endDateStr - ${report.durationDays} hari';

    final numFmt = NumberFormat.decimalPattern('id_ID');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── 1. HEADER SECTION ──────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          report.period.name.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          cage.name.isNotEmpty ? cage.name : 'Kandang Utama',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          dateRangeStr,
                          style: const pw.TextStyle(
                            color: PdfColor.fromInt(0xFFD0DCFF),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFF2855F0),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'CHICKIN REPORT',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'BroilerKu Farm Management',
                            style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xFFD0DCFF),
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // ── 2. ROW 1 KPI (LABA, MORTALITAS, BOBOT) ─────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: _cardBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: _cardBorder, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    // Col 1: Laba
                    _buildKpiColumn(
                      value: _clean(comparison.netProfitText),
                      label: 'LABA',
                      delta: _clean(comparison.netProfitDeltaText),
                      deltaColor: comparison.isProfitImproved ? _successGreen : _warningAmber,
                    ),
                    _buildVerticalDivider(),
                    // Col 2: Mortalitas
                    _buildKpiColumn(
                      value: _clean(comparison.mortalityText),
                      label: 'MORTALITAS',
                      delta: _clean(comparison.mortalityDeltaText),
                      deltaColor: comparison.isMortalityImproved ? _successGreen : _warningAmber,
                    ),
                    _buildVerticalDivider(),
                    // Col 3: Bobot
                    _buildKpiColumn(
                      value: _clean(comparison.weightText),
                      label: 'BOBOT',
                      delta: _clean(comparison.weightDeltaText),
                      deltaColor: comparison.isWeightImproved ? _successGreen : _warningAmber,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // ── 3. ROW 2 KPI (FCR & HPP) ───────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: _cardBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: _cardBorder, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniKpi(
                      title: 'FCR ${_clean(comparison.fcrText)}',
                      subtitle: _clean(comparison.fcrDeltaText),
                      deltaColor: comparison.isFcrImproved ? _successGreen : _warningAmber,
                    ),
                    _buildVerticalDivider(),
                    _buildMiniKpi(
                      title: _clean(comparison.hppText),
                      subtitle: _clean(comparison.hppComparisonLabel),
                      deltaColor: _textSecondary,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // ── 4. INSIGHT PERIODE ─────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF0F4FF),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFD2DEFF), width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          'INSIGHT PERIODE',
                          style: pw.TextStyle(
                            color: _primaryColor,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    ...comparison.periodInsights.map(
                      (insight) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Text(
                          _clean(insight),
                          style: pw.TextStyle(
                            color: _textPrimary,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // ── 5. HASIL PANEN & KEUANGAN (TWO COLUMNS) ─────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // SISI KIRI: HASIL PANEN
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: _cardBg,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: _cardBorder, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'HASIL PANEN',
                            style: pw.TextStyle(
                              color: _primaryColor,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${numFmt.format(report.initialPopulation)} DOC -> ${numFmt.format(report.finalPopulation)} panen',
                            style: const pw.TextStyle(
                              color: _textSecondary,
                              fontSize: 9,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          _buildDataRow(
                            'Total berat',
                            '${report.totalBiomassKg.toStringAsFixed(0)} kg',
                          ),
                          _buildDataRow(
                            'Penjualan utama',
                            finance.mainHarvestRevenue > 0
                                ? formatCompactRupiah(finance.mainHarvestRevenue)
                                : 'Rp0',
                          ),
                          _buildDataRow(
                            'Afkir / reject',
                            finance.rejectRevenue > 0
                                ? formatCompactRupiah(finance.rejectRevenue)
                                : 'Rp0',
                          ),
                          pw.Divider(color: _dividerColor, height: 10),
                          _buildDataRow(
                            'Total pendapatan',
                            finance.totalRevenue > 0
                                ? formatCompactRupiah(finance.totalRevenue)
                                : 'Rp0',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),

                  // SISI KANAN: KEUANGAN
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: _cardBg,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: _cardBorder, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'KEUANGAN',
                            style: pw.TextStyle(
                              color: _primaryColor,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          _buildDataRow(
                            'Pendapatan',
                            finance.totalRevenue > 0
                                ? formatCompactRupiah(finance.totalRevenue)
                                : 'Rp0',
                          ),
                          _buildDataRow(
                            'Pengeluaran',
                            finance.totalExpense > 0
                                ? formatCompactRupiah(finance.totalExpense)
                                : 'Rp0',
                          ),
                          pw.Divider(color: _dividerColor, height: 8),
                          _buildDataRow(
                            'LABA BERSIH',
                            finance.hasTransactions
                                ? formatCompactRupiah(finance.netProfit)
                                : 'Rp0',
                            isBold: true,
                            valueColor: finance.netProfit >= 0 ? _successGreen : _warningAmber,
                          ),
                          pw.SizedBox(height: 8),

                          // Visual Breakdown Bar (Pakan, DOC, OVK, Operasional)
                          _buildCostBar(
                            label: 'Pakan',
                            pct: finance.feedExpensePct,
                            barColor: _primaryColor,
                          ),
                          _buildCostBar(
                            label: 'DOC',
                            pct: finance.docExpensePct,
                            barColor: const PdfColor.fromInt(0xFF3B82F6),
                          ),
                          _buildCostBar(
                            label: 'OVK',
                            pct: finance.ovkExpensePct,
                            barColor: const PdfColor.fromInt(0xFF10B981),
                          ),
                          _buildCostBar(
                            label: 'Oper.',
                            pct: finance.operationalExpensePct,
                            barColor: const PdfColor.fromInt(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── 6. TREN 3 PERIODE ──────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: _cardBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: _cardBorder, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TREN 3 PERIODE',
                          style: pw.TextStyle(
                            color: _primaryColor,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          _clean(comparison.threePeriodSequence),
                          style: pw.TextStyle(
                            color: _textPrimary,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFEBF0FF),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        _clean(comparison.threePeriodTrendSummary),
                        style: pw.TextStyle(
                          color: _primaryColor,
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Spacer(),

              // ── 7. FOOTER ──────────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: _cardBorder, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'DETAIL PANEN & BIAYA',
                      style: const pw.TextStyle(
                        color: _textSecondary,
                        fontSize: 8.5,
                      ),
                    ),
                    pw.Text(
                      'Dicetak pada ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} | Chickin BroilerKu',
                      style: const pw.TextStyle(
                        color: _textSecondary,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  static pw.Widget _buildKpiColumn({
    required String value,
    required String label,
    required String delta,
    required PdfColor deltaColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: _textSecondary,
            fontSize: 8.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          delta,
          style: pw.TextStyle(
            color: deltaColor,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMiniKpi({
    required String title,
    required String subtitle,
    required PdfColor deltaColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            color: _textPrimary,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          subtitle,
          style: pw.TextStyle(
            color: deltaColor,
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildVerticalDivider() {
    return pw.Container(
      width: 0.8,
      height: 32,
      color: _dividerColor,
    );
  }

  static pw.Widget _buildDataRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: isBold ? _textPrimary : _textSecondary,
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: valueColor ?? _textPrimary,
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCostBar({
    required String label,
    required double pct,
    required PdfColor barColor,
  }) {
    final clampedPct = pct.clamp(0.0, 100.0);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 32,
            child: pw.Text(
              label,
              style: const pw.TextStyle(color: _textSecondary, fontSize: 8),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              height: 7,
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE2E8F0),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: (clampedPct / 100.0) * 120.0,
                    height: 7,
                    decoration: pw.BoxDecoration(
                      color: barColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.SizedBox(
            width: 28,
            child: pw.Text(
              '${clampedPct.toStringAsFixed(1).replaceAll('.', ',')}%',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                color: _textPrimary,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
