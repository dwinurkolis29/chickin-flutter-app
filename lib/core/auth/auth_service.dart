import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';

/// Result model untuk semua auth operations.
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  factory AuthResult.success(User user) =>
      AuthResult(success: true, user: user);

  factory AuthResult.failure(String errorMessage) =>
      AuthResult(success: false, errorMessage: errorMessage);
}

/// Satu pintu semua urusan autentikasi.
/// Didaftarkan sebagai [ChangeNotifierProvider] di root app — single instance.
///
/// Yang boleh ada di sini:
///   - Login / logout / register
///   - State & info user (currentUser, uid, isLoggedIn)
///   - Stream auth state (untuk trigger ProxyProvider)
///   - Error mapping Firebase Auth
///
/// Yang TIDAK boleh ada di sini:
///   - Logic bisnis fitur (period, recording, dll.)
///   - UI / navigation
///   - Data fetching selain yang terkait auth
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService;

  AuthService({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService();

  // ── State & Info User ──────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream UID — sumber tunggal yang drives [StreamProvider<String?>]
  /// di [main_app.dart]. ProxyProvider semua controller bergantung pada ini.
  Stream<String?> get uidStream =>
      _auth.authStateChanges().map((u) => u?.uid);

  // ── Aksi Utama ─────────────────────────────────────────────────────────────

  /// Login email/password.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('Terjadi kesalahan yang tidak terduga: $e');
    }
  }

  /// Register akun baru + buat dokumen user di Firestore.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required UserProfile profile,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      const cage = CageData();
      await _firebaseService.createUserDocument(uid, profile, cage);
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('Terjadi kesalahan yang tidak terduga: $e');
    }
  }

  /// Logout.
  /// [AuthWrapper] reaktif via StreamBuilder — tidak perlu navigate manual
  /// setelah memanggil ini.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Error Mapping ──────────────────────────────────────────────────────────

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password yang Anda masukkan salah.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Silakan coba lagi nanti.';
      case 'invalid-credential':
        return 'Email atau password yang Anda masukkan salah.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa koneksi Anda.';
      default:
        return 'Terjadi kesalahan: ${e.message ?? 'Silakan coba lagi'}';
    }
  }
}
