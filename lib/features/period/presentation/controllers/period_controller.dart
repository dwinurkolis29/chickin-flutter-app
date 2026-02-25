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
          // Filter out isDeleted == true
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

  /// Create Period: Check no active period exists.
  Future<void> createPeriod(PeriodData period) async {
    final hasActive = _periods.any((p) => p.isActive);
    if (hasActive) {
      throw Exception('Cannot create: There is already an active period.');
    }
    
    // Default to inactive (draft) when created unless specified
    final newPeriod = period.copyWith(isActive: false, createdAt: DateTime.now());
    await _firebaseService.createPeriod(newPeriod);
  }

  /// Activate Period: Only from draft -> active.
  Future<void> activatePeriod(String periodId) async {
    final period = _periods.firstWhere(
      (p) => p.id == periodId,
      orElse: () => throw Exception('Period not found'),
    );

    final isDraft = !period.isActive && period.endDate == null;
    if (!isDraft) {
      throw Exception('Cannot activate: Only draft periods can be activated.');
    }

    final hasActive = _periods.any((p) => p.isActive);
    if (hasActive) {
      throw Exception('Cannot activate: Another period is already active.');
    }

    final updatedPeriod = period.copyWith(isActive: true, startDate: DateTime.now(), endDate: null);
    await _firebaseService.updatePeriod(periodId, updatedPeriod);
  }

  /// Close Period: Set status = closed (isActive = false, endDate = now).
  Future<void> closePeriod(String periodId, PeriodSummary summary) async {
    final period = _periods.firstWhere(
      (p) => p.id == periodId,
      orElse: () => throw Exception('Period not found'),
    );

    final isRunning = period.isActive;
    if (!isRunning) {
      throw Exception('Cannot close: Period is not active/running.');
    }

    final updatedPeriod = period.copyWith(
      isActive: false, 
      endDate: DateTime.now(),
      summary: summary,
    );
    await _firebaseService.updatePeriod(periodId, updatedPeriod);
  }

  /// Delete Period: Only if draft or no recordings exist. Sets isDeleted = true (Hidden).
  Future<void> deletePeriod(String periodId) async {
    final period = _periods.firstWhere(
      (p) => p.id == periodId,
      orElse: () => throw Exception('Period not found'),
    );

    // Is it a draft? (isActive = false & endDate = null)
    final isDraft = !period.isActive && period.endDate == null;

    if (!isDraft) {
      // Check if recordings exist if it's not a draft
      final recordingsStream = _firebaseService.getRecordingsStream(periodId);
      final hasRecordings = await recordingsStream.first.then((list) => list.isNotEmpty);

      if (hasRecordings) {
        throw Exception('Cannot delete period: It is not a draft and contains recordings.');
      }
    }

    // Update document with isDeleted = true instead of deleting entirely
    try {
      final updatedPeriod = period.copyWith(isDeleted: true);
      await _firebaseService.updatePeriod(periodId, updatedPeriod);
    } catch (e) {
      throw Exception('Failed to hide/delete period: $e');
    }
  }
}
