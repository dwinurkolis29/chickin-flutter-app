// lib/features/cage/presentation/controllers/cage_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class CageController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final StorageService _storageService;
  final FirebaseAuth _auth;

  CageData? _cageData;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _errorMessage;

  CageController({
    required FirebaseService firebaseService,
    required StorageService storageService,
    required FirebaseAuth auth,
  })  : _firebaseService = firebaseService,
        _storageService = storageService,
        _auth = auth;

  CageData? get cageData => _cageData;
  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorMessage => _errorMessage;

  bool get hasValidCageData {
    if (_cageData == null) return false;
    return _cageData!.type.isNotEmpty && _cageData!.capacity > 0;
  }

  Future<void> loadCageData([String? uid]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cageData = await _firebaseService.getCage(uid);
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

  Future<void> saveCageData(CageData cage) async {
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

      await _firebaseService.updateCage(cage);
      _cageData = cage;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving cage data: $e');
      _errorMessage = 'Gagal menyimpan data kandang: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> handleCageImageUpload(ImageSource source) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final File? imageFile = await _storageService.pickImage(source);
      if (imageFile == null) return;

      final File? croppedFile = await _storageService.cropImage(
        imageFile: imageFile, 
        aspectRatio: null // Free crop ratio
      );
      if (croppedFile == null) return; // User canceled crop

      _isUploadingImage = true;
      _errorMessage = null;
      notifyListeners();

      final pathPrefix = 'users/${user.uid}/cage/cover';

      final downloadUrl = await _storageService.uploadImage(croppedFile, pathPrefix);
      await _firebaseService.updateCageImageUrl(downloadUrl);

      _cageData = _cageData?.copyWith(imageUrl: downloadUrl);
      _isUploadingImage = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error uploading cage image: $e');
      _errorMessage = 'Gagal mengunggah foto kandang: $e';
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// Dipanggil oleh ProxyProvider.update() setiap kali auth state berubah.
  void onAuthChanged(String? uid) {
    if (uid == null) {
      clear();
    } else {
      _cageData = null;
      _errorMessage = null;
      loadCageData(uid);
    }
  }

  /// Bersihkan data tanpa load ulang. Dipanggil saat logout.
  void clear() {
    _cageData = null;
    _isLoading = false;
    _isUploadingImage = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Load ulang dengan UID baru. Delegate ke onAuthChanged.
  void reload([String? uid]) => onAuthChanged(uid);
}