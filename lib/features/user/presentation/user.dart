import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';

class User extends StatefulWidget {
  const User({super.key});

  @override
  State<User> createState() => _UserState();
}

class _UserState extends State<User> {
  // Deklarasi objek FirebaseService
  final FirebaseService _firebaseService = FirebaseService();
  // Deklarasi objek FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Deklarasi variabel untuk menyimpan data pengguna
  UserProfile? _userProfile;
  bool _isLoading = true;
  String _errorMessage = '';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
      // Menampilkan indikator loading jika sedang memuat
          ? const Center(child: CircularProgressIndicator())
      // Menampilkan pesan kesalahan jika ada
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Form(
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
                // set hanya bisa di baca untuk textfield
                readOnly: true,
                // menampilkan data name atau "tidak ada data"
                initialValue: _userProfile?.name ?? 'Tidak ada data',
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
                initialValue: _auth.currentUser?.email ?? 'Tidak ada data',
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
                // set hanya bisa di baca untuk textfield
                readOnly: true,
                // menampilkan data phone atau "tidak ada data"
                initialValue: _userProfile?.phone ?? 'Tidak ada data',
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
                // set hanya bisa di baca untuk textfield
                readOnly: true,
                // menampilkan data address atau "tidak ada data"
                initialValue: _userProfile?.address ?? 'Tidak ada data',
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Alamat",
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}