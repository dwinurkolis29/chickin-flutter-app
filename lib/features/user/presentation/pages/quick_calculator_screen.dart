import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Screen mandiri untuk simulasi kalkulator cepat formula broiler (FCR, IP/EPEF, dan HPP).
/// Didesain bersih, interaktif, dan mudah digunakan oleh peternak dewasa hingga lanjut usia.
class QuickCalculatorScreen extends StatefulWidget {
  final int initialIndex;

  const QuickCalculatorScreen({super.key, this.initialIndex = 0});

  @override
  State<QuickCalculatorScreen> createState() => _QuickCalculatorScreenState();
}

class _QuickCalculatorScreenState extends State<QuickCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final NumberFormat _currencyFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Controllers untuk Kalkulator FCR
  final _fcrFeedController = TextEditingController(text: '1700');
  final _fcrWeightController = TextEditingController(text: '1000');
  String _fcrUnit = 'kg'; // 'kg' or 'sak'
  double _fcrResult = 1.70;

  // Controllers untuk Kalkulator IP
  final _ipLivabilityController = TextEditingController(text: '96');
  final _ipAvgWeightController = TextEditingController(text: '1.80');
  final _ipAgeController = TextEditingController(text: '35');
  final _ipFcrController = TextEditingController(text: '1.65');
  double _ipResult = 299.22;

  // Controllers untuk Kalkulator HPP
  final _hppCostController = TextEditingController(text: '95000000');
  final _hppWeightController = TextEditingController(text: '5000');
  final _hppSellingPriceController = TextEditingController(text: '21000');
  double _hppResult = 19000.0;
  double _hppMarginResult = 2000.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 2),
    );
    _calculateFcr();
    _calculateIp();
    _calculateHpp();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fcrFeedController.dispose();
    _fcrWeightController.dispose();
    _ipLivabilityController.dispose();
    _ipAvgWeightController.dispose();
    _ipAgeController.dispose();
    _ipFcrController.dispose();
    _hppCostController.dispose();
    _hppWeightController.dispose();
    _hppSellingPriceController.dispose();
    super.dispose();
  }

  void _calculateFcr() {
    final feedInput = double.tryParse(_fcrFeedController.text.replaceAll(',', '.')) ?? 0;
    final weight = double.tryParse(_fcrWeightController.text.replaceAll(',', '.')) ?? 0;
    final feedKg = _fcrUnit == 'sak' ? feedInput * 50.0 : feedInput;

    setState(() {
      if (feedKg > 0 && weight > 0) {
        _fcrResult = feedKg / weight;
      } else {
        _fcrResult = 0.0;
      }
    });
  }

  void _calculateIp() {
    final livability = double.tryParse(_ipLivabilityController.text.replaceAll(',', '.')) ?? 0;
    final avgBw = double.tryParse(_ipAvgWeightController.text.replaceAll(',', '.')) ?? 0;
    final age = double.tryParse(_ipAgeController.text.replaceAll(',', '.')) ?? 0;
    final fcr = double.tryParse(_ipFcrController.text.replaceAll(',', '.')) ?? 0;

    setState(() {
      if (age > 0 && fcr > 0) {
        _ipResult = (livability * avgBw * 100) / (age * fcr);
      } else {
        _ipResult = 0.0;
      }
    });
  }

  void _calculateHpp() {
    final cost = double.tryParse(
          _hppCostController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;
    final weight = double.tryParse(
          _hppWeightController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;
    final sellingPrice = double.tryParse(
          _hppSellingPriceController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;

    setState(() {
      if (cost > 0 && weight > 0) {
        _hppResult = cost / weight;
      } else {
        _hppResult = 0.0;
      }

      if (_hppResult > 0 && sellingPrice > 0) {
        _hppMarginResult = sellingPrice - _hppResult;
      } else {
        _hppMarginResult = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppHeader(
        title: 'Kalkulator Cepat',
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                // ── Tab Bar Navigasi ──────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                    labelColor: cs.onPrimary,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    labelStyle: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [
                      Tab(text: 'Hitung FCR'),
                      Tab(text: 'Hitung IP'),
                      Tab(text: 'Hitung HPP'),
                    ],
                  ),
                ),

                // ── Tab Bar View Content ──────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFcrTab(context),
                      _buildIpTab(context),
                      _buildHppTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab 1: FCR Calculator ───────────────────────────────────────────────────

  Widget _buildFcrTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Color fcrColor;
    String fcrStatus;
    String fcrDesc;

    if (_fcrResult <= 0) {
      fcrColor = cs.onSurfaceVariant;
      fcrStatus = 'Masukkan Data';
      fcrDesc = 'Isi data konsumsi pakan dan total bobot untuk menghitung.';
    } else if (_fcrResult <= 1.55) {
      fcrColor = AppColors.success;
      fcrStatus = 'Sangat Efisien';
      fcrDesc = 'Konversi pakan sangat optimal, biaya pakan sangat hemat.';
    } else if (_fcrResult <= 1.80) {
      fcrColor = cs.primary;
      fcrStatus = 'Efisien (Standar Baik)';
      fcrDesc = 'Performa FCR memenuhi standar performa pemeliharaan ayam broiler.';
    } else if (_fcrResult <= 2.10) {
      fcrColor = AppColors.warning;
      fcrStatus = 'Cukup / Perhatian';
      fcrDesc = 'FCR agak tinggi, periksa kualitas pakan, kesehatan, dan suhu brooding.';
    } else {
      fcrColor = AppColors.error;
      fcrStatus = 'Boros Pakan';
      fcrDesc = 'FCR di atas normal. Evaluasi potensi pakan tercecer atau gangguan pencernaan.';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kartu Hasil Live FCR
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: fcrColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: fcrColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'NILAI FCR SIMULASI',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: fcrColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _fcrResult > 0 ? _fcrResult.toStringAsFixed(2) : '-',
                style: tt.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: fcrColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: fcrColor,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                child: Text(
                  fcrStatus,
                  style: tt.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                fcrDesc,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Form Input
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'DATA SIMULASI FCR',
                    style: tt.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pilihan Satuan Pakan: Kg vs Sak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Satuan Input Pakan:',
                    style: tt.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUnitToggleChip(
                          label: 'Kg',
                          isSelected: _fcrUnit == 'kg',
                          onTap: () {
                            if (_fcrUnit != 'kg') {
                              setState(() {
                                _fcrUnit = 'kg';
                                final currentVal = double.tryParse(_fcrFeedController.text.replaceAll(',', '.')) ?? 0;
                                if (currentVal > 0) {
                                  _fcrFeedController.text = (currentVal * 50).round().toString();
                                }
                                _calculateFcr();
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 2),
                        _buildUnitToggleChip(
                          label: 'Sak (50 Kg)',
                          isSelected: _fcrUnit == 'sak',
                          onTap: () {
                            if (_fcrUnit != 'sak') {
                              setState(() {
                                _fcrUnit = 'sak';
                                final currentVal = double.tryParse(_fcrFeedController.text.replaceAll(',', '.')) ?? 0;
                                if (currentVal > 0) {
                                  final sakVal = currentVal / 50.0;
                                  _fcrFeedController.text = sakVal % 1 == 0
                                      ? sakVal.toInt().toString()
                                      : sakVal.toStringAsFixed(1);
                                }
                                _calculateFcr();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              AppTextFormField(
                controller: _fcrFeedController,
                labelText: _fcrUnit == 'sak' ? 'Total Pakan (Sak)' : 'Total Pakan (Kg)',
                helperText: _fcrUnit == 'sak'
                    ? '1 Sak = 50 Kg pakan (otomatis dikalikan 50 saat menghitung FCR)'
                    : 'Total pakan yang dihabiskan selama masa pemeliharaan',
                helperMaxLines: 2,
                prefixIcon: Icons.inventory_2_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateFcr(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _fcrWeightController,
                labelText: 'Total Bobot Panen (Kg)',
                helperText: 'Total bobot timbangan ayam hidup hasil panen',
                helperMaxLines: 2,
                prefixIcon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateFcr(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Catatan Rumus Praktis
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rumus: FCR = Total Konsumsi Pakan (Kg) ÷ Total Bobot Ayam (Kg). Semakin kecil angka FCR, semakin hemat pakan yang digunakan.',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Tab 2: IP / EPEF Calculator ─────────────────────────────────────────────

  Widget _buildIpTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Color ipColor;
    String ipStatus;
    String ipDesc;

    if (_ipResult <= 0) {
      ipColor = cs.onSurfaceVariant;
      ipStatus = 'Masukkan Data';
      ipDesc = 'Isi data daya hidup, bobot rata-rata, umur, dan FCR.';
    } else if (_ipResult >= 400) {
      ipColor = AppColors.success;
      ipStatus = 'Istimewa (Sangat Hebat)';
      ipDesc = 'Performa pemeliharaan kelas atas industri modern.';
    } else if (_ipResult >= 350) {
      ipColor = cs.primary;
      ipStatus = 'Sangat Baik';
      ipDesc = 'Manajemen pakan, kandang, dan brooding sangat baik.';
    } else if (_ipResult >= 300) {
      ipColor = cs.primary;
      ipStatus = 'Baik / Standar';
      ipDesc = 'Performa panen memenuhi standar kelayakan peternak mandiri.';
    } else if (_ipResult >= 250) {
      ipColor = AppColors.warning;
      ipStatus = 'Cukup / Perhatian';
      ipDesc = 'Perlu evaluasi tingkat kematian (mortalitas) dan kebersihan kandang.';
    } else {
      ipColor = AppColors.error;
      ipStatus = 'Kurang / Evaluasi Total';
      ipDesc = 'Skor IP rendah. Periksa FCR, umur panen, dan penanganan penyakit.';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kartu Hasil Live IP
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ipColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: ipColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'INDEKS PERFORMA (IP / EPEF)',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: ipColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _ipResult > 0 ? _ipResult.toStringAsFixed(1) : '-',
                style: tt.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: ipColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ipColor,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                child: Text(
                  ipStatus,
                  style: tt.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                ipDesc,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Form Input IP
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'PARAMETER PANEN',
                    style: tt.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextFormField(
                controller: _ipLivabilityController,
                labelText: 'Daya Hidup (%)',
                helperText: 'Persentase ayam yang bertahan hidup hingga masa panen',
                helperMaxLines: 2,
                prefixIcon: Icons.favorite_outline_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateIp(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _ipAvgWeightController,
                labelText: 'Bobot Rata-rata (Kg/ekor)',
                helperText: 'Rata-rata bobot timbangan per ekor ayam saat panen',
                helperMaxLines: 2,
                prefixIcon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateIp(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _ipAgeController,
                labelText: 'Umur Panen (Hari)',
                helperText: 'Lama masa pemeliharaan ayam sejak DOC chick-in',
                helperMaxLines: 2,
                prefixIcon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateIp(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _ipFcrController,
                labelText: 'FCR Panen',
                helperText: 'Rasio konversi pakan akhir saat panen',
                helperMaxLines: 2,
                prefixIcon: Icons.speed_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateIp(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Catatan Rumus Praktis
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rumus: IP = (Daya Hidup % × Bobot Rata-rata kg × 100) ÷ (Umur Hari × FCR). Semakin tinggi angka IP, semakin sukses siklus pemeliharaan Anda.',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Tab 3: HPP Calculator ───────────────────────────────────────────────────

  Widget _buildHppTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Color hppColor;
    String hppStatus;
    String hppDesc;

    if (_hppResult <= 0) {
      hppColor = cs.onSurfaceVariant;
      hppStatus = 'Masukkan Data';
      hppDesc = 'Isi total biaya produksi dan total bobot panen untuk menghitung.';
    } else if (_hppResult <= 17500) {
      hppColor = AppColors.success;
      hppStatus = 'Sangat Hemat / Efisiensi Tinggi';
      hppDesc = 'Biaya pokok produksi sangat kompetitif, potensi keuntungan sangat besar.';
    } else if (_hppResult <= 20000) {
      hppColor = cs.primary;
      hppStatus = 'Normal / Kompetitif Pasar';
      hppDesc = 'HPP berada di rentang standar rata-rata peternak broiler mandiri.';
    } else if (_hppResult <= 22000) {
      hppColor = AppColors.warning;
      hppStatus = 'Cukup Tinggi / Waspada';
      hppDesc = 'HPP agak tinggi. Perhatikan efisiensi pakan, mortalitas, dan biaya OVK.';
    } else {
      hppColor = AppColors.error;
      hppStatus = 'Sangat Tinggi / Rawan Rugi';
      hppDesc = 'HPP melebihi rata-rata pasar. Segera evaluasi FCR dan manajemen pemeliharaan.';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kartu Hasil Live HPP
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: hppColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: hppColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'HARGA POKOK PRODUKSI (HPP)',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: hppColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _hppResult > 0 ? '${_currencyFmt.format(_hppResult.round())} / kg' : '-',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: hppColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: hppColor,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                child: Text(
                  hppStatus,
                  style: tt.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hppDesc,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (_hppMarginResult != 0 && _hppResult > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (_hppMarginResult >= 0 ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hppMarginResult >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 18,
                        color: _hppMarginResult >= 0 ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _hppMarginResult >= 0
                            ? 'Estimasi Margin Untung: +${_currencyFmt.format(_hppMarginResult.round())} / kg'
                            : 'Estimasi Potensi Rugi: ${_currencyFmt.format(_hppMarginResult.round())} / kg',
                        style: tt.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _hppMarginResult >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Form Input HPP
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'BIAYA & HASIL PANEN',
                    style: tt.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextFormField(
                controller: _hppCostController,
                labelText: 'Total Biaya (Rp)',
                helperText: 'Mencakup biaya DOC, pakan, OVK, listrik, sekam, dan tenaga kerja',
                helperMaxLines: 3,
                prefixIcon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateHpp(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _hppWeightController,
                labelText: 'Total Bobot Panen (Kg)',
                helperText: 'Total kilogram seluruh ayam hidup yang ditimbang dan terjual',
                helperMaxLines: 2,
                prefixIcon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateHpp(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _hppSellingPriceController,
                labelText: 'Harga Jual Pasar (Rp/kg)',
                helperText: 'Opsional: untuk menghitung perkiraan selisih keuntungan terhadap modal',
                helperMaxLines: 3,
                prefixIcon: Icons.monetization_on_outlined,
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateHpp(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Catatan Rumus Praktis
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rumus: HPP = Total Biaya Produksi (Rp) ÷ Total Bobot Panen (Kg). HPP menunjukkan titik impas (Break Even Point / BEP) modal peternak per kg ayam hidup.',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUnitToggleChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        ),
        child: Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
