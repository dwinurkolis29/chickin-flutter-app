import 'package:flutter/material.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Screen mandiri untuk simulasi kalkulator cepat formula broiler (FCR, IP/EPEF, dan Estimasi Pakan).
/// Didesain bersih, interaktif, dan mudah digunakan oleh peternak dewasa hingga lanjut usia.
class QuickCalculatorScreen extends StatefulWidget {
  const QuickCalculatorScreen({super.key});

  @override
  State<QuickCalculatorScreen> createState() => _QuickCalculatorScreenState();
}

class _QuickCalculatorScreenState extends State<QuickCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers untuk Kalkulator FCR
  final _fcrFeedController = TextEditingController(text: '1700');
  final _fcrWeightController = TextEditingController(text: '1000');
  double _fcrResult = 1.70;

  // Controllers untuk Kalkulator IP
  final _ipLivabilityController = TextEditingController(text: '96');
  final _ipAvgWeightController = TextEditingController(text: '1.80');
  final _ipAgeController = TextEditingController(text: '35');
  final _ipFcrController = TextEditingController(text: '1.65');
  double _ipResult = 298.83;

  // Controllers untuk Estimasi Kebutuhan Pakan
  final _estDocController = TextEditingController(text: '3000');
  final _estTargetBwController = TextEditingController(text: '1.80');
  final _estTargetFcrController = TextEditingController(text: '1.65');
  double _estTotalFeedKg = 8910.0;
  int _estTotalFeedSacks = 179;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateFcr();
    _calculateIp();
    _calculateFeedEstimate();
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
    _estDocController.dispose();
    _estTargetBwController.dispose();
    _estTargetFcrController.dispose();
    super.dispose();
  }

  void _calculateFcr() {
    final feed = double.tryParse(_fcrFeedController.text.replaceAll(',', '.')) ?? 0;
    final weight = double.tryParse(_fcrWeightController.text.replaceAll(',', '.')) ?? 0;

    setState(() {
      if (feed > 0 && weight > 0) {
        _fcrResult = feed / weight;
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

  void _calculateFeedEstimate() {
    final doc = int.tryParse(_estDocController.text.trim()) ?? 0;
    final targetBw = double.tryParse(_estTargetBwController.text.replaceAll(',', '.')) ?? 0;
    final targetFcr = double.tryParse(_estTargetFcrController.text.replaceAll(',', '.')) ?? 0;

    setState(() {
      final totalBiomass = doc * targetBw;
      _estTotalFeedKg = totalBiomass * targetFcr;
      _estTotalFeedSacks = (_estTotalFeedKg / 50).ceil();
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
        top: false,
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
                      Tab(text: 'Kebutuhan Pakan'),
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
                      _buildFeedEstimateTab(context),
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
                    'INPUT DATA SIMULASI FCR',
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
                controller: _fcrFeedController,
                labelText: 'Total Pakan Dihabiskan (Kg)',
                prefixIcon: Icons.inventory_2_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateFcr(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _fcrWeightController,
                labelText: 'Total Bobot Ayam Hidup (Kg)',
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
                    'INPUT PARAMETER PANEN',
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
                labelText: 'Daya Hidup / Livability (%)',
                prefixIcon: Icons.favorite_outline_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateIp(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _ipAvgWeightController,
                labelText: 'Bobot Rata-rata Panen (Kg/ekor)',
                prefixIcon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateIp(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _ipAgeController,
                labelText: 'Umur Panen (Hari)',
                prefixIcon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateIp(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _ipFcrController,
                labelText: 'FCR Panen',
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
      ],
    );
  }

  // ── Tab 3: Feed Requirement Estimate ────────────────────────────────────────

  Widget _buildFeedEstimateTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kartu Hasil Live Estimasi Pakan
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'ESTIMASI KEBUTUHAN PAKAN',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '${_estTotalFeedKg.round()} Kg',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        'Total Kilogram',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: cs.outlineVariant,
                  ),
                  Column(
                    children: [
                      Text(
                        '$_estTotalFeedSacks Sak',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        'Sak (50 Kg)',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Estimasi total pakan yang harus disiapkan peternak hingga masa panen.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Form Input Estimasi
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
                    'TARGET POPULASI & PANEN',
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
                controller: _estDocController,
                labelText: 'Jumlah DOC / Populasi Awal (Ekor)',
                prefixIcon: Icons.pets_outlined,
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateFeedEstimate(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _estTargetBwController,
                labelText: 'Target Bobot Panen (Kg/ekor)',
                prefixIcon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateFeedEstimate(),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: _estTargetFcrController,
                labelText: 'Target FCR',
                prefixIcon: Icons.speed_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateFeedEstimate(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
