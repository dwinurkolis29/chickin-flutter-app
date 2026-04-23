import 'dart:async';
import 'package:flutter/material.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/insight_generator.dart';
import 'package:recording_app/features/reporting/domain/usecases/summary_calculator.dart';

class PeriodController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final SummaryCalculator _summaryCalculator;
  final InsightGenerator _insightGenerator;
  StreamSubscription<List<PeriodData>>? _periodSubscription;

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
      clear();
    } else {
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

  /// Subscribe ulang dengan UID baru. Delegate ke onAuthChanged.
  void reload([String? uid]) => onAuthChanged(uid);

  @override
  void dispose() {
    _periodSubscription?.cancel();
    super.dispose();
  }

  // ============================================================================
  // BUSINESS LOGIC
  // ============================================================================

  /// Create Period: Defaults to draft (isActive = false, no endDate).
  Future<void> createPeriod(PeriodData period) async {
    final hasActive = _periods.any((p) => p.isActive);
    if (hasActive) {
      throw Exception('Cannot create: There is already an active period.');
    }

    final newPeriod = period.copyWith(isActive: false, createdAt: DateTime.now());
    await _firebaseService.createPeriod(newPeriod);
  }

  /// Activate Period: Works for both draft (no endDate) and closed (has endDate) periods.
  /// Clears endDate on reactivation so period appears as running again.
  Future<void> activatePeriod(String periodId) async {
    final period = _periods.firstWhere(
          (p) => p.id == periodId,
      orElse: () => throw Exception('Period not found'),
    );

    if (period.isActive) {
      throw Exception('Cannot activate: Period is already active.');
    }

    final hasActive = _periods.any((p) => p.isActive);
    if (hasActive) {
      throw Exception('Cannot activate: Another period is already active.');
    }

    // Clear endDate so it no longer appears as closed
    final updatedPeriod = period.copyWith(
      isActive: true,
      startDate: DateTime.now(),
      endDate: null, // works correctly with the sentinel-based copyWith
    );
    await _firebaseService.updatePeriod(periodId, updatedPeriod);
  }

  /// Close Period: ambil recordings, kalkulasi summary + weeklyFCR + insights, simpan ke Firebase.
  Future<void> closePeriod(String periodId) async {
    final period = _periods.firstWhere(
          (p) => p.id == periodId,
      orElse: () => throw Exception('Period not found'),
    );

    if (!period.isActive) {
      throw Exception('Cannot close: Period is not active.');
    }

    // Fetch recordings sekali untuk kalkulasi snapshot
    final recordings = await _firebaseService.getRecordingsOnce(periodId);

    // Kalkulasi snapshot
    final closingPeriod = period.copyWith(endDate: DateTime.now());
    final snapshot = _summaryCalculator.execute(closingPeriod, recordings);
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
      orElse: () => throw Exception('Period not found'),
    );

    final isDraft = !period.isActive && period.endDate == null;

    if (!isDraft) {
      final recordingsStream = _firebaseService.getRecordingsStream(periodId);
      final hasRecordings = await recordingsStream.first.then((list) => list.isNotEmpty);

      if (hasRecordings) {
        throw Exception('Cannot delete period: It contains recordings.');
      }
    }

    try {
      final updatedPeriod = period.copyWith(isDeleted: true);
      await _firebaseService.updatePeriod(periodId, updatedPeriod);
    } catch (e) {
      throw Exception('Failed to delete period: $e');
    }
  }

  /// Update Period Details: Only allowed for draft periods (not active, no endDate).
  Future<void> updatePeriodDetails(String periodId, PeriodData updatedData) async {
    final period = _periods.firstWhere(
          (p) => p.id == periodId,
      orElse: () => throw Exception('Period not found'),
    );

    final isDraft = !period.isActive && period.endDate == null;
    if (!isDraft) {
      throw Exception('Cannot edit: Only draft periods can be modified.');
    }

    await _firebaseService.updatePeriod(periodId, updatedData);
  }
}