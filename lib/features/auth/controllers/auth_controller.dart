import 'package:firebase_auth/firebase_auth.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';

/// Result model for auth operations
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  factory AuthResult.success(User user) {
    return AuthResult(success: true, user: user);
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult(success: false, errorMessage: errorMessage);
  }
}

/// Controller for authentication business logic
class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// Sign up new user
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required UserProfile profile,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Create default cage data (empty for now)
      const cage = CageData();

      // Create user document in Firestore
      await _firebaseService.createUserDocument(uid, profile, cage);

      // Auto-create first period
      final firstPeriod = PeriodData(
        name: 'Periode 1',
        initialCapacity: cage.capacity > 0 ? cage.capacity : 1000,
        initialWeight: 0.4,
        startDate: DateTime.now(),
        isActive: true,
        createdAt: DateTime.now(),
      );
      await _firebaseService.createPeriod(firstPeriod, uid);

      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password terlalu lemah. Gunakan minimal 6 karakter.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid.';
          break;
        default:
          errorMessage = 'Terjadi kesalahan: ${e.message ?? 'Silakan coba lagi'}';
      }

      return AuthResult.failure(errorMessage);
    } catch (e) {
      return AuthResult.failure('Terjadi kesalahan yang tidak terduga: $e');
    }
  }

  /// Sign in existing user
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
          break;
        case 'wrong-password':
          errorMessage = 'Password yang Anda masukkan salah.';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid.';
          break;
        case 'user-disabled':
          errorMessage = 'Akun ini telah dinonaktifkan.';
          break;
        case 'too-many-requests':
          errorMessage = 'Terlalu banyak percobaan login. Silakan coba lagi nanti.';
          break;
        case 'invalid-credential':
          errorMessage = 'Email atau password yang Anda masukkan salah.';
          break;
        case 'network-request-failed':
          errorMessage = 'Tidak ada koneksi internet. Periksa koneksi Anda.';
          break;
        default:
          errorMessage = 'Terjadi kesalahan: ${e.message ?? 'Silakan coba lagi'}';
      }

      return AuthResult.failure(errorMessage);
    } catch (e) {
      return AuthResult.failure('Terjadi kesalahan yang tidak terduga: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;
}
