import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/features/dashboard/data/models/recording_data.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/components/snackbars/app_snackbar.dart';
import '../../../core/components/dialogs/dialog_helper.dart';
import '../../period/presentation/screens/form_period.dart';

// class yang digunakan untuk menambahkan data recording
class AddRecord extends StatefulWidget {

  AddRecord({
    Key? key,
  }) : super(key: key);

  @override
  State<AddRecord> createState() => _AddRecord();
}

class _AddRecord extends State<AddRecord> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  bool _isLoading = false;

  //membuat focus node untuk text field
  final FocusNode _focusNodeUmur = FocusNode();
  final FocusNode _focusNodeTerimaPakan = FocusNode();
  final FocusNode _focusNodeHabisPakan = FocusNode();
  final FocusNode _focusNodeMatiAyam = FocusNode();
  final FocusNode _focusNodeBeratAyam = FocusNode();
  //membuat controller untuk text field
  final TextEditingController _controllerUmur = TextEditingController();
  final TextEditingController _controllerHabisPakan = TextEditingController();
  final TextEditingController _controllerMatiAyam = TextEditingController();
  final TextEditingController _controllerBeratAyam = TextEditingController();

  //membuat instance firebase
  final db = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  //membuat instance auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadLastRecordingDay();
  }

  // Load umur terakhir dan auto-increment +1
  Future<void> _loadLastRecordingDay() async {
    try {
      final activePeriod = await _firebaseService.getActivePeriod();
      if (activePeriod != null) {
        final recordings = await _firebaseService
            .getRecordingsStream(activePeriod.id)
            .first;
        
        if (recordings.isNotEmpty) {
          // Urutkan berdasarkan day descending untuk dapat yang terbaru
          recordings.sort((a, b) => b.day.compareTo(a.day));
          final lastDay = recordings.first.day;
          
          // Set umur = last day + 1
          if (mounted) {
            _controllerUmur.text = (lastDay + 1).toString();
          }
        } else {
          // Jika belum ada recording, set umur = 1
          if (mounted) {
            _controllerUmur.text = '1';
          }
        }
      }
    } catch (e) {
      // Jika error, biarkan field kosong atau set default 1
      if (mounted) {
        _controllerUmur.text = '1';
      }
    }
  }

  //membuat method untuk menambahkan data recording
  Future<void> addRecord() async {

    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          AppSnackbar.showError(context, 'Anda harus login terlebih dahulu');
        }
        return;
      }

      // Get active period
      final activePeriod = await _firebaseService.getActivePeriod();
      
      if (activePeriod == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
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

      // Create recording with new structure
      final recording = RecordingData(
        day: int.tryParse(_controllerUmur.text) ?? 0,
        avgWeightGram: int.tryParse(_controllerBeratAyam.text) ?? 0,
        feedSack: int.tryParse(_controllerHabisPakan.text) ?? 0,
        mortality: int.tryParse(_controllerMatiAyam.text) ?? 0,
        createdAt: DateTime.now(),
      );

      // Add recording to active period
      await _firebaseService.addRecording(activePeriod.id, recording);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Gagal menyimpan data: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // mengatur warna latar belakang
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        // mengatur warna background appbar
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        // menggunakan scroll view agar form dapat di scroll
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              // Header Form Recording
              const SizedBox(height: 30),
              FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(
                  "Tamba Data Recording",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Menambakan data recording ayam broiler.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 35),
              // Umur field
              TextFormField(
                controller: _controllerUmur,
                focusNode: _focusNodeUmur,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Umur Ayam (hari)",
                  prefixIcon: const Icon(Icons.data_saver_on_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // menampilkan error jika umur kosong karena umur wajib diisi
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Umur tidak boleh kosong.";
                  }
                  return null;
                },
                onEditingComplete: () => _focusNodeTerimaPakan.requestFocus(),
              ),
              const SizedBox(height: 10),
              // Habis pakan field
              TextFormField(
                controller: _controllerHabisPakan,
                focusNode: _focusNodeHabisPakan,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Habis pakan (sak)",
                  prefixIcon: const Icon(Icons.arrow_circle_up),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // menampilkan error jika habis pakan kosong karena habis pakan wajib diisi
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Habis pakan tidak boleh kosong.";
                  }
                  return null;
                },
                onEditingComplete: () => _focusNodeMatiAyam.requestFocus(),
              ),
              const SizedBox(height: 10),
              // Mati ayam field
              TextFormField(
                controller: _controllerMatiAyam,
                focusNode: _focusNodeMatiAyam,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Mati ayam (Ekor)",
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
              // Berat ayam field
              TextFormField(
                controller: _controllerBeratAyam,
                focusNode: _focusNodeBeratAyam,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Berat Ayam (gram)",
                  prefixIcon: const Icon(Icons.scale),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // menampilkan error jika mati ayam kosong karena mati ayam wajib diisi
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Berat ayam tidak boleh kosong.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 50),
              /// Register button
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _isLoading ? null : () {
                      // memeriksa apakah form valid
                    if (_formKey.currentState?.validate() ?? false) {
                      addRecord();
                    }
                  },
                  child: _isLoading
                      // menampilkan loading jika isLoading true
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text("Tambah Data"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // membuang focus node agar tidak terjadi memory leak
    _focusNodeUmur.dispose();
    _focusNodeTerimaPakan.dispose();
    _focusNodeHabisPakan.dispose();
    _focusNodeMatiAyam.dispose();
    _focusNodeBeratAyam.dispose();

    // membuang controller agar tidak terjadi memory leak
    _controllerUmur.dispose();
    _controllerHabisPakan.dispose();
    _controllerMatiAyam.dispose();
    _controllerBeratAyam.dispose();

    super.dispose();
  }
}
