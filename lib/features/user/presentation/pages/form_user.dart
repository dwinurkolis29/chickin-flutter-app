import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';

class FormUser extends StatefulWidget {
  const FormUser({super.key});

  @override
  State<FormUser> createState() => _FormUserState();
}

class _FormUserState extends State<FormUser> {
  // Deklarasi objek FirebaseService
  final FirebaseService _firebaseService = FirebaseService();
  // Deklarasi objek FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;

  // Deklarasi variabel untuk menyimpan data pengguna
  UserProfile? _userProfile;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Memuat data pengguna ketika halaman pertama kali dibuka
    _loadUserData();
  }

  // Fungsi untuk memuat data pengguna
  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Memuat data profil pengguna/peternak
        final userProfile = await _firebaseService.getUserProfile();
        if (mounted) {
          // Memperbarui state dengan data pengguna
          setState(() {
            _userProfile = userProfile;
            _nameController.text = userProfile.name ?? '';
            _phoneController.text = userProfile.phone ?? '';
            _addressController.text = userProfile.address ?? '';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          // Menampilkan pesan jika pengguna belum login
          _errorMessage = 'Pengguna tidak login';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        // Menampilkan pesan jika terjadi kesalahan saat memuat data
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = UserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      await _firebaseService.updateUserProfile(updatedProfile);

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Profil berhasil diperbarui');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Gagal memperbarui profil: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child:
            _isLoading
                // Menampilkan indikator loading jika sedang memuat
                ? const Center(child: CircularProgressIndicator())
                // Menampilkan pesan kesalahan jika ada
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_pin, size: 50),
                            const SizedBox(width: 10),
                            Text(
                              "Profil Peternak",
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Informasi Akun",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 35),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: "Nama",
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Email Field (from Firebase Auth)
                        TextFormField(
                          // set hanya bisa di baca untuk textfield
                          readOnly: true,
                          // menampilkan email dari Firebase Auth
                          initialValue:
                              _auth.currentUser?.email ?? 'Tidak ada data',
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Phone Field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nomor telepon tidak boleh kosong';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: "Nomor Telepon",
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Address Field
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Alamat tidak boleh kosong';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: "Alamat",
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _isSaving ? null : _handleUpdate,
                          child:
                              _isSaving
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    "Simpan",
                                    style: TextStyle(fontSize: 16),
                                  ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
