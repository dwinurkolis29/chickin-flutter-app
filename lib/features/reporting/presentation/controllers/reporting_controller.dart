import 'dart:async';
import 'package:flutter/material.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/export/domain/usecases/export_period_csv.dart';
import 'package:recording_app/features/export/domain/usecases/export_period_excel.dart';
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
  bool _isExporting = false;
  bool _isLoadingRecordingDetail = false;
  List<RecordingData> _recordings = [];
  PeriodReport? _report;
  String? _errorMessage;

  // Lightweight cache: skipping redundant DB fetches when exporting same period twice.
  String? _cachedFullReportPeriodId;
  PeriodReport? _cachedFullReport;

  ReportingController({
    required FirebaseService firebaseService,
    BuildReportSnapshotUseCase? snapshotUseCase,
    BuildRealtimeReportUseCase? realtimeUseCase,
  })  : _firebaseService = firebaseService,
        _snapshotUseCase = snapshotUseCase ?? BuildReportSnapshotUseCase(),
        _realtimeUseCase = realtimeUseCase ?? BuildRealtimeReportUseCase();

  // ── Getters ─────────────────────────────────────────────────────────────────
  List<PeriodData> get closedPeriods => _closedPeriods;
  String? get selectedPeriodId => _selectedPeriodId;
  bool get isLoading => _isLoading;
  bool get isLoadingRecordings => _isLoadingRecordings;
  bool get isExporting => _isExporting;
  bool get isLoadingRecordingDetail => _isLoadingRecordingDetail;
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
    // Invalidate export cache when period changes.
    _cachedFullReportPeriodId = null;
    _cachedFullReport = null;
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

  // ── Export Flow ──────────────────────────────────────────────────────────────
  /// Selalu fetch recordings dari DB, hitung ulang report, lalu export.
  /// TIDAK pakai [_report] yang ada di UI — data bisa tidak lengkap (recordings=[]).
  ///
  /// [onError] dipanggil kalau ada kegagalan di mana saja dalam flow.
  Future<void> exportCsv({required void Function(String) onError}) async {
    await _runExport(
      onError: onError,
      doExport: (report) => ExportPeriodCsv().execute(report),
    );
  }

  Future<void> exportExcel({required void Function(String) onError}) async {
    await _runExport(
      onError: onError,
      doExport: (report) => ExportPeriodExcel().execute(report),
    );
  }

  Future<void> _runExport({
    required void Function(String) onError,
    required Future<void> Function(PeriodReport) doExport,
  }) async {
    if (_isExporting) return; // Cegah double tap.

    _isExporting = true;
    notifyListeners();

    try {
      final fullReport = await _buildFullReportForExport();

      if (fullReport == null) {
        onError('Tidak ada data recording untuk periode ini.');
        return;
      }

      await doExport(fullReport);
    } catch (e) {
      onError(e.toString());
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  /// Fetch recordings dari DB dan generate report ulang dari awal.
  /// Pakai cache ringan: jika period sama dan cache masih ada, skip fetch.
  Future<PeriodReport?> _buildFullReportForExport() async {
    final period = selectedPeriod;
    if (period == null) return null;

    // Return cache jika period sama.
    if (_cachedFullReportPeriodId == period.id && _cachedFullReport != null) {
      return _cachedFullReport;
    }

    final recordings = await _firebaseService.getRecordingsOnce(period.id);

    if (recordings.isEmpty) return null;

    final fullReport = _realtimeUseCase.execute(period, recordings);

    // Simpan cache.
    _cachedFullReportPeriodId = period.id;
    _cachedFullReport = fullReport;

    return fullReport;
  }

  // ── View Recording Detail Flow ────────────────────────────────────────────────
  /// Fetch recordings dari DB lalu panggil [onReady] dengan hasilnya.
  /// Reuses cache yang sama dengan export flow — tidak double fetch jika sudah ada.
  ///
  /// [onReady]  dipanggil dengan list recordings saat data siap.
  /// [onError]  dipanggil dengan pesan error jika gagal.
  Future<void> viewRecordingDetail({
    required void Function(List<RecordingData>) onReady,
    required void Function(String) onError,
  }) async {
    if (_isLoadingRecordingDetail) return; // Cegah double tap.

    _isLoadingRecordingDetail = true;
    notifyListeners();

    try {
      final period = selectedPeriod;
      if (period == null) {
        onError('Tidak ada periode yang dipilih.');
        return;
      }

      List<RecordingData> recordings;

      // Reuse cache dari export jika tersedia — skip fetch.
      if (_cachedFullReportPeriodId == period.id && _cachedFullReport != null) {
        recordings = _cachedFullReport!.recordings;
      } else {
        recordings = await _firebaseService.getRecordingsOnce(period.id);
        if (recordings.isNotEmpty) {
          final fullReport = _realtimeUseCase.execute(period, recordings);
          _cachedFullReportPeriodId = period.id;
          _cachedFullReport = fullReport;
        }
      }

      if (recordings.isEmpty) {
        onError('Tidak ada data recording untuk periode ini.');
        return;
      }

      onReady(recordings);
    } catch (e) {
      onError(e.toString());
    } finally {
      _isLoadingRecordingDetail = false;
      notifyListeners();
    }
  }

  /// Bersihkan data tanpa subscribe ulang. Dipanggil saat logout.
  void clear() {
    _periodSub?.cancel();
    _periodSub = null;
    _closedPeriods = [];
    _selectedPeriodId = null;
    _isLoading = false;
    _isLoadingRecordings = false;
    _isExporting = false;
    _recordings = [];
    _report = null;
    _errorMessage = null;
    _cachedFullReportPeriodId = null;
    _cachedFullReport = null;
    notifyListeners();
  }

  /// Subscribe ulang dengan UID baru. Dipanggil saat ganti akun.
  void reload() {
    _periodSub?.cancel();
    _periodSub = null;
    _closedPeriods = [];
    _selectedPeriodId = null;
    _isLoading = true;
    _isLoadingRecordings = false;
    _isExporting = false;
    _recordings = [];
    _report = null;
    _errorMessage = null;
    _cachedFullReportPeriodId = null;
    _cachedFullReport = null;
    notifyListeners();
    _init();
  }

  @override
  void dispose() {
    _periodSub?.cancel();
    super.dispose();
  }
}
