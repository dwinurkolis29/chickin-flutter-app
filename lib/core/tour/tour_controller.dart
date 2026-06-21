import 'package:flutter/foundation.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'tour_step.dart';

class TourController extends ChangeNotifier {
  final FirebaseService _firebaseService;

  TourStep _currentStep = TourStep.none;
  bool _isTourActive = false;

  TourController({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService();

  TourStep get currentStep => _currentStep;
  bool get isTourActive => _isTourActive;

  /// Mengecek apakah tour harus ditampilkan berdasarkan status di Firebase dan kondisi data.
  Future<bool> shouldShowTour() async {
    try {
      final profile = await _firebaseService.getUserProfile();
      if (profile.hasCompletedTour) return false;

      // Cek apakah sudah ada periode. Jika sudah ada banyak periode, anggap sudah paham.
      final activePeriod = await _firebaseService.getActivePeriod();
      if (activePeriod != null) {
        final recordings = await _firebaseService.getRecordingsOnce(activePeriod.id);
        if (recordings.isNotEmpty) {
          // Sudah ada data, selesaikan tour secara diam-diam
          await complete();
          return false;
        }
        // Ada periode tapi belum ada recording -> Resume di step 2
        _currentStep = TourStep.addRecording;
        _isTourActive = true;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking tour status: $e');
      return false;
    }
  }

  /// Memulai tour dari step pertama.
  void startTour() {
    _currentStep = TourStep.createPeriod;
    _isTourActive = true;
    notifyListeners();
  }

  /// Melangkah ke step berikutnya.
  void advance() {
    if (!_isTourActive) return;

    switch (_currentStep) {
      case TourStep.createPeriod:
        _currentStep = TourStep.addRecording;
        break;
      case TourStep.addRecording:
        _currentStep = TourStep.viewDashboard;
        break;
      case TourStep.viewDashboard:
        _currentStep = TourStep.completed;
        complete();
        break;
      default:
        break;
    }
    notifyListeners();
  }

  /// Melewati tour (set completed tanpa mengikuti langkah).
  Future<void> skip() async {
    _currentStep = TourStep.completed;
    _isTourActive = false;
    await complete();
    notifyListeners();
  }

  /// Menandai tour sebagai selesai di Firebase.
  Future<void> complete() async {
    try {
      await _firebaseService.updateTourStatus(true);
      _isTourActive = false;
    } catch (e) {
      debugPrint('Error completing tour: $e');
    }
    notifyListeners();
  }

  /// Set current step secara manual (untuk resume logic).
  void setStep(TourStep step) {
    _currentStep = step;
    _isTourActive = step != TourStep.none && step != TourStep.completed;
    notifyListeners();
  }

  /// Dipanggil oleh ProxyProvider.update() setiap kali auth state berubah.
  void onAuthChanged(String? uid) {
    if (uid == null) clear();
    // Login: Dashboard akan memanggil shouldShowTour() secara eksplisit.
  }

  /// Bersihkan state saat logout.
  void clear() {
    _currentStep = TourStep.none;
    _isTourActive = false;
    notifyListeners();
  }

  /// Tidak ada stream, reload = clear. Dipanggil saat ganti akun.
  void reload() => clear();
}
