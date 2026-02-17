import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/dashboard/data/models/fcr_data.dart';
import 'package:recording_app/features/dashboard/data/models/recording_data.dart';
import 'package:recording_app/features/dashboard/domain/usecases/calculate_fcr_usecase.dart';

class HomeController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final CalculateFCRUseCase _calculateFCRUseCase;
  
  HomeController({
    required FirebaseService firebaseService,
    CalculateFCRUseCase? calculateFCRUseCase,
  })  : _firebaseService = firebaseService,
        _calculateFCRUseCase = calculateFCRUseCase ?? CalculateFCRUseCase();

  String? _activePeriodId;
  bool _isLoadingPeriod = true;
  int _initialPopulation = 0;
  Stream<List<RecordingData>>? _recordingsStream;
  Stream<List<FlSpot>>? _weightStream;

  String? get activePeriodId => _activePeriodId;
  bool get isLoadingPeriod => _isLoadingPeriod;
  int get initialPopulation => _initialPopulation;
  Stream<List<RecordingData>>? get recordingsStream => _recordingsStream;
  Stream<List<FlSpot>>? get weightStream => _weightStream;

  Future<void> loadActivePeriod() async {
    try {
      final activePeriod = await _firebaseService.getActivePeriod();
      _activePeriodId = activePeriod?.id;
      
      // Load initial population from cage data
      if (_activePeriodId != null) {
        final cageData = await _firebaseService.getCage();
        _initialPopulation = cageData.capacity;
        // Cache streams so they don't get recreated on every rebuild
        _recordingsStream = _firebaseService.getRecordingsStream(_activePeriodId!);
        _weightStream = _firebaseService.getWeightStream(_activePeriodId!);
      }
      
      _isLoadingPeriod = false;
      notifyListeners();
    } catch (e) {
      _isLoadingPeriod = false;
      notifyListeners();
    }
  }

  // Refresh streams to get latest data (e.g., after adding new recording)
  void refreshStreams() {
    if (_activePeriodId != null) {
      _recordingsStream = _firebaseService.getRecordingsStream(_activePeriodId!);
      _weightStream = _firebaseService.getWeightStream(_activePeriodId!);
      notifyListeners();
    }
  }

  List<FCRData> calculateWeeklyFCR(List<RecordingData> recordings) {
    if (recordings.isEmpty || _initialPopulation == 0) {
      return <FCRData>[];
    }
    return _calculateFCRUseCase.execute(recordings, _initialPopulation);
  }
}
