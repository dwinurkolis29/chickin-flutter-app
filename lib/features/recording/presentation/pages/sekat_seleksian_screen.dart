import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/period/data/models/hospital_pen_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_separated_flock.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';

/// Screen untuk manajemen Sekat Seleksian / Sub-populasi Sakit (Hospital Pen).
///
/// Ayam di sekat seleksian tetap dihitung sebagai ayam hidup (Live Chicks),
/// tidak menambah mortalitas/deplesi dan tidak mengurangi pembagi pakan.
class SekatSeleksianScreen extends StatefulWidget {
  const SekatSeleksianScreen({super.key});

  @override
  State<SekatSeleksianScreen> createState() => _SekatSeleksianScreenState();
}

class _SekatSeleksianScreenState extends State<SekatSeleksianScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dayController = TextEditingController();
  final _countController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  /// false = Gram (g), true = Kilogram (kg)
  bool _isKgUnit = false;

  final Set<String> _selectedConditions = <String>{};

  bool _isInitialized = false;
  bool _isSaving = false;

  static const List<String> _availableConditions = [
    'Kerdil',
    'Pincang / Kaki Lemah',
    'Sakit / Lesu',
    'Kalah Bersaing',
    'Lainnya',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final controller = context.read<RecordingController>();
      final existing = controller.hospitalPen;

      if (existing != null && existing.isNotEmpty) {
        _dayController.text = existing.day.toString();
        _countController.text = existing.count.toString();
        _weightController.text = existing.avgWeightGram.toString();
        _isKgUnit = false;
        _selectedConditions.addAll(existing.conditions);
        _notesController.text = existing.notes;
      } else {
        // Default ke hari ke-1 atau hari terakhir dari activePeriod
        _dayController.text = '1';
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _dayController.dispose();
    _countController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _parsedDay => int.tryParse(_dayController.text.trim()) ?? 1;

  int get _parsedCount => int.tryParse(_countController.text.trim()) ?? 0;

  int get _parsedWeightInGram {
    final rawText = _weightController.text.trim().replaceAll(',', '.');
    final val = double.tryParse(rawText) ?? 0.0;
    if (_isKgUnit) {
      return (val * 1000).round();
    }
    return val.round();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<RecordingController>();
    final count = _parsedCount;
    final weightInGram = _parsedWeightInGram;
    final day = _parsedDay;
    final notes = _notesController.text.trim();

    final data = HospitalPenData(
      count: count,
      avgWeightGram: weightInGram,
      day: day,
      conditions: _selectedConditions.toList(),
      notes: notes,
      updatedAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    try {
      await controller.saveHospitalPen(data);
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          'Data sekat seleksian berhasil diperbarui',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Gagal menyimpan data sekat: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleReset() async {
    final confirmed = await DialogHelper.showConfirm(
      context,
      'Kosongkan Sekat Seleksian?',
      'Semua ayam di sekat seleksian akan dikembalikan/dihapus dari catatan sekat aktif. Tindakan ini tidak mengubah data rekaman mortalitas.',
      confirmText: 'Kosongkan',
      cancelText: 'Batal',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.error,
      iconBackgroundColor: AppColors.error.withValues(alpha: 0.12),
    );

    if (confirmed != true || !mounted) return;

    final controller = context.read<RecordingController>();
    setState(() => _isSaving = true);
    try {
      await controller.saveHospitalPen(null);
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          'Sekat seleksian berhasil dikosongkan',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Gagal mengosongkan sekat: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecordingController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final numFmt = NumberFormat.decimalPattern('id_ID');

    final activePeriod = controller.activePeriod;
    final initialCap = controller.initialPopulation > 0
        ? controller.initialPopulation
        : 1000;

    return Scaffold(
      appBar: const AppHeader(title: 'Sekat Seleksian'),
      body: StreamBuilder<List<RecordingData>>(
        stream: controller.recordingsStream,
        builder: (context, snapshot) {
          final recordings = snapshot.data ?? const <RecordingData>[];

          // Hitung estimasi populasi hidup dan bobot reguler
          int totalMortality = 0;
          int regularAvgWeightGram = 0;

          for (final rec in recordings) {
            totalMortality += rec.mortality;
            if (rec.day == _parsedDay && rec.avgWeightGram > 0) {
              regularAvgWeightGram = rec.avgWeightGram;
            }
          }

          // Total ayam dipanen jika ada
          final totalHarvested =
              activePeriod?.summary?.harvestedChicks ?? 0;
          final currentLivePopulation = (initialCap - totalMortality - totalHarvested).clamp(0, initialCap);

          // Jika tidak ada bobot reguler pas di hari sekat, ambil bobot terbaru
          if (regularAvgWeightGram == 0 && recordings.isNotEmpty) {
            final sorted = List<RecordingData>.from(recordings)
              ..sort((a, b) => b.day.compareTo(a.day));
            for (final r in sorted) {
              if (r.avgWeightGram > 0) {
                regularAvgWeightGram = r.avgWeightGram;
                break;
              }
            }
          }

          // Buat HospitalPenData sementara untuk live kalkulasi
          final tempHospitalPen = HospitalPenData(
            count: _parsedCount,
            avgWeightGram: _parsedWeightInGram,
            day: _parsedDay,
            conditions: _selectedConditions.toList(),
          );

          final summary = const CalculateSeparatedFlock().execute(
            totalLiveBirds: currentLivePopulation,
            regularAvgWeightGram: regularAvgWeightGram,
            hospitalPen: tempHospitalPen,
          );

          final hasExistingData =
              activePeriod?.hospitalPen != null &&
              activePeriod!.hospitalPen!.isNotEmpty;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Hero Guidance Card ─────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.health_and_safety_outlined,
                                color: cs.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sub-Populasi Ayam Sekat',
                                    style: tt.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ayam di sekat seleksian (sakit/kerdil) tetap tergolong ayam hidup (Live Chicks). Pencatatan ini memisahkan pemantauan bobot tanpa mengubah angka kematian kandang.',
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Ringkasan Populasi Kandang ────────────────────────
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Populasi Ayam Hidup Saat Ini',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${numFmt.format(currentLivePopulation)} ekor',
                                  style: tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainer,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.pillRadius,
                                ),
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                'Umur H-$_parsedDay',
                                style: tt.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Form Input Sekat Seleksian ─────────────────────────
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Form Data Sekat',
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Input Hari
                              AppTextFormField(
                                controller: _dayController,
                                labelText: 'Hari ke- (Umur Ayam)',
                                hintText: 'Contoh: 28',
                                prefixIcon: Icons.calendar_today_rounded,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => setState(() {}),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Hari umur ayam wajib diisi';
                                  }
                                  final d = int.tryParse(value);
                                  if (d == null || d <= 0) {
                                    return 'Hari harus lebih besar dari 0';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Input Jumlah Ekor
                              AppTextFormField(
                                controller: _countController,
                                labelText: 'Jumlah Ayam di Sekat',
                                hintText: 'Contoh: 150',
                                suffixText: 'ekor',
                                prefixIcon: Icons.fence_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => setState(() {}),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Jumlah ekor wajib diisi';
                                  }
                                  final cnt = int.tryParse(value);
                                  if (cnt == null || cnt < 0) {
                                    return 'Jumlah tidak boleh negatif';
                                  }
                                  if (cnt > currentLivePopulation) {
                                    return 'Melebihi populasi hidup (${numFmt.format(currentLivePopulation)} ekor)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Input Bobot Rata-rata Sekat + Toggle Satuan
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AppTextFormField(
                                      controller: _weightController,
                                      labelText: 'Bobot Rata-rata Sekat',
                                      hintText: _isKgUnit ? 'Contoh: 1.2' : 'Contoh: 1206',
                                      suffixText: _isKgUnit ? 'kg' : 'g',
                                      prefixIcon: Icons.scale_rounded,
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*[.,]?\d*'),
                                        ),
                                      ],
                                      onChanged: (_) => setState(() {}),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Bobot sekat wajib diisi';
                                        }
                                        final norm = value.replaceAll(',', '.');
                                        final w = double.tryParse(norm);
                                        if (w == null || w <= 0) {
                                          return 'Bobot harus lebih dari 0';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Toggle Gram / Kg
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainer,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.pillRadius,
                                      ),
                                      border: Border.all(
                                        color: cs.outlineVariant.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _UnitToggleButton(
                                          label: 'Gram',
                                          isSelected: !_isKgUnit,
                                          onTap: () {
                                            if (_isKgUnit) {
                                              final val = double.tryParse(
                                                _weightController.text.trim().replaceAll(',', '.'),
                                              );
                                              if (val != null && val > 0) {
                                                _weightController.text = (val * 1000).round().toString();
                                              }
                                              setState(() => _isKgUnit = false);
                                            }
                                          },
                                        ),
                                        _UnitToggleButton(
                                          label: 'Kg',
                                          isSelected: _isKgUnit,
                                          onTap: () {
                                            if (!_isKgUnit) {
                                              final val = double.tryParse(
                                                _weightController.text.trim(),
                                              );
                                              if (val != null && val > 0) {
                                                _weightController.text = (val / 1000).toStringAsFixed(2);
                                              }
                                              setState(() => _isKgUnit = true);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Pilihan Kondisi Ayam (Chips)
                              Text(
                                'Kondisi / Alasan Pemisahan',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableConditions.map((condition) {
                                  final isSelected = _selectedConditions.contains(condition);
                                  return FilterChip(
                                    label: Text(condition),
                                    selected: isSelected,
                                    showCheckmark: isSelected,
                                    labelStyle: tt.labelSmall?.copyWith(
                                      color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                    backgroundColor: cs.surfaceContainer,
                                    selectedColor: cs.primary,
                                    checkmarkColor: cs.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                      side: BorderSide(
                                        color: isSelected
                                            ? cs.primary
                                            : cs.outlineVariant.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedConditions.add(condition);
                                        } else {
                                          _selectedConditions.remove(condition);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Catatan Tambahan
                              AppTextFormField(
                                controller: _notesController,
                                labelText: 'Catatan Khusus (Opsional)',
                                hintText: 'Contoh: Diberi suplemen vitamin khusus di tempat pakan sekat...',
                                prefixIcon: Icons.notes_rounded,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Live KPI / Analysis Card ───────────────────────────
                      if (_parsedCount > 0) ...[
                        _buildLiveAnalysisCard(
                          context: context,
                          summary: summary,
                          regularBW: regularAvgWeightGram,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── CTA Buttons ────────────────────────────────────────
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.surface,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan Status Sekat',
                          style: tt.labelLarge?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                          ),
                        ),
                      ),

                      if (hasExistingData) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _handleReset,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          label: Text(
                            'Kosongkan / Reset Sekat',
                            style: tt.labelLarge?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveAnalysisCard({
    required BuildContext context,
    required SeparatedFlockSummary summary,
    required int regularBW,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final numFmt = NumberFormat.decimalPattern('id_ID');

    final Color statusColor;
    final Color statusBg;
    switch (summary.status) {
      case SeparatedFlockStatus.normal:
        statusColor = AppColors.success;
        statusBg = AppColors.success.withValues(alpha: 0.12);
        break;
      case SeparatedFlockStatus.warning:
        statusColor = AppColors.warning;
        statusBg = AppColors.warning.withValues(alpha: 0.12);
        break;
      case SeparatedFlockStatus.danger:
        statusColor = AppColors.error;
        statusBg = AppColors.error.withValues(alpha: 0.12);
        break;
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kartu Analisis
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analisis Sub-Populasi',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      summary.statusLabel,
                      style: tt.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid 4 Metrik
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Proporsi Sekat',
                  value: '${summary.sekatPercentage.toStringAsFixed(1)}%',
                  subtext: '${summary.sekatCount} dari ${numFmt.format(summary.totalLiveBirds)} ek',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Gap Bobot',
                  value: summary.weightGapGram > 0
                      ? '-${numFmt.format(summary.weightGapGram)} g'
                      : '0 g',
                  subtext: 'vs ayam reguler',
                  valueColor: summary.weightGapGram > 0 ? AppColors.warning : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Rata-rata Riil',
                  value: '${numFmt.format(summary.weightedAvgWeightGram)} g',
                  subtext: regularBW > 0 ? 'Reguler: ${numFmt.format(regularBW)} g' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Biomassa Sekat',
                  value: '${summary.totalBiomassKg.toStringAsFixed(1)} kg',
                  subtext: '~${(summary.totalBiomassKg / 1000).toStringAsFixed(2)} ton',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rekomendasi Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.rowRadius),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.recommendation,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
    String? subtext,
    Color? valueColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.rowRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? cs.onSurface,
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(
              subtext,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnitToggleButton extends StatelessWidget {
  const _UnitToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        ),
        child: Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
