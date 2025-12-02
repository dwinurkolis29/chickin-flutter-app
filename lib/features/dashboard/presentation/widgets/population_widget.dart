import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';

class PopulationSection extends StatefulWidget {
  int populationRemain;

  PopulationSection({Key? key, required this.populationRemain})
    : super(key: key);

  @override
  State<PopulationSection> createState() => _PopulationSectionState();
}

class _PopulationSectionState extends State<PopulationSection> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CageData? _cageData;
  bool _isLoading = true;
  String _errorMessage = '';


  @override
  void initState() {
    super.initState();
    // Memuat data kandang ketika halaman pertama kali dibuka
    _loadCageData();
  }

  // Memuat data kandang dari Firebase
  Future<void> _loadCageData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Memuat data kandang
        final cageData = await _firebaseService.getCage(user.email!);
        if (mounted) {
          setState(() {
            // Memperbarui state dengan data kandang
            _cageData = cageData;
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
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    // Menghitung persentase ayam yang masih hidup dari jumlah populasi
    double progress = _cageData == null || _cageData!.capacity == 0 ? 0 : widget.populationRemain / (_cageData?.capacity ?? 1);
    String percentage = (progress * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Populasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  // menampilkan jumlah ayam yang masih hidup
                  widget.populationRemain.toString(),
                  style: const TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A61B4),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Text(
                    'Ekor ayam',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A61B4),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF5A61B4),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          // menampilkan persentase ayam yang masih hidup
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'dari 100%',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
          ],
        ),
      ],
    );
  }
}
