// lib/features/cage/presentation/pages/add_cage_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';

class AddCagePage extends StatefulWidget {
  const AddCagePage({super.key});

  @override
  State<AddCagePage> createState() => _AddCagePageState();
}

class _AddCagePageState extends State<AddCagePage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  bool _isLoading = false;

  // Focus nodes
  final FocusNode _focusNodeType = FocusNode();
  final FocusNode _focusNodeCapacity = FocusNode();
  final FocusNode _focusNodeLocation = FocusNode();

  // Controllers
  final TextEditingController _controllerType = TextEditingController();
  final TextEditingController _controllerCapacity = TextEditingController();
  final TextEditingController _controllerLocation = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addCage() async {
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

      final cage = CageData(
        type: _controllerType.text.trim(),
        capacity: int.tryParse(_controllerCapacity.text) ?? 0,
        location: _controllerLocation.text.trim(),
      );

      await _firebaseService.updateCage(cage);

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Data kandang berhasil disimpan');
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
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        title: const Text('Tambah Kandang'),
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
                  "Tambah Data Kandang",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Menambahkan data kandang ayam broiler.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 35),

              // Jenis Kandang field
              TextFormField(
                controller: _controllerType,
                focusNode: _focusNodeType,
                decoration: InputDecoration(
                  labelText: "Jenis Kandang",
                  prefixIcon: const Icon(Icons.bloodtype),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Jenis kandang tidak boleh kosong.";
                  }
                  return null;
                },
                onEditingComplete: () => _focusNodeCapacity.requestFocus(),
              ),
              const SizedBox(height: 10),

              // Kapasitas field
              TextFormField(
                controller: _controllerCapacity,
                focusNode: _focusNodeCapacity,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Kapasitas Kandang",
                  prefixIcon: const Icon(Icons.reduce_capacity),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Kapasitas kandang tidak boleh kosong.";
                  }
                  return null;
                },
                onEditingComplete: () => _focusNodeLocation.requestFocus(),
              ),
              const SizedBox(height: 10),

              // Lokasi field
              TextFormField(
                controller: _controllerLocation,
                focusNode: _focusNodeLocation,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Lokasi Kandang",
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Lokasi kandang tidak boleh kosong.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 50),

              // Submit button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    addCage();
                  }
                },
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text("Tambah Kandang"),
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
    _focusNodeType.dispose();
    _focusNodeCapacity.dispose();
    _focusNodeLocation.dispose();

    _controllerType.dispose();
    _controllerCapacity.dispose();
    _controllerLocation.dispose();

    super.dispose();
  }
}