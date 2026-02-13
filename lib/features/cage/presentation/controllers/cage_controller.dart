// lib/features/cage/presentation/controllers/cage_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';

class CageController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final FirebaseAuth _auth;

  CageData? _cageData;
  bool _isLoading = false;
  String? _errorMessage;

  CageController({
    required FirebaseService firebaseService,
    required FirebaseAuth auth,
  })  : _firebaseService = firebaseService,
        _auth = auth;

  CageData? get cageData => _cageData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // TAMBAHKAN METHOD INI - CEK APAKAH DATA VALID
  bool get hasValidCageData {
    if (_cageData == null) return false;
    // Cek apakah data benar-benar ada (bukan default value)
    return _cageData!.idKandang > 0 &&
        _cageData!.type.isNotEmpty &&
        _cageData!.capacity > 0;
  }

  Future<void> loadCageData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;

      if (user == null) {
        _errorMessage = 'Anda belum login';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        _errorMessage = 'Email pengguna tidak ditemukan';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final cageData = await _firebaseService.getCage(email);

      _cageData = cageData;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cage data: $e');
      _errorMessage = 'Gagal memuat data kandang. Silakan coba lagi.';
      _isLoading = false;
      notifyListeners();
    }
  }
}