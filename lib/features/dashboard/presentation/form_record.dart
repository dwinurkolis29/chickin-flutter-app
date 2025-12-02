import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/features/dashboard/data/models/recording_data.dart';

import '../../../core/services/firebase_service.dart';

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
  final TextEditingController _controllerTerimaPakan = TextEditingController();
  final TextEditingController _controllerHabisPakan = TextEditingController();
  final TextEditingController _controllerMatiAyam = TextEditingController();
  final TextEditingController _controllerBeratAyam = TextEditingController();

  //membuat instance firebase
  final db = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  //membuat instance auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
          //menampilkan snackbar jika pengguna belum login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anda harus login terlebih dahulu')),
          );
        }
        return;
      }

      //membuat objek recording dengan data yang diambil dari text field
      final recording = RecordingData(
        umur: int.tryParse(_controllerUmur.text) ?? 0,
        terimaPakan: int.tryParse(_controllerTerimaPakan.text) ?? 0,
        habisPakan: double.tryParse(_controllerHabisPakan.text) ?? 0,
        matiAyam: int.tryParse(_controllerMatiAyam.text) ?? 0,
        beratAyam: int.tryParse(_controllerBeratAyam.text) ?? 0,
        id_periode: 1, // default periode adalah 1
      );

      await _firebaseService.addRecording(recording, user.email!);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        //menampilkan snackbar jika terjadi error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          //mengatur isLoading menjadi false jika selesai
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // mengatur warna latar belakang
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        // mengatur warna background appbar
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
                    return "Umur tidak boleh kosong. Silahkan masukkan umur ayam.";
                  }
                  return null;
                },
                onEditingComplete: () => _focusNodeTerimaPakan.requestFocus(),
              ),
              const SizedBox(height: 10),
              // Terima pakan field
              TextFormField(
                controller: _controllerTerimaPakan,
                focusNode: _focusNodeTerimaPakan,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Terima pakan (sak)",
                  prefixIcon: const Icon(Icons.arrow_circle_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodeHabisPakan.requestFocus(),
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
                    return "Habis pakan tidak boleh kosong. Silahkan masukkan jumlah pakan ayam.";
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
                    return "Berat ayam tidak boleh kosong. Silahkan masukkan berat ayam.";
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
    _controllerTerimaPakan.dispose();
    _controllerHabisPakan.dispose();
    _controllerMatiAyam.dispose();
    _controllerBeratAyam.dispose();

    super.dispose();
  }
}
