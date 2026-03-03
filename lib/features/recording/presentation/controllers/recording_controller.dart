import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/recording/data/models/fcr_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_fcr.dart';

class RecordingController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final CalculateFCR _calculateFCR;

  RecordingController({
    required FirebaseService firebaseService,
    CalculateFCR? calculateFCR,
  })  : _firebaseService = firebaseService,
        _calculateFCR = calculateFCR ?? CalculateFCR();

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

      if (_activePeriodId != null) {
        _initialPopulation = activePeriod!.initialCapacity;
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

  void refreshStreams() {
    if (_activePeriodId != null) {
      _recordingsStream = _firebaseService.getRecordingsStream(_activePeriodId!);
      _weightStream = _firebaseService.getWeightStream(_activePeriodId!);
      notifyListeners();
    }
  }

  List<FCRData> calculateWeeklyFCR(List<RecordingData> recordings) {
    if (recordings.isEmpty || _initialPopulation == 0) return <FCRData>[];
    return _calculateFCR.execute(recordings, _initialPopulation);
  }

  Future<void> updateRecording(RecordingData recording) async {
    if (_activePeriodId == null) return;
    await _firebaseService.updateRecording(_activePeriodId!, recording.id, recording);
  }
}
