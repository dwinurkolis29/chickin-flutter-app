import 'dart:async';
import 'package:flutter/material.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

class PeriodController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  StreamSubscription<List<PeriodData>>? _periodSubscription;

  List<PeriodData> _periods = [];
  bool _isLoading = true;
  String? _errorMessage;

  PeriodController({required FirebaseService firebaseService})
      : _firebaseService = firebaseService {
    _init();
  }

  List<PeriodData> get periods => _periods;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _init() {
    _loadPeriods();
  }

  void _loadPeriods() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _periodSubscription = _firebaseService.getPeriodsStream().listen(
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

  /// Close Period: Sets isActive = false, endDate = now, stores summary.
  Future<void> closePeriod(String periodId, PeriodSummary summary) async {
    final period = _periods.firstWhere(
          (p) => p.id == periodId,
      orElse: () => throw Exception('Period not found'),
    );

    if (!period.isActive) {
      throw Exception('Cannot close: Period is not active.');
    }

    final updatedPeriod = period.copyWith(
      isActive: false,
      endDate: DateTime.now(), // explicitly set close timestamp
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