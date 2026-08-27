import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/recording/data/models/daily_fcr_data.dart';
import 'package:recording_app/features/recording/data/models/fcr_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_fcr.dart';

class HomeController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final CalculateFCR _calculateFCRUseCase;
  
  HomeController({
    required FirebaseService firebaseService,
    CalculateFCR? calculateFCRUseCase,
  })  : _firebaseService = firebaseService,
        _calculateFCRUseCase = calculateFCRUseCase ?? CalculateFCR();

  String? _activePeriodId;
  String? _activePeriodName;
  bool _isLoadingPeriod = false;
  int _initialPopulation = 0;
  Stream<List<RecordingData>>? _recordingsStream;
  Stream<List<FlSpot>>? _weightStream;
  List<RecordingData>? _cachedRecordings;

  String? get activePeriodId => _activePeriodId;
  String? get activePeriodName => _activePeriodName;
  bool get isLoadingPeriod => _isLoadingPeriod;
  int get initialPopulation => _initialPopulation;
  Stream<List<RecordingData>>? get recordingsStream => _recordingsStream;
  Stream<List<FlSpot>>? get weightStream => _weightStream;
  List<RecordingData>? get cachedRecordings => _cachedRecordings;

  void setCachedRecordings(List<RecordingData> data) {
    _cachedRecordings = data;
  }

  Future<void> loadActivePeriod([String? uid]) async {
    try {
      final activePeriod = await _firebaseService.getActivePeriod(uid);
      _activePeriodId = activePeriod?.id;
      
      // Load initial population from cage data
      if (_activePeriodId != null) {
        // Use period.initialCapacity as the source of truth for initial population
        // This ensures FCR is consistent with active_period_card
        _initialPopulation = activePeriod!.initialCapacity;
        _activePeriodName = activePeriod.name;
        // Cache streams so they don't get recreated on every rebuild
        _recordingsStream = _firebaseService.getRecordingsStream(_activePeriodId!, uid);
        _weightStream = _firebaseService.getWeightStream(_activePeriodId!, uid);
      }
      
      _isLoadingPeriod = false;
      notifyListeners();
    } catch (e) {
      _isLoadingPeriod = false;
      notifyListeners();
    }
  }

  // Refresh streams to get latest data (e.g., after adding new recording).
  // notifyListeners() di-defer ke post-frame agar tidak bentrok dengan
  // BuildScope._flushDirtyElements yang sedang berjalan saat pop navigation.
  void refreshStreams() {
    if (_activePeriodId != null) {
      _recordingsStream = _firebaseService.getRecordingsStream(_activePeriodId!);
      _weightStream = _firebaseService.getWeightStream(_activePeriodId!);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Dipanggil oleh ProxyProvider.update() setiap kali auth state berubah.
  void onAuthChanged(String? uid) {
    if (uid == null) {
      clear();
    } else {
      _activePeriodId = null;
      _activePeriodName = null;
      _initialPopulation = 0;
      _recordingsStream = null;
      _weightStream = null;
      _isLoadingPeriod = true;
      notifyListeners();
      loadActivePeriod(uid);
    }
  }

  /// Bersihkan data tanpa load ulang. Dipanggil saat logout.
  void clear() {
    _activePeriodId = null;
    _activePeriodName = null;
    _initialPopulation = 0;
    _recordingsStream = null;
    _weightStream = null;
    _cachedRecordings = null;
    _isLoadingPeriod = false;
    notifyListeners();
  }

  /// Load ulang dengan UID baru. Delegate ke onAuthChanged.
  void reload([String? uid]) => onAuthChanged(uid);

  List<FCRData> calculateWeeklyFCR(List<RecordingData> recordings) {
    if (recordings.isEmpty || initialPopulation == 0) {
      return <FCRData>[];
    }
    return _calculateFCRUseCase.execute(recordings, initialPopulation);
  }

  List<DailyFCRData> calculateDailyFCR(List<RecordingData> recordings) {
    if (recordings.isEmpty || initialPopulation == 0) {
      return <DailyFCRData>[];
    }
    return _calculateFCRUseCase.executeDaily(recordings, initialPopulation);
  }
}
