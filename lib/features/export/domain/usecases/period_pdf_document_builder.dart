import 'dart:typed_data';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/finance/data/models/finance_summary.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/domain/usecases/period_comparison_calculator.dart';

/// Builder untuk menghasilkan dokumen Laporan Resmi Periode PDF A4 (Gaya Dokumen Kertas Resmi).
/// Format dokumen formal tanpa pembungkus card mobile UI.
class PeriodPdfDocumentBuilder {
  static const PdfColor _black = PdfColors.black;
  static const PdfColor _tableBorder = PdfColor.fromInt(0xFFCBD5E1);
  static const PdfColor _tableHeaderBg = PdfColor.fromInt(0xFFF8FAFC);

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

  String _evalFcr(double fcr) {
    if (fcr <= 0) return '-';
    if (fcr <= 1.65) return 'Istimewa';
    if (fcr <= 1.75) return 'Sangat Baik';
    if (fcr <= 1.85) return 'Baik / Standar';
    return 'Perlu Evaluasi';
  }

  String _evalIp(double? ip) {
    if (ip == null || ip <= 0) return '-';
    if (ip >= 400) return 'Istimewa';
    if (ip >= 350) return 'Sangat Baik';
    if (ip >= 300) return 'Baik / Standar';
    return 'Perlu Evaluasi';
  }

  String _formatRupiah(double amount) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return fmt.format(amount.round());
  }

  Future<Uint8List> buildPdf({
    required PeriodReport report,
    required FinanceSummary finance,
    required PeriodDeltaComparison comparison,
    required CageData cage,
    String? farmerName,
  }) async {
    await initializeDateFormatting('id_ID', null);
    final pdf = pw.Document();

    final resolvedFarmerName =
        (farmerName != null && farmerName.trim().isNotEmpty)
            ? farmerName.trim()
            : 'Peternak';

    final dateFmt = DateFormat('d MMMM yyyy', 'id_ID');
    final startDateStr = dateFmt.format(report.period.startDate);
    final endDateStr =
        report.period.endDate != null
            ? dateFmt.format(report.period.endDate!)
            : 'Masih Berjalan';

    final numFmt = NumberFormat.decimalPattern('id_ID');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── 1. KOP DOKUMEN RESMI (LETTERHEAD) ──────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BroileKu',
                        style: pw.TextStyle(
                          color: _black,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'LAPORAN PERFORMA DAN REKAPITULASI HASIL PANEN',
                        style: pw.TextStyle(
                          color: _black,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Peternak: $resolvedFarmerName',
                        style: pw.TextStyle(
                          color: _black,
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'Kandang: ${cage.name.isNotEmpty ? cage.name : 'Kandang Utama'} (${cage.type.isNotEmpty ? cage.type : 'Closed House'}) | Lokasi: ${cage.location.isNotEmpty ? cage.location : '-'}',
                        style: const pw.TextStyle(
                          color: _black,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        report.period.name.toUpperCase(),
                        style: pw.TextStyle(
                          color: _black,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Durasi: ${report.durationDays} Hari',
                        style: const pw.TextStyle(
                          color: _black,
                          fontSize: 8.5,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        '$startDateStr - $endDateStr',
                        style: const pw.TextStyle(
                          color: _black,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // Double Horizontal Rule (Khas Surat / Dokumen Resmi)
              pw.Container(height: 1.5, color: _black),
              pw.SizedBox(height: 1.5),
              pw.Container(height: 0.5, color: _black),
              pw.SizedBox(height: 10),

              // ── 2. SEKSI 1: DATA PRODUKSI DAN POPULASI ─────────────────────
              _buildSectionTitle('1. DATA PRODUKSI DAN POPULASI AYAM'),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: _tableBorder, width: 0.5),
                children: [
                  pw.TableRow(
                    children: [
                      _buildTableCell('Populasi Awal DOC', isLabel: true),
                      _buildTableCell(
                        '${numFmt.format(report.initialPopulation)} ekor',
                        isBold: true,
                      ),
                      _buildTableCell('Total Bobot Daging Panen', isLabel: true),
                      _buildTableCell(
                        '${numFmt.format(report.totalBiomassKg.round())} kg',
                        isBold: true,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell('Mortalitas (Kematian)', isLabel: true),
                      _buildTableCell(
                        '${numFmt.format(report.totalMortality)} ekor (${report.mortalityRate.toStringAsFixed(1).replaceAll('.', ',')}%)',
                      ),
                      _buildTableCell('Rata-rata Bobot Panen', isLabel: true),
                      _buildTableCell(
                        '${(report.finalAvgWeightGram / 1000.0).toStringAsFixed(2).replaceAll('.', ',')} kg (${report.finalAvgWeightGram} g)',
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell('Ayam Dipanen Hidup', isLabel: true),
                      _buildTableCell(
                        '${numFmt.format(report.finalPopulation)} ekor (${report.survivalRate.toStringAsFixed(1).replaceAll('.', ',')}%)',
                      ),
                      _buildTableCell('Total Konsumsi Pakan', isLabel: true),
                      _buildTableCell(
                        '${numFmt.format(report.totalFeedKg.round())} kg (${(report.totalFeedKg / 50.0).toStringAsFixed(1).replaceAll('.', ',')} sak)',
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── 3. SEKSI 2: INDIKATOR PERFORMA TEKNIS (KPI BROILER) ────────
              _buildSectionTitle('2. INDIKATOR PERFORMA TEKNIS (KPI BROILER)'),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: _tableBorder, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.5),
                  1: pw.FlexColumnWidth(2.0),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(2.5),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _tableHeaderBg),
                    children: [
                      _buildTableHeaderCell('Parameter Evaluasi'),
                      _buildTableHeaderCell(
                        'Nilai Aktual',
                        align: pw.TextAlign.center,
                      ),
                      _buildTableHeaderCell(
                        'Standar Acuan',
                        align: pw.TextAlign.center,
                      ),
                      _buildTableHeaderCell(
                        'Predikat Mutu',
                        align: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  // Baris FCR
                  pw.TableRow(
                    children: [
                      _buildTableCell('FCR (Feed Conversion Ratio)'),
                      _buildTableCell(
                        report.fcr > 0
                            ? report.fcr.toStringAsFixed(2).replaceAll('.', ',')
                            : '-',
                        align: pw.TextAlign.center,
                        isBold: true,
                      ),
                      _buildTableCell('<= 1.70', align: pw.TextAlign.center),
                      _buildTableCell(
                        _evalFcr(report.fcr),
                        align: pw.TextAlign.center,
                        isBold: true,
                      ),
                    ],
                  ),
                  // Baris IP
                  pw.TableRow(
                    children: [
                      _buildTableCell('Indeks Performa (IP / EPEF)'),
                      _buildTableCell(
                        report.ipScore != null && report.ipScore! > 0
                            ? report.ipScore!.toStringAsFixed(0)
                            : '-',
                        align: pw.TextAlign.center,
                        isBold: true,
                      ),
                      _buildTableCell('>= 350', align: pw.TextAlign.center),
                      _buildTableCell(
                        _evalIp(report.ipScore),
                        align: pw.TextAlign.center,
                        isBold: true,
                      ),
                    ],
                  ),
                  // Baris Daya Hidup
                  pw.TableRow(
                    children: [
                      _buildTableCell('Daya Hidup (Livability)'),
                      _buildTableCell(
                        '${report.survivalRate.toStringAsFixed(1).replaceAll('.', ',')}%',
                        align: pw.TextAlign.center,
                        isBold: true,
                      ),
                      _buildTableCell('>= 95,0%', align: pw.TextAlign.center),
                      _buildTableCell(
                        report.survivalRate >= 95
                            ? 'Optimal'
                            : 'Perlu Evaluasi',
                        align: pw.TextAlign.center,
                        isBold: true,
                      ),
                    ],
                  ),
                  // Baris ADG
                  pw.TableRow(
                    children: [
                      _buildTableCell('Average Daily Gain (ADG)'),
                      _buildTableCell(
                        '${report.avgDailyGainGram.toStringAsFixed(1).replaceAll('.', ',')} g/hari',
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        '48 - 52 g/hari',
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        'Sesuai Standar',
                        align: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  // Baris Pakan per Ekor
                  pw.TableRow(
                    children: [
                      _buildTableCell('Konsumsi Pakan per Ekor'),
                      _buildTableCell(
                        '${report.feedPerBird.toStringAsFixed(2).replaceAll('.', ',')} kg',
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell('<= 3,10 kg', align: pw.TextAlign.center),
                      _buildTableCell('Efisien', align: pw.TextAlign.center),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── 4. SEKSI 3: REKAPITULASI KEUANGAN DAN HASIL USAHA ───────────
              _buildSectionTitle('3. REKAPITULASI KEUANGAN DAN HASIL USAHA'),
              pw.SizedBox(height: 4),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Tabel Kiri: Penerimaan
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(
                        color: _tableBorder,
                        width: 0.5,
                      ),
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: _tableHeaderBg,
                          ),
                          children: [
                            _buildTableHeaderCell('PENERIMAAN (HASIL PANEN)'),
                            _buildTableHeaderCell(
                              'JUMLAH (RP)',
                              align: pw.TextAlign.right,
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            _buildTableCell('Penjualan Ayam Utama'),
                            _buildTableCell(
                              _formatRupiah(finance.mainHarvestRevenue),
                              align: pw.TextAlign.right,
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            _buildTableCell('Penjualan Afkir / Reject'),
                            _buildTableCell(
                              _formatRupiah(finance.rejectRevenue),
                              align: pw.TextAlign.right,
                            ),
                          ],
                        ),
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: _tableHeaderBg,
                          ),
                          children: [
                            _buildTableCell('TOTAL PENDAPATAN', isBold: true),
                            _buildTableCell(
                              _formatRupiah(finance.totalRevenue),
                              align: pw.TextAlign.right,
                              isBold: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  // Tabel Kanan: Pengeluaran
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(
                        color: _tableBorder,
                        width: 0.5,
                      ),
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: _tableHeaderBg,
                          ),
                          children: [
                            _buildTableHeaderCell('PENGELUARAN (BIAYA)'),
                            _buildTableHeaderCell(
                              'JUMLAH (RP)',
                              align: pw.TextAlign.right,
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            _buildTableCell(
                              'Biaya Pakan (${finance.feedExpensePct.toStringAsFixed(1)}%)',
                            ),
                            _buildTableCell(
                              _formatRupiah(finance.feedExpense),
                              align: pw.TextAlign.right,
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            _buildTableCell(
                              'Biaya DOC (${finance.docExpensePct.toStringAsFixed(1)}%)',
                            ),
                            _buildTableCell(
                              _formatRupiah(finance.docExpense),
                              align: pw.TextAlign.right,
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            _buildTableCell(
                              'Biaya OVK / Medis (${finance.ovkExpensePct.toStringAsFixed(1)}%)',
                            ),
                            _buildTableCell(
                              _formatRupiah(finance.ovkExpense),
                              align: pw.TextAlign.right,
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            _buildTableCell(
                              'Operasional (${finance.operationalExpensePct.toStringAsFixed(1)}%)',
                            ),
                            _buildTableCell(
                              _formatRupiah(finance.operationalExpense),
                              align: pw.TextAlign.right,
                            ),
                          ],
                        ),
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: _tableHeaderBg,
                          ),
                          children: [
                            _buildTableCell('TOTAL PENGELUARAN', isBold: true),
                            _buildTableCell(
                              _formatRupiah(finance.totalExpense),
                              align: pw.TextAlign.right,
                              isBold: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),

              // Rangkuman Laba Bersih & HPP Bergaris Resmi
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _tableBorder, width: 0.8),
                  color: _tableHeaderBg,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ESTIMASI LABA BERSIH: ${_formatRupiah(finance.netProfit)}',
                      style: pw.TextStyle(
                        color: _black,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'HPP: ${_formatRupiah(finance.hppPerKg)} / kg bobot hidup',
                      style: pw.TextStyle(
                        color: _black,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // ── 5. SEKSI 4: CATATAN EVALUASI & REKOMENDASI SIKLUS ────────────
              _buildSectionTitle('4. CATATAN EVALUASI DAN REKOMENDASI TEKNIS'),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _tableBorder, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (comparison.periodInsights.isNotEmpty)
                      ...comparison.periodInsights
                          .take(3)
                          .map(
                            (insight) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    '- ',
                                    style: pw.TextStyle(
                                      color: _black,
                                      fontSize: 8,
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      _clean(insight),
                                      style: const pw.TextStyle(
                                        color: _black,
                                        fontSize: 8,
                                        lineSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                    else
                      pw.Text(
                        '- Siklus pemeliharaan berjalan dengan baik dan seluruh parameter target produksi tercapai.',
                        style: const pw.TextStyle(
                          color: _black,
                          fontSize: 8,
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // ── 6. SEKSI 5: PENGESAHAN DOKUMEN (TANDA TANGAN RESMI) ─────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Kolom Kiri: PPL / Pengawas
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Mengetahui / Diverifikasi:',
                        style: const pw.TextStyle(
                          color: _black,
                          fontSize: 8,
                        ),
                      ),
                      pw.Text(
                        'Pengawas Lapangan (PPL) / Kemitraan',
                        style: pw.TextStyle(
                          color: _black,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 36), // Ruang tanda tangan
                      pw.Text(
                        '( ............................................................ )',
                        style: const pw.TextStyle(
                          color: _black,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                  // Kolom Kanan: Peternak
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        '${cage.location.isNotEmpty ? cage.location : 'Tempat'}, ${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          color: _black,
                          fontSize: 8,
                        ),
                      ),
                      pw.Text(
                        'Peternak / Penanggung Jawab Kandang',
                        style: pw.TextStyle(
                          color: _black,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 36), // Ruang tanda tangan
                      pw.Text(
                        '( $resolvedFarmerName )',
                        style: pw.TextStyle(
                          color: _black,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),

              // ── 7. FOOTER FORMAL DOKUMEN ───────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: _tableBorder, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Dicetak melalui Sistem Manajemen Peternakan BroileKu pada ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        color: _black,
                        fontSize: 7.5,
                      ),
                    ),
                    pw.Text(
                      'Halaman 1 dari 1',
                      style: const pw.TextStyle(
                        color: _black,
                        fontSize: 7.5,
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

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _black,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: _black,
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isLabel = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: _black,
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
