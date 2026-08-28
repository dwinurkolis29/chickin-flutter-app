import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import '../../data/models/period_data.dart';
import '../controllers/period_controller.dart';

/// Screen form untuk membuat atau mengedit periode/siklus pemeliharaan ayam.
/// Didesain bersih dan ramah untuk peternak lanjut usia.
class FormPeriod extends StatefulWidget {
  final PeriodData? period;

  const FormPeriod({super.key, this.period});

  @override
  State<FormPeriod> createState() => _FormPeriodState();
}

class _FormPeriodState extends State<FormPeriod> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _capacityController;

  late DateTime _startDate;
  bool _isLoading = false;

  bool get _isEditing => widget.period != null;
  bool get _isDraft =>
      _isEditing &&
      !(widget.period?.isActive ?? false) &&
      widget.period?.endDate == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.period?.name ?? '');
    _capacityController = TextEditingController(
      text: widget.period != null && widget.period!.initialCapacity > 0
          ? widget.period!.initialCapacity.toString()
          : '',
    );
    _startDate = widget.period?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'PILIH TANGGAL DOC MASUK',
      confirmText: 'PILIH',
      cancelText: 'BATAL',
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = context.read<PeriodController>();

      final periodData = PeriodData(
        id: widget.period?.id ?? '',
        name: _nameController.text.trim(),
        initialCapacity: int.tryParse(_capacityController.text.trim()) ?? 0,
        initialWeight: widget.period?.initialWeight ?? 0.04,
        startDate: _startDate,
        createdAt: widget.period?.createdAt ?? DateTime.now(),
        isActive: widget.period?.isActive ?? false,
        isDeleted: widget.period?.isDeleted ?? false,
      );

      if (_isEditing) {
        await controller.updatePeriodDetails(widget.period!.id, periodData);
        if (mounted) {
          AppSnackbar.showSuccess(context, 'Periode berhasil diperbarui');
          Navigator.pop(context, true);
        }
      } else {
        final hasActive = controller.periods.any((p) => p.isActive);
        await controller.createPeriod(periodData);
        if (mounted) {
          if (hasActive) {
            AppSnackbar.showSuccess(
              context,
              'Periode baru disimpan sebagai Draft (karena ada periode yang sedang aktif)',
            );
          } else {
            AppSnackbar.showSuccess(
              context,
              'Periode baru berhasil dibuat dan langsung Aktif',
            );
          }
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePeriod() async {
    if (widget.period == null) return;

    DialogHelper.showConfirm(
      context,
      'Hapus Periode Draft',
      'Apakah Anda yakin ingin menghapus periode draft "${widget.period!.name}"?',
      confirmText: 'Ya, Hapus',
      isDestructive: true,
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          await context.read<PeriodController>().deletePeriod(widget.period!.id);
          if (mounted) {
            AppSnackbar.showSuccess(context, 'Periode draft berhasil dihapus');
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (mounted) {
            AppSnackbar.showError(context, e.toString().replaceAll('Exception: ', ''));
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _activatePeriod() async {
    if (widget.period == null) return;

    final bool isReopening = widget.period!.endDate != null;

    DialogHelper.showConfirm(
      context,
      'Aktifkan Periode',
      isReopening
          ? 'Periode ini sebelumnya sudah ditutup. Apakah Anda yakin ingin mengaktifkannya kembali? Hanya satu periode yang bisa aktif dalam satu waktu.'
          : 'Aktifkan periode "${widget.period!.name}" sekarang? Data recording harian dan dashboard akan langsung terhubung ke periode ini.',
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          await context.read<PeriodController>().activatePeriod(widget.period!.id);
          if (mounted) {
            AppSnackbar.showSuccess(context, 'Periode berhasil diaktifkan');
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (mounted) {
            AppSnackbar.showError(context, e.toString().replaceAll('Exception: ', ''));
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _closePeriod() async {
    if (widget.period == null) return;

    final result = await DialogHelper.showClosePeriodHarvest(context, widget.period!);
    if (result == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await context.read<PeriodController>().closePeriod(
        widget.period!.id,
        harvestedChicks: result.harvestedChicks,
        harvestedWeightKg: result.harvestedWeightKg,
      );
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Periode berhasil ditutup & laporan dibuat');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

    final bool showActivateOption = _isEditing && !(widget.period?.isActive ?? false);
    final bool isCurrentlyActive = _isEditing && (widget.period?.isActive ?? false);

    return Scaffold(
      appBar: AppHeader(
        title: _isEditing ? 'Edit Periode' : 'Buat Periode Baru',
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!_isEditing) ...[
                    Consumer<PeriodController>(
                      builder: (context, periodCtrl, _) {
                        final hasActive = periodCtrl.periods.any((p) => p.isActive);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasActive
                                ? cs.surfaceContainer
                                : AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                            border: Border.all(
                              color: hasActive
                                  ? cs.outlineVariant
                                  : AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasActive
                                    ? Icons.info_outline_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: hasActive ? cs.primary : AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  hasActive
                                      ? 'Saat ini ada periode aktif. Periode baru ini akan otomatis disimpan sebagai DRAFT.'
                                      : 'Belum ada periode aktif. Periode baru ini akan OTOMATIS LANGSUNG AKTIF.',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── 1. Kartu Informasi Siklus DOC ──────────────────────────
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 20, color: cs.primary),
                              const SizedBox(width: 8),
                              Text(
                                'INFORMASI SIKLUS DOC',
                                style: tt.labelMedium?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Nama Periode
                          AppTextFormField(
                            controller: _nameController,
                            labelText: 'Nama Periode / Siklus',
                            prefixIcon: Icons.badge_outlined,
                            hintText: 'Misal: Periode 1 - 2026',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nama periode wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Tanggal DOC Masuk (Interactive DatePicker)
                          Text(
                            'Tanggal DOC Masuk',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _isLoading ? null : _pickStartDate,
                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainer,
                                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 20, color: cs.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      dateFmt.format(_startDate),
                                      style: tt.bodyMedium?.copyWith(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.edit_calendar_rounded, size: 18, color: cs.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Populasi Awal / Kapasitas DOC
                          AppTextFormField(
                            controller: _capacityController,
                            labelText: 'Jumlah DOC / Populasi Awal (Ekor)',
                            prefixIcon: Icons.groups_outlined,
                            hintText: 'Misal: 5000',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Jumlah DOC wajib diisi';
                              }
                              final numVal = int.tryParse(val.trim());
                              if (numVal == null || numVal <= 0) {
                                return 'Masukkan jumlah ekor yang valid (> 0)';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 2. Kartu Status & Pengelolaan Siklus ────────────────────
                  if (_isEditing)
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'STATUS SIKLUS TERNAK',
                                  style: tt.labelMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (isCurrentlyActive) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Periode Ini Sedang Aktif',
                                            style: tt.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          Text(
                                            'Pencatatan harian dan dashboard saat ini mengacu pada periode ini.',
                                            style: tt.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _closePeriod,
                                icon: Icon(Icons.check_box_outlined, color: cs.error, size: 20),
                                label: Text(
                                  'Tutup Siklus (Selesai Panen)',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                  ),
                                ),
                              ),
                            ] else if (showActivateOption) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainer,
                                  borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: cs.primary, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.period?.endDate != null
                                                ? 'Periode Selesai / Arsip Panen'
                                                : 'Periode Draft (Belum Aktif)',
                                            style: tt.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          Text(
                                            'Aktifkan periode ini jika Anda ingin mulai mencatat perkembangan harian.',
                                            style: tt.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.tonalIcon(
                                onPressed: _isLoading ? null : _activatePeriod,
                                icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                                label: const Text('Aktifkan Periode Ini Sekarang'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── 3. Tombol Submit Form ──────────────────────────────────
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                            ),
                          )
                        : Text(
                            _isEditing ? 'Simpan Perubahan' : 'Buat Periode Baru',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimary,
                            ),
                          ),
                  ),

                  // ── 4. Tombol Hapus Periode (Khusus Draft) ─────────────────
                  if (_isDraft) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _deletePeriod,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text('Hapus Periode Draft'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.6),
                        ),
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        ),
                        textStyle: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
