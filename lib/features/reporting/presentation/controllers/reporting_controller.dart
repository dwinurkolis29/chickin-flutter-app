import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/finance/data/models/finance_summary.dart';
import 'package:recording_app/features/finance/data/models/finance_transaction.dart';
import 'package:recording_app/features/finance/domain/usecases/calculate_finance_summary.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/build_realtime_report_usecase.dart';
import 'package:recording_app/features/reporting/domain/usecases/build_report_snapshot_usecase.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/domain/usecases/period_comparison_calculator.dart';

class ReportingController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final BuildReportSnapshotUseCase _snapshotUseCase;
  final BuildRealtimeReportUseCase _realtimeUseCase;
  final CalculateFinanceSummary _calculateFinance;
  final PeriodComparisonCalculator _comparisonCalculator;

  StreamSubscription<List<PeriodData>>? _periodSub;
  String? _currentUid;

  List<PeriodData> _closedPeriods = [];
  String? _selectedPeriodId;
  bool _isLoading = false;
  bool _isLoadingRecordings = false;
  bool _isLoadingRecordingDetail = false;
  List<RecordingData> _recordings = [];
  PeriodReport? _report;
  String? _errorMessage;

  FinanceSummary _financeSummary = const FinanceSummary();
  PeriodDeltaComparison? _comparison;
  CageData _cageData = const CageData();

  // Lightweight cache: skipping redundant DB fetches when exporting same period twice.
  String? _cachedFullReportPeriodId;
  PeriodReport? _cachedFullReport;

  ReportingController({
    required FirebaseService firebaseService,
    BuildReportSnapshotUseCase? snapshotUseCase,
    BuildRealtimeReportUseCase? realtimeUseCase,
    CalculateFinanceSummary? calculateFinance,
    PeriodComparisonCalculator? comparisonCalculator,
  })  : _firebaseService = firebaseService,
        _snapshotUseCase = snapshotUseCase ?? BuildReportSnapshotUseCase(),
        _realtimeUseCase = realtimeUseCase ?? BuildRealtimeReportUseCase(),
        _calculateFinance = calculateFinance ?? CalculateFinanceSummary(),
        _comparisonCalculator = comparisonCalculator ?? PeriodComparisonCalculator();

  // ── Getters ─────────────────────────────────────────────────────────────────
  List<PeriodData> get closedPeriods => _closedPeriods;
  String? get selectedPeriodId => _selectedPeriodId;
  bool get isLoading => _isLoading;
  bool get isLoadingRecordings => _isLoadingRecordings;
  bool get isLoadingRecordingDetail => _isLoadingRecordingDetail;
  List<RecordingData> get recordings => _recordings;
  PeriodReport? get report => _report;
  String? get errorMessage => _errorMessage;
  FinanceSummary get financeSummary => _financeSummary;
  PeriodDeltaComparison? get comparison => _comparison;
  CageData get cageData => _cageData;

  PeriodData? get selectedPeriod => _closedPeriods
      .where((p) => p.id == _selectedPeriodId)
      .firstOrNull;

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  /// Dipanggil oleh ProxyProvider.update() setiap kali auth state berubah.
  void onAuthChanged(String? uid) {
    if (uid == null) {
      _currentUid = null;
      clear();
      return;
    }

    _currentUid = uid;
    _periodSub?.cancel(); // Cancel sebelum buat yang baru — hindari leak
    _periodSub = null;
    _closedPeriods = [];
    _selectedPeriodId = null;
    _isLoading = true;
    _isLoadingRecordings = false;
    _recordings = [];
    _report = null;
    _errorMessage = null;
    _cachedFullReportPeriodId = null;
    _cachedFullReport = null;
    notifyListeners();

    _periodSub = _firebaseService.getPeriodsStream(uid).listen(
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
      _cageData = await _firebaseService.getCage(_currentUid);

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

      // 3. Fetch data keuangan periode ini
      List<FinanceTransaction> transactions = [];
      try {
        transactions = await _firebaseService.getFinanceTransactions(
          period.id,
          _currentUid,
        );
      } catch (e) {
        debugPrint('Warning: gagal memuat transaksi keuangan: $e');
        transactions = [];
      }
      _financeSummary = _calculateFinance.execute(
        transactions: transactions,
        fallbackHarvestWeightKg:
            _report?.harvestedWeightKg ?? _report?.totalBiomassKg,
        fallbackHarvestedChicks:
            _report?.harvestedChicks ?? _report?.finalPopulation,
      );

      // 4. Komparasi periode sebelumnya (jika ada)
      PeriodReport? prevReport;
      FinanceSummary? prevFinance;
      final currentIndex = _closedPeriods.indexWhere((p) => p.id == period.id);
      if (currentIndex != -1 && currentIndex + 1 < _closedPeriods.length) {
        final prevPeriod = _closedPeriods[currentIndex + 1];
        prevReport = _snapshotUseCase.execute(prevPeriod);
        try {
          final prevTx = await _firebaseService.getFinanceTransactions(
            prevPeriod.id,
            _currentUid,
          );
          prevFinance = _calculateFinance.execute(
            transactions: prevTx,
            fallbackHarvestWeightKg:
                prevReport.harvestedWeightKg ?? prevReport.totalBiomassKg,
            fallbackHarvestedChicks:
                prevReport.harvestedChicks ?? prevReport.finalPopulation,
          );
        } catch (_) {
          prevFinance = const FinanceSummary();
        }
      }

      // 5. Kalkulasi komparasi delta & tren 3 periode
      if (_report != null) {
        _comparison = _comparisonCalculator.execute(
          currentReport: _report!,
          currentFinance: _financeSummary,
          previousReport: prevReport,
          previousFinance: prevFinance,
          recentPeriods: _closedPeriods,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingRecordings = false;
      notifyListeners();
    }
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
    _recordings = [];
    _report = null;
    _errorMessage = null;
    _cachedFullReportPeriodId = null;
    _cachedFullReport = null;
    notifyListeners();
  }

  /// Refresh data menggunakan UID saat ini. Aman dipanggil dari pull-to-refresh.
  /// Berbeda dengan onAuthChanged — tidak butuh uid dari luar, tidak akan trigger clear().
  void reload([String? uid]) => onAuthChanged(uid ?? _currentUid);

  @override
  void dispose() {
    _periodSub?.cancel();
    super.dispose();
  }
}
