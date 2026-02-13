// lib/features/cage/presentation/pages/add_cage_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final FocusNode _focusNodeIdKandang = FocusNode();
  final FocusNode _focusNodeType = FocusNode();
  final FocusNode _focusNodeCapacity = FocusNode();
  final FocusNode _focusNodeAddress = FocusNode();

  // Controllers
  final TextEditingController _controllerIdKandang = TextEditingController();
  final TextEditingController _controllerType = TextEditingController();
  final TextEditingController _controllerCapacity = TextEditingController();
  final TextEditingController _controllerAddress = TextEditingController();

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anda harus login terlebih dahulu')),
          );
        }
        return;
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email pengguna tidak ditemukan')),
          );
        }
        return;
      }

      final cage = CageData(
        idKandang: int.tryParse(_controllerIdKandang.text) ?? 0,
        type: _controllerType.text.trim(),
        capacity: int.tryParse(_controllerCapacity.text) ?? 0,
        address: _controllerAddress.text.trim(),
      );

      await _firebaseService.addCage(cage, email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data kandang berhasil ditambahkan')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: ${e.toString()}')),
        );
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

              // ID Kandang field
              TextFormField(
                controller: _controllerIdKandang,
                focusNode: _focusNodeIdKandang,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Kandang ke",
                  prefixIcon: const Icon(Icons.other_houses_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "ID Kandang tidak boleh kosong.";
                  }
                  return null;
                },
                onEditingComplete: () => _focusNodeType.requestFocus(),
              ),
              const SizedBox(height: 10),

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
                onEditingComplete: () => _focusNodeAddress.requestFocus(),
              ),
              const SizedBox(height: 10),

              // Alamat field
              TextFormField(
                controller: _controllerAddress,
                focusNode: _focusNodeAddress,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Alamat Kandang",
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
                    return "Alamat kandang tidak boleh kosong.";
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
    _focusNodeIdKandang.dispose();
    _focusNodeType.dispose();
    _focusNodeCapacity.dispose();
    _focusNodeAddress.dispose();

    _controllerIdKandang.dispose();
    _controllerType.dispose();
    _controllerCapacity.dispose();
    _controllerAddress.dispose();

    super.dispose();
  }
}