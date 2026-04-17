import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/services/storage_service.dart';
import 'package:recording_app/core/utils/image_picker_helper.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class UserController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final StorageService _storageService;
  final FirebaseAuth _auth;

  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;

  UserController({
    required FirebaseService firebaseService,
    required StorageService storageService,
    required FirebaseAuth auth,
  })  : _firebaseService = firebaseService,
        _storageService = storageService,
        _auth = auth;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isUploadingAvatar => _isUploadingAvatar;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserData() async {
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

      final profile = await _firebaseService.getUserProfile();
      _userProfile = profile;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _errorMessage = 'Gagal memuat data pengguna: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleProfileImageUpload(ImageSource source) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final File? imageFile = await ImagePickerHelper.pickImage(source);
      if (imageFile == null) return; // User canceled

      final File? croppedFile = await ImagePickerHelper.cropImage(
        imageFile: imageFile, 
        aspectRatio: CropAspectRatioPreset.square
      );
      if (croppedFile == null) return; // User canceled crop

      _isUploadingAvatar = true;
      _errorMessage = null;
      notifyListeners();

      // Path prefix without timestamp
      final pathPrefix = 'users/${user.uid}/profile/avatar';

      // Upload and get URL
      final downloadUrl = await _storageService.uploadImage(croppedFile, pathPrefix);

      // Save to Firestore
      await _firebaseService.updateProfileAvatarUrl(downloadUrl);

      // Update local state
      _userProfile = _userProfile?.copyWith(avatarUrl: downloadUrl);
      _isUploadingAvatar = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      _errorMessage = 'Gagal mengunggah foto profil: $e';
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  void clear() {
    _userProfile = null;
    _isLoading = false;
    _isUploadingAvatar = false;
    _errorMessage = null;
    notifyListeners();
  }
}
