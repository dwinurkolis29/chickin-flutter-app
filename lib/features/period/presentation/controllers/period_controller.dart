import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/insight_generator.dart';
import 'package:recording_app/features/reporting/domain/usecases/summary_calculator.dart';

class PeriodController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final SummaryCalculator _summaryCalculator;
  final InsightGenerator _insightGenerator;
  StreamSubscription<List<PeriodData>>? _periodSubscription;
  String? _currentUid;

  List<PeriodData> _periods = [];
  bool _isLoading = false;
  String? _errorMessage;

  PeriodController({
    required FirebaseService firebaseService,
    SummaryCalculator? summaryCalculator,
    InsightGenerator? insightGenerator,
  })  : _firebaseService = firebaseService,
        _summaryCalculator = summaryCalculator ?? SummaryCalculator(),
        _insightGenerator = insightGenerator ?? InsightGenerator();

  List<PeriodData> get periods => _periods;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _loadPeriods(String uid) {
    _periodSubscription?.cancel(); // Cancel sebelum buat yang baru — hindari leak
    _periodSubscription = null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _periodSubscription = _firebaseService.getPeriodsStream(uid).listen(
            (data) {
          _periods = data.where((p) => !p.isDeleted).toList();
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          _errorMessage = error.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Dipanggil oleh ProxyProvider.update() setiap kali auth state berubah.
  void onAuthChanged(String? uid) {
    if (uid == null) {
      _currentUid = null;
      clear();
    } else {
      _currentUid = uid;
      _loadPeriods(uid);
    }
  }

  /// Bersihkan data tanpa subscribe ulang. Dipanggil saat logout.
  void clear() {
    _periodSubscription?.cancel();
    _periodSubscription = null;
    _periods = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh data menggunakan UID saat ini. Aman dipanggil dari pull-to-refresh.
  void reload([String? uid]) => onAuthChanged(uid ?? _currentUid);

  @override
  void dispose() {
    _periodSubscription?.cancel();
    super.dispose();
  }

  // ============================================================================
  // BUSINESS LOGIC
  // ============================================================================

  /// Create Period:
  /// - Jika belum ada periode aktif: otomatis langsung aktif (`isActive = true`).
  /// - Jika sudah ada periode aktif: otomatis disimpan sebagai draft (`isActive = false`).
  Future<void> createPeriod(PeriodData period) async {
    final hasActive = _periods.any((p) => p.isActive);
    final shouldBeActive = !hasActive;

    final newPeriod = period.copyWith(
      isActive: shouldBeActive,
      createdAt: DateTime.now(),
    );
    await _firebaseService.createPeriod(newPeriod);
  }

  /// Activate Period: Works for both draft (no endDate) and closed (has endDate) periods.
  /// Clears endDate on reactivation so period appears as running again.
  Future<void> activatePeriod(String periodId) async {
    final period = _periods.firstWhere(
          (p) => p.id == periodId,
      orElse: () => throw Exception('Periode tidak ditemukan'),
    );

    if (period.isActive) {
      throw Exception('Periode ini sudah dalam keadaan aktif.');
    }

    final hasActive = _periods.any((p) => p.isActive);
    if (hasActive) {
      throw Exception('Tidak dapat mengaktifkan: Ada periode lain yang sedang berjalan. Silakan tutup panen periode aktif terlebih dahulu.');
    }

    // Clear endDate so it no longer appears as closed
    final updatedPeriod = period.copyWith(
      isActive: true,
      startDate: DateTime.now(),
      endDate: null, // works correctly with the sentinel-based copyWith
    );
    await _firebaseService.updatePeriod(periodId, updatedPeriod);
  }

  /// Close Period: ambil recordings, kalkulasi summary + weeklyFCR + insights + panen riil, simpan ke Firebase.
  Future<void> closePeriod(
    String periodId, {
    int? harvestedChicks,
    double? harvestedWeightKg,
  }) async {
    final period = _periods.firstWhere(
      (p) => p.id == periodId,
      orElse: () => throw Exception('Periode tidak ditemukan'),
    );

    if (!period.isActive) {
      throw Exception('Tidak dapat menutup: Periode tidak sedang aktif.');
    }

    // Fetch recordings sekali untuk kalkulasi snapshot
    final recordings = await _firebaseService.getRecordingsOnce(periodId);

    // Kalkulasi snapshot
    final closingPeriod = period.copyWith(endDate: DateTime.now());
    final snapshot = _summaryCalculator.execute(
      closingPeriod,
      recordings,
      harvestedChicks: harvestedChicks,
      harvestedWeightKg: harvestedWeightKg,
    );
    final insights = _insightGenerator.execute(snapshot, period.initialCapacity);

    // Susun PeriodSummary dari snapshot
    final summary = PeriodSummary(
      totalFeedKg: snapshot.totalFeedKg,
      finalPopulation: snapshot.finalPopulation,
      totalMortality: snapshot.totalMortality,
      finalBiomass: snapshot.finalBiomassKg,
      finalFCR: snapshot.finalFCR,
      avgDailyGain: snapshot.avgDailyGain,
      weeklyFCR: snapshot.weeklyFCR,
      insights: insights,
      harvestedChicks: snapshot.harvestedChicks,
      harvestedWeightKg: snapshot.harvestedWeightKg,
      avgHarvestWeightKg: snapshot.avgHarvestWeightKg,
      ipScore: snapshot.ipScore,
    );

    final updatedPeriod = period.copyWith(
      isActive: false,
      endDate: DateTime.now(),
      summary: summary,
    );
    await _firebaseService.updatePeriod(periodId, updatedPeriod);
  }

  /// Delete Period: Soft delete (isDeleted = true). Only draft periods or periods
  /// without recordings can be deleted.
  Future<void> deletePeriod(String periodId) async {
    final period = _periods.firstWhere(
          (p) => p.id == periodId,
      orElse: () => throw Exception('Periode tidak ditemukan'),
    );

    final isDraft = !period.isActive && period.endDate == null;

    if (!isDraft) {
      final recordingsStream = _firebaseService.getRecordingsStream(periodId);
      final hasRecordings = await recordingsStream.first.then((list) => list.isNotEmpty);

      if (hasRecordings) {
        throw Exception('Tidak dapat menghapus periode: Periode sudah memiliki rekaman harian.');
      }
    }

    try {
      final updatedPeriod = period.copyWith(isDeleted: true);
      await _firebaseService.updatePeriod(periodId, updatedPeriod);
    } catch (e) {
      throw Exception('Gagal menghapus periode: $e');
    }
  }

  /// Update Period Details: Diizinkan untuk periode draft atau periode aktif (sebelum ditutup panen).
  /// Periode yang sudah selesai panen (endDate != null) terkunci demi integritas laporan.
  Future<void> updatePeriodDetails(String periodId, PeriodData updatedData) async {
    final period = _periods.firstWhere(
          (p) => p.id == periodId,
          orElse: () => throw Exception('Periode tidak ditemukan'),
    );

    final isClosed = !period.isActive && period.endDate != null;
    if (isClosed) {
      throw Exception('Tidak dapat mengubah data: Periode ini sudah selesai panen.');
    }

    final newPeriodData = updatedData.copyWith(
      isActive: period.isActive,
    );

    await _firebaseService.updatePeriod(periodId, newPeriodData);
  }
}