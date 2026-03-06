import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/features/period/presentation/screens/form_period.dart';

/// Halaman form untuk menambahkan data recording baru.
class FormRecording extends StatefulWidget {
  const FormRecording({super.key});

  @override
  State<FormRecording> createState() => _FormRecordingState();
}

class _FormRecordingState extends State<FormRecording> {
  final GlobalKey<FormState> _formKey = GlobalKey();
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
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

  Future<void> _addRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
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
      if (mounted) Navigator.pop(context, true);
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(
                  'Tambah Data Recording',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Menambahkan data recording ayam broiler.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 35),
              TextFormField(
                controller: _controllerUmur,
                focusNode: _focusNodeUmur,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Umur Ayam (hari)',
                  prefixIcon: const Icon(Icons.data_saver_on_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator:
                    (v) =>
                        (v == null || v.isEmpty)
                            ? 'Umur tidak boleh kosong.'
                            : null,
                onEditingComplete: () => _focusNodeTerimaPakan.requestFocus(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerHabisPakan,
                focusNode: _focusNodeHabisPakan,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Habis pakan (sak)',
                  prefixIcon: const Icon(Icons.arrow_circle_up),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator:
                    (v) =>
                        (v == null || v.isEmpty)
                            ? 'Habis pakan tidak boleh kosong.'
                            : null,
                onEditingComplete: () => _focusNodeMatiAyam.requestFocus(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerMatiAyam,
                focusNode: _focusNodeMatiAyam,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Mati ayam (Ekor)',
                  prefixIcon: const Icon(Icons.highlight_remove),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodeBeratAyam.requestFocus(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerBeratAyam,
                focusNode: _focusNodeBeratAyam,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Berat Ayam (gram)',
                  prefixIcon: const Icon(Icons.scale),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator:
                    (v) =>
                        (v == null || v.isEmpty)
                            ? 'Berat ayam tidak boleh kosong.'
                            : null,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _isLoading ? null : _addRecord,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('Tambah Data'),
              ),
              const SizedBox(height: 30),
            ],
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
