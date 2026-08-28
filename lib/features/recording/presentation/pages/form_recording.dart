import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/period/presentation/screens/form_period.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/recording_validator.dart';

/// Halaman form untuk menambahkan data recording harian baru dengan fleksibilitas satuan.
class FormRecording extends StatefulWidget {
  final FirebaseService? firebaseService;

  const FormRecording({super.key, this.firebaseService});

  @override
  State<FormRecording> createState() => _FormRecordingState();
}

class _FormRecordingState extends State<FormRecording> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // Satuan yang dipilih pengguna pada UI
  String _feedUnit = 'Sak'; // 'Sak' | 'Kg'
  String _weightUnit = 'Gram'; // 'Gram' | 'Kg'

  final FocusNode _focusNodeUmur = FocusNode();
  final FocusNode _focusNodeHabisPakan = FocusNode();
  final FocusNode _focusNodeMatiAyam = FocusNode();
  final FocusNode _focusNodeBeratAyam = FocusNode();

  final TextEditingController _controllerUmur = TextEditingController();
  final TextEditingController _controllerHabisPakan = TextEditingController();
  final TextEditingController _controllerMatiAyam = TextEditingController(text: '0');
  final TextEditingController _controllerBeratAyam = TextEditingController();

  late final FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _firebaseService = widget.firebaseService ?? FirebaseService();
    _loadLastRecordingDay();
  }

  Future<void> _loadLastRecordingDay() async {
    try {
      final activePeriod = await _firebaseService.getActivePeriod();
      if (activePeriod != null) {
        final recordings =
            await _firebaseService.getRecordingsStream(activePeriod.id).first;

        if (recordings.isNotEmpty) {
          recordings.sort((a, b) => b.day.compareTo(a.day));
          final lastDay = recordings.first.day;
          if (mounted) {
            _controllerUmur.text = (lastDay + 1).toString();
          }
        } else {
          if (mounted) {
            _controllerUmur.text = '1';
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _controllerUmur.text = '1';
      }
    }
  }

  // ── Konversi Satuan ─────────────────────────────────────────────────────────

  void _onFeedUnitChanged(String newUnit) {
    if (_feedUnit == newUnit) return;
    setState(() {
      final raw = _controllerHabisPakan.text.trim().replaceAll(',', '.');
      if (raw.isNotEmpty) {
        final val = double.tryParse(raw);
        if (val != null) {
          if (newUnit == 'Kg') {
            // Sak -> Kg (1 Sak = 50 Kg)
            final kg = val * 50.0;
            _controllerHabisPakan.text =
                kg % 1 == 0 ? kg.toInt().toString() : kg.toStringAsFixed(1);
          } else {
            // Kg -> Sak (50 Kg = 1 Sak)
            final sacks = val / 50.0;
            _controllerHabisPakan.text =
                sacks % 1 == 0 ? sacks.toInt().toString() : sacks.toStringAsFixed(2);
          }
        }
      }
      _feedUnit = newUnit;
    });
  }

  void _onWeightUnitChanged(String newUnit) {
    if (_weightUnit == newUnit) return;
    setState(() {
      final raw = _controllerBeratAyam.text.trim().replaceAll(',', '.');
      if (raw.isNotEmpty) {
        final val = double.tryParse(raw);
        if (val != null) {
          if (newUnit == 'Kg') {
            // Gram -> Kg
            final kg = val / 1000.0;
            _controllerBeratAyam.text =
                kg % 1 == 0 ? kg.toInt().toString() : kg.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
          } else {
            // Kg -> Gram
            final grams = (val * 1000).round();
            _controllerBeratAyam.text = grams.toString();
          }
        }
      }
      _weightUnit = newUnit;
    });
  }

  /// Menghitung nilai habis pakan final dalam satuan SAK untuk disimpan
  int get _parsedFeedSack {
    final raw = _controllerHabisPakan.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return 0;
    final val = double.tryParse(raw) ?? 0.0;
    if (_feedUnit == 'Sak') {
      return val.round();
    } else {
      return (val / 50.0).round();
    }
  }

  /// Menghitung nilai berat ayam final dalam satuan GRAM untuk disimpan
  int get _parsedWeightGram {
    final raw = _controllerBeratAyam.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return 0;
    final val = double.tryParse(raw) ?? 0.0;
    if (_weightUnit == 'Gram') {
      return val.round();
    } else {
      return (val * 1000).round();
    }
  }

  // ── Submit Record ──────────────────────────────────────────────────────────

  Future<void> _addRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) {
        if (mounted) {
          AppSnackbar.showError(context, 'Anda harus login terlebih dahulu');
        }
        setState(() => _isLoading = false);
        return;
      }

      final activePeriod = await _firebaseService.getActivePeriod();

      if (activePeriod == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          DialogHelper.showConfirm(
            context,
            'Periode Aktif Tidak Ditemukan',
            'Tidak ada periode aktif. Buat periode terlebih dahulu sebelum menambahkan data recording.',
            confirmText: 'Buat Periode',
            onConfirm: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FormPeriod()),
              );
            },
          );
        }
        return;
      }

      final inputDay = int.tryParse(_controllerUmur.text.trim()) ?? 0;

      // Validasi duplikat hari
      final existingRecordings =
          await _firebaseService.getRecordingsOnce(activePeriod.id);
      final isDuplicate = existingRecordings.any((r) => r.day == inputDay);

      if (isDuplicate) {
        if (mounted) {
          setState(() => _isLoading = false);
          DialogHelper.showError(
            context,
            'Hari Sudah Ada',
            'Recording untuk hari ke-$inputDay sudah pernah diinput. '
            'Setiap hari hanya boleh ada satu catatan. '
            'Gunakan tombol Edit pada menu Semua Recording jika ingin mengubah data yang sudah ada.',
          );
        }
        return;
      }

      // Buat recording data dengan satuan standar (Sak & Gram)
      final recording = RecordingData(
        day: inputDay,
        avgWeightGram: _parsedWeightGram,
        feedSack: _parsedFeedSack,
        mortality: int.tryParse(_controllerMatiAyam.text.trim()) ?? 0,
        createdAt: DateTime.now(),
      );

      // ── Validasi Anomali Biologis & Typo Ekstrem ───────────────────────────
      final anomalies = RecordingValidator.checkAnomalies(
        newRecording: recording,
        initialPopulation: activePeriod.initialCapacity,
        existingRecordings: existingRecordings,
      );

      for (final anomaly in anomalies) {
        if (anomaly.isBlocking) {
          if (mounted) {
            setState(() => _isLoading = false);
            DialogHelper.showError(
              context,
              anomaly.title,
              anomaly.message,
            );
          }
          return;
        }
      }

      final nonBlocking = anomalies.where((a) => !a.isBlocking).toList();
      if (nonBlocking.isNotEmpty && mounted) {
        final messages = nonBlocking.map((a) => '• ${a.message}').join('\n\n');
        final isConfirmed = await DialogHelper.showConfirm(
          context,
          nonBlocking.length == 1
              ? nonBlocking.first.title
              : 'Peringatan Data Recording',
          '$messages\n\nApakah Anda yakin data ini sudah benar?',
          confirmText: 'Tetap Simpan',
          cancelText: 'Periksa Kembali',
          isDestructive: true,
        );

        if (isConfirmed != true) {
          setState(() => _isLoading = false);
          return;
        }
      }
      // ──────────────────────────────────────────────────────────────────────

      await _saveData(activePeriod.id, recording);
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Gagal menyimpan data: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveData(String periodId, RecordingData recording) async {
    try {
      await _firebaseService.addRecording(periodId, recording);
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          'Data recording Hari ke-${recording.day} berhasil disimpan!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Gagal menyimpan data: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppHeader(title: 'Tambah Recording'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. Hero Guidance Card ────────────────────────────────
                    _buildGuidanceCard(context),
                    const SizedBox(height: 20),

                    // ── 2. Card Umur & Mortalitas ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'WAKTU & KEMATIAN',
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    _buildUmurField(context),
                    const SizedBox(height: 14),
                    _buildMatiField(context),
                    const SizedBox(height: 20),

                    // ── 3. Card Pakan & Bobot ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'PAKAN & PENIMBANGAN',
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    _buildPakanField(context),
                    const SizedBox(height: 14),
                    _buildBeratField(context),
                    const SizedBox(height: 20),

                    // ── 4. Live Conversion Preview ──────────────────────────
                    _buildLivePreviewCard(context),
                    const SizedBox(height: 24),

                    // ── 5. Submit Button ────────────────────────────────────
                    _buildSubmitButton(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidanceCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit_note_rounded, color: cs.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pencatatan Harian Ternak',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pilih satuan Sak/Kg untuk pakan dan Gram/Kg untuk bobot. Sistem otomatis mengonversi data dengan presisi.',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUmurField(BuildContext context) {
    return AppTextFormField(
      controller: _controllerUmur,
      focusNode: _focusNodeUmur,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      labelText: 'Umur Ayam (Hari)',
      hintText: 'Contoh: 14',
      prefixIcon: Icons.calendar_month_outlined,
      onChanged: (_) => setState(() {}),
      validator: RecordingValidator.validateDay,
      onEditingComplete: () => _focusNodeMatiAyam.requestFocus(),
    );
  }

  Widget _buildMatiField(BuildContext context) {
    return AppTextFormField(
      controller: _controllerMatiAyam,
      focusNode: _focusNodeMatiAyam,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      labelText: 'Mati Ayam (Ekor)',
      hintText: '0 jika tidak ada',
      prefixIcon: Icons.heart_broken_outlined,
      onChanged: (_) => setState(() {}),
      validator: RecordingValidator.validateMortality,
      onEditingComplete: () => _focusNodeHabisPakan.requestFocus(),
    );
  }

  Widget _buildPakanField(BuildContext context) {
    final rawText = _controllerHabisPakan.text.trim().replaceAll(',', '.');
    final val = double.tryParse(rawText);
    String? helperText;

    if (val != null && val > 0) {
      if (_feedUnit == 'Sak') {
        helperText = 'Setara ≈ ${(val * 50).toInt()} Kg (1 sak = 50 kg)';
      } else {
        final sacks = (val / 50.0).toStringAsFixed(2);
        helperText = 'Setara ≈ $sacks Sak pakan';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextFormField(
          controller: _controllerHabisPakan,
          focusNode: _focusNodeHabisPakan,
          keyboardType: _feedUnit == 'Sak'
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          labelText: 'Habis Pakan ($_feedUnit)',
          hintText: _feedUnit == 'Sak' ? 'Contoh: 3' : 'Contoh: 150',
          prefixIcon: Icons.inventory_2_outlined,
          suffixIcon: _buildUnitSelector(
            currentUnit: _feedUnit,
            units: const ['Sak', 'Kg'],
            onChanged: _onFeedUnitChanged,
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => RecordingValidator.validateFeedInput(v, _feedUnit),
          onEditingComplete: () => _focusNodeBeratAyam.requestFocus(),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              helperText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBeratField(BuildContext context) {
    final rawText = _controllerBeratAyam.text.trim().replaceAll(',', '.');
    final val = double.tryParse(rawText);
    String? helperText;

    if (val != null && val > 0) {
      if (_weightUnit == 'Gram') {
        final kg = (val / 1000.0).toStringAsFixed(2);
        helperText = 'Setara ≈ $kg Kg per ekor';
      } else {
        final grams = (val * 1000).round();
        helperText = 'Setara ≈ $grams Gram per ekor';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextFormField(
          controller: _controllerBeratAyam,
          focusNode: _focusNodeBeratAyam,
          keyboardType: _weightUnit == 'Gram'
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          labelText: 'Berat Rata-rata ($_weightUnit)',
          hintText: _weightUnit == 'Gram' ? 'Contoh: 1250' : 'Contoh: 1.25',
          prefixIcon: Icons.scale_outlined,
          suffixIcon: _buildUnitSelector(
            currentUnit: _weightUnit,
            units: const ['Gram', 'Kg'],
            onChanged: _onWeightUnitChanged,
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => RecordingValidator.validateWeightInput(v, _weightUnit),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              helperText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUnitSelector({
    required String currentUnit,
    required List<String> units,
    required ValueChanged<String> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: units.map((unit) {
          final isSelected = currentUnit == unit;
          return GestureDetector(
            onTap: () => onChanged(unit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary
                    : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                unit,
                style: tt.labelSmall?.copyWith(
                  color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLivePreviewCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final day = _controllerUmur.text.trim().isEmpty ? '-' : 'Hari ke-${_controllerUmur.text.trim()}';
    final mortality = _controllerMatiAyam.text.trim().isEmpty ? '0 Ekor' : '${_controllerMatiAyam.text.trim()} Ekor';
    final feed = '$_parsedFeedSack Sak (${_parsedFeedSack * 50} kg)';
    final weight = '$_parsedWeightGram g (${(_parsedWeightGram / 1000).toStringAsFixed(2)} kg)';

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Data Siap Disimpan (Standar Database)',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPreviewItem(
                      context,
                      label: 'Umur',
                      value: day,
                      icon: Icons.calendar_month_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildPreviewItem(
                      context,
                      label: 'Pakan (Sak)',
                      value: feed,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPreviewItem(
                      context,
                      label: 'Bobot (Gram)',
                      value: weight,
                      icon: Icons.scale_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildPreviewItem(
                      context,
                      label: 'Kematian',
                      value: mortality,
                      icon: Icons.heart_broken_outlined,
                      isAlert: (int.tryParse(_controllerMatiAyam.text.trim()) ?? 0) > 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isAlert = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isAlert ? AppColors.warning : cs.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isAlert ? AppColors.warning : cs.onSurface,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        ),
        elevation: 0,
      ),
      onPressed: _isLoading ? null : _addRecord,
      child: _isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Simpan Data Recording',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _focusNodeUmur.dispose();
    _focusNodeHabisPakan.dispose();
    _focusNodeMatiAyam.dispose();
    _focusNodeBeratAyam.dispose();
    _controllerUmur.dispose();
    _controllerHabisPakan.dispose();
    _controllerMatiAyam.dispose();
    _controllerBeratAyam.dispose();
    super.dispose();
  }
}
