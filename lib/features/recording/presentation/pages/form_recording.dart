import 'package:recording_app/core/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/core/components/buttons/circle_icon_button.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/tour/tour_controller.dart';
import 'package:recording_app/core/tour/tour_step.dart';
import 'package:recording_app/core/tour/widgets/tour_aware_wrapper.dart';
import 'package:recording_app/core/tour/widgets/tour_overlay.dart';
import 'package:recording_app/core/tour/widgets/tour_tooltip.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/features/period/presentation/screens/form_period.dart';
import 'package:recording_app/core/services/firebase_service.dart';

/// Halaman form untuk menambahkan data recording baru.
class FormRecording extends StatefulWidget {
  const FormRecording({super.key});

  @override
  State<FormRecording> createState() => _FormRecordingState();
}

class _FormRecordingState extends State<FormRecording> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final GlobalKey _saveRecordBtnKey = GlobalKey();
  bool _isLoading = false;

  final FocusNode _focusNodeUmur = FocusNode();
  final FocusNode _focusNodeTerimaPakan = FocusNode();
  final FocusNode _focusNodeHabisPakan = FocusNode();
  final FocusNode _focusNodeMatiAyam = FocusNode();
  final FocusNode _focusNodeBeratAyam = FocusNode();

  final TextEditingController _controllerUmur = TextEditingController();
  final TextEditingController _controllerHabisPakan = TextEditingController();
  final TextEditingController _controllerMatiAyam = TextEditingController();
  final TextEditingController _controllerBeratAyam = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();


  @override
  void initState() {
    super.initState();
    _loadLastRecordingDay();
    // Logic tour lama dihapus
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

  Future<void> _addRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) {
        if (mounted)
          AppSnackbar.showError(context, 'Anda harus login terlebih dahulu');
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

      final recording = RecordingData(
        day: int.tryParse(_controllerUmur.text) ?? 0,
        avgWeightGram: int.tryParse(_controllerBeratAyam.text) ?? 0,
        feedSack: int.tryParse(_controllerHabisPakan.text) ?? 0,
        mortality: int.tryParse(_controllerMatiAyam.text) ?? 0,
        createdAt: DateTime.now(),
      );

      final weight = recording.avgWeightGram;

      if (weight > 0) {
        final expectedMaxWeight = recording.day * 80.0;
        final expectedMinWeight = _getExpectedMinWeight(recording.day);

        bool isAbnormal = false;
        String warningMessage = '';

        if (weight > expectedMaxWeight) {
          isAbnormal = true;
          warningMessage =
              'Bobot ayam ($weight gram) terdeteksi terlalu tinggi (maks wajar ~${expectedMaxWeight.toInt()} gram) untuk umur ${recording.day} hari.';
        } else if (weight < expectedMinWeight) {
          isAbnormal = true;
          warningMessage =
              'Bobot ayam ($weight gram) terdeteksi di bawah standar minimal.';
        }

        if (isAbnormal && mounted) {
          final isConfirmed = await DialogHelper.showConfirm(
            context,
            'Bobot Abnormal',
            '$warningMessage\n\nApakah Anda yakin data ini sudah benar?',
            confirmText: 'Lanjutkan',
            cancelText: 'Periksa Kembali',
            isDestructive: true,
          );

          if (isConfirmed != true) {
            setState(() => _isLoading = false);
            return;
          }
        }
      }

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
        // Advance tour jika sedang aktif di step addRecording
        final tourController = context.read<TourController>();
        if (tourController.isTourActive &&
            tourController.currentStep == TourStep.addRecording) {
          tourController.advance();
        }

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

  double _getStandardWeight(int day) {
    if (day <= 0) return 40.0;
    return 42.0 + (day * 12.0) + (day * day * 1.1);
  }

  double _getExpectedMinWeight(int day) => _getStandardWeight(day) * 0.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const AppHeader(title: 'Data Recording'),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    const SizedBox(height: 35),
                    _buildUmurField(context),
                    const SizedBox(height: 10),
                    _buildPakanField(context),
                    const SizedBox(height: 10),
                    _buildMatiField(context),
                    const SizedBox(height: 10),
                    _buildBeratField(context),
                    const SizedBox(height: 50),
                    _buildSubmitButton(context),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          _buildTourOverlay(context),
        ],
      ),
    );
  }

  Widget _buildTourOverlay(BuildContext context) {
    final tourController = context.watch<TourController>();
    if (!tourController.isTourActive ||
        tourController.currentStep != TourStep.addRecording) {
      return const SizedBox.shrink();
    }

    final rect = TourAwareWrapper.getRect(_saveRecordBtnKey);
    if (rect == null) return const SizedBox.shrink();

    return TourOverlay(
      targetKey: _saveRecordBtnKey,
      tooltip: TourTooltip(
        title: 'Langkah 2: Tambah Recording',
        description:
            'Setelah mengisi data harian ayam, klik tombol ini untuk menyimpan. Data ini akan digunakan untuk menghitung FCR dan statistik lainnya.',
        stepText: '2 / 3',
        showSkip: true,
        onSkip: () => tourController.skip(),
      ),
      onSkip: () {},
    );
  }

  Widget _buildUmurField(BuildContext context) {
    return AppTextFormField(
      controller: _controllerUmur,
      focusNode: _focusNodeUmur,
      keyboardType: TextInputType.number,
      labelText: 'Umur Ayam (hari)',
      prefixIcon: Icons.data_saver_on_rounded,
      validator:
          (v) => (v == null || v.isEmpty) ? 'Umur tidak boleh kosong.' : null,
      onEditingComplete: () => _focusNodeTerimaPakan.requestFocus(),
    );
  }

  Widget _buildPakanField(BuildContext context) {
    return AppTextFormField(
      controller: _controllerHabisPakan,
      focusNode: _focusNodeHabisPakan,
      keyboardType: TextInputType.number,
      labelText: 'Habis pakan (sak)',
      prefixIcon: Icons.arrow_circle_up,
      validator:
          (v) =>
              (v == null || v.isEmpty)
                  ? 'Habis pakan tidak boleh kosong.'
                  : null,
      onEditingComplete: () => _focusNodeMatiAyam.requestFocus(),
    );
  }

  Widget _buildMatiField(BuildContext context) {
    return AppTextFormField(
      controller: _controllerMatiAyam,
      focusNode: _focusNodeMatiAyam,
      keyboardType: TextInputType.number,
      labelText: 'Mati ayam (Ekor)',
      prefixIcon: Icons.highlight_remove,
      onEditingComplete: () => _focusNodeBeratAyam.requestFocus(),
    );
  }

  Widget _buildBeratField(BuildContext context) {
    return AppTextFormField(
      controller: _controllerBeratAyam,
      focusNode: _focusNodeBeratAyam,
      keyboardType: TextInputType.number,
      labelText: 'Berat Ayam (gram)',
      prefixIcon: Icons.scale,
      validator:
          (v) =>
              (v == null || v.isEmpty)
                  ? 'Berat ayam tidak boleh kosong.'
                  : null,
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TourAwareWrapper(
      tourKey: _saveRecordBtnKey,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _isLoading ? null : _addRecord,
        child:
            _isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.onPrimary,
                    ),
                  ),
                )
                : Text(
                  'Tambah Data',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNodeUmur.dispose();
    _focusNodeTerimaPakan.dispose();
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
