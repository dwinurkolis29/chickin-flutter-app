import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';

class Cage extends StatefulWidget {
  const Cage({super.key});

  @override
  State<Cage> createState() => _CageState();
}

class _CageState extends State<Cage> {
  //Membuat objek FirebaseService
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //Deklarasi variabel untuk menyimpan data kandang
  CageData? _cageData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    //Memanggil fungsi untuk memuat data kandang ketika halaman pertama kali dibuka
    _loadCageData();
  }

  //Fungsi untuk memuat data kandang
  Future<void> _loadCageData() async {
    try {
      final user = _auth.currentUser;
      //memeriksa apakah pengguna sudah login
      if (user != null) {
        final cageData = await _firebaseService.getCage(user.email!);
        //Memperbarui state dengan data kandang
        if (mounted) {
          setState(() {
            _cageData = cageData;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Pengguna tidak login';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          //Menampilkan indikator loading jika sedang memuat
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          //Menampilkan pesan kesalahan jika ada
          ? Center(child: Text(_errorMessage))
          : _cageData == null
          //Menampilkan pesan jika tidak ada data
          ? const Center(child: Text('Tidak ada data'))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        //Membuat form untuk menampilkan data kandang
        child: Form(
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Header kandang
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.house_siding, size: 50),
                  const SizedBox(width: 10),
                  Text(
                    "Profil Kandang",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Informasi Kandang Peternak",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 35),
              //field untuk menampilkan id kandang
              TextFormField(
                //menggunakan form hanya untuk membaca
                readOnly: true,
                initialValue: _cageData?.idKandang.toString() ?? 'Tidak ada data',
                decoration: InputDecoration(
                  labelText: "Kandang ke",
                  prefixIcon: const Icon(Icons.other_houses_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              //field untuk menampilkan jenis kandang
              TextFormField(
                //menggunakan form hanya untuk membaca
                readOnly: true,
                initialValue: _cageData?.type ?? 'Tidak ada data',
                decoration: InputDecoration(
                  labelText: "Jenis Kandang",
                  prefixIcon: const Icon(Icons.bloodtype),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              //field untuk menampilkan kapasitas kandang
              TextFormField(
                //menggunakan form hanya untuk membaca
                readOnly: true,
                initialValue: _cageData?.capacity.toString() ?? 'Tidak ada data',
                decoration: InputDecoration(
                  labelText: "Kapasitas Kandang",
                  prefixIcon: const Icon(Icons.reduce_capacity),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              //field untuk menampilkan alamat kandang
              TextFormField(
                //menggunakan form hanya untuk membaca
                readOnly: true,
                initialValue: _cageData?.address ?? 'Tidak ada data',
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Alamat Kandang",
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