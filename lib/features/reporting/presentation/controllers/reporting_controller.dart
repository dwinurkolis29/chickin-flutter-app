import 'dart:async';
import 'package:flutter/material.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';

class ReportingController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final GeneratePeriodReport _generateReport;

  StreamSubscription<List<PeriodData>>? _periodSub;

  List<PeriodData> _closedPeriods = [];
  String? _selectedPeriodId;
  bool _isLoading = true;
  bool _isLoadingRecordings = false;
  List<RecordingData> _recordings = [];
  PeriodReport? _report;
  String? _errorMessage;

  ReportingController({
    required FirebaseService firebaseService,
    GeneratePeriodReport? generateReport,
  })  : _firebaseService = firebaseService,
        _generateReport = generateReport ?? GeneratePeriodReport() {
    _init();
  }

  // ── Getters ─────────────────────────────────────────────────────────────────
  List<PeriodData> get closedPeriods => _closedPeriods;
  String? get selectedPeriodId => _selectedPeriodId;
  bool get isLoading => _isLoading;
  bool get isLoadingRecordings => _isLoadingRecordings;
  List<RecordingData> get recordings => _recordings;
  PeriodReport? get report => _report;
  String? get errorMessage => _errorMessage;

  PeriodData? get selectedPeriod => _closedPeriods
      .where((p) => p.id == _selectedPeriodId)
      .firstOrNull;

  // ── Init ────────────────────────────────────────────────────────────────────
  void _init() {
    _isLoading = true;
    _periodSub = _firebaseService.getPeriodsStream().listen(
      (periods) {
        // Closed = not active, has endDate, not deleted
        _closedPeriods = periods
            .where((p) => !p.isActive && p.endDate != null && !p.isDeleted)
            .toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate)); // newest first

        _isLoading = false;

        // Auto-select first period on first load
        if (_selectedPeriodId == null && _closedPeriods.isNotEmpty) {
          _selectedPeriodId = _closedPeriods.first.id;
          _loadRecordings();
        } else {
          notifyListeners();
        }
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // ── Select Period ────────────────────────────────────────────────────────────
  void selectPeriod(String periodId) {
    if (_selectedPeriodId == periodId) return;
    _selectedPeriodId = periodId;
    _recordings = [];
    _report = null;
    notifyListeners();
    _loadRecordings();
  }

  // ── Load recordings & compute report ────────────────────────────────────────
  Future<void> _loadRecordings() async {
    final period = selectedPeriod;
    if (period == null) return;

    _isLoadingRecordings = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recordings = await _firebaseService
          .getRecordingsStream(period.id)
          .first;
      _report = _generateReport.execute(period, _recordings);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingRecordings = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _periodSub?.cancel();
    super.dispose();
  }
}
