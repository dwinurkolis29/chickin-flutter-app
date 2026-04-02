import 'dart:async';
import 'package:flutter/material.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/build_realtime_report_usecase.dart';
import 'package:recording_app/features/reporting/domain/usecases/build_report_snapshot_usecase.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';

class ReportingController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final BuildReportSnapshotUseCase _snapshotUseCase;
  final BuildRealtimeReportUseCase _realtimeUseCase;

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
    BuildReportSnapshotUseCase? snapshotUseCase,
    BuildRealtimeReportUseCase? realtimeUseCase,
  })  : _firebaseService = firebaseService,
        _snapshotUseCase = snapshotUseCase ?? BuildReportSnapshotUseCase(),
        _realtimeUseCase = realtimeUseCase ?? BuildRealtimeReportUseCase() {
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
          ..sort((a, b) => b.startDate.compareTo(a.startDate));

        _isLoading = false;

        // Auto-select first period on first load
        if (_selectedPeriodId == null && _closedPeriods.isNotEmpty) {
          _selectedPeriodId = _closedPeriods.first.id;
          _buildReport();
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
    _buildReport();
  }

  // ── Build Report ─────────────────────────────────────────────────────────────
  /// Aturan tegas:
  /// - Period closed + punya summary valid → pakai snapshot (tidak fetch recordings)
  /// - Lainnya (summary kosong / periode aktif) → hitung realtime dari recordings
  Future<void> _buildReport() async {
    final period = selectedPeriod;
    if (period == null) return;

    _isLoadingRecordings = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bool hasValidSnapshot = period.endDate != null &&
          period.summary != null &&
          period.summary!.finalFCR > 0;

      if (hasValidSnapshot) {
        // Periode ditutup setelah refactor — pakai snapshot langsung
        _recordings = [];
        _report = _snapshotUseCase.execute(period);
      } else {
        // Periode lama (sebelum refactor) atau belum ada summary — hitung realtime
        _recordings = await _firebaseService.getRecordingsOnce(period.id);
        _report = _realtimeUseCase.execute(period, _recordings);
      }
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
