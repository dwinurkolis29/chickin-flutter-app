import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/period/data/models/harvest_record.dart';
import 'package:recording_app/features/period/data/models/hospital_pen_data.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/fcr_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_fcr.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';

class _FakeCalculateFCR extends Fake implements CalculateFCR {
  @override
  List<FCRData> execute(
    List<RecordingData> recordings,
    int initialCapacity, {
    List<HarvestRecord>? harvests,
  }) {
    return const [
      FCRData(
        mingguKe: 1,
        totalPakan: 100,
        sisaAyam: 950,
        beratAyam: 60,
        fcr: 1.67,
      ),
    ];
  }
}

class _FakeFirebaseService extends Fake implements FirebaseService {
  PeriodData? mockActivePeriod;
  List<RecordingData> mockRecordings = [];
  List<FlSpot> mockWeights = [];

  HospitalPenData? lastUpdatedHospitalPen;
  String? lastUpdatedHospitalPenPeriodId;

  RecordingData? lastUpdatedRecording;
  String? lastUpdatedRecordingPeriodId;
  String? lastUpdatedRecordingId;

  bool throwOnGetActivePeriod = false;

  @override
  Future<PeriodData?> getActivePeriod([String? uid]) async {
    if (throwOnGetActivePeriod) {
      throw Exception('Firestore fetch error');
    }
    return mockActivePeriod;
  }

  @override
  Stream<List<RecordingData>> getRecordingsStream(
    String periodId, [
    String? uid,
  ]) => Stream.value(mockRecordings);

  @override
  Stream<List<FlSpot>> getWeightStream(String periodId, [String? uid]) =>
      Stream.value(mockWeights);

  @override
  Future<void> updateHospitalPen(
    String periodId,
    HospitalPenData? hospitalPen, [
    String? uid,
  ]) async {
    lastUpdatedHospitalPenPeriodId = periodId;
    lastUpdatedHospitalPen = hospitalPen;
  }

  @override
  Future<void> updateRecording(
    String periodId,
    String recordingId,
    RecordingData recording, [
    String? uid,
  ]) async {
    lastUpdatedRecordingPeriodId = periodId;
    lastUpdatedRecordingId = recordingId;
    lastUpdatedRecording = recording;
  }
}

void main() {
  group('RecordingController', () {
    late _FakeFirebaseService fakeFirebase;
    late _FakeCalculateFCR fakeCalculateFCR;
    late RecordingController controller;

    final samplePeriod = PeriodData(
      id: 'period-123',
      name: 'Kandang A Periode 1',
      initialCapacity: 3000,
      initialWeight: 45,
      startDate: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      isActive: true,
      summary: const PeriodSummary(
        hospitalPen: HospitalPenData(
          count: 100,
          avgWeightGram: 1100,
          day: 25,
        ),
      ),
    );

    setUp(() {
      fakeFirebase = _FakeFirebaseService();
      fakeCalculateFCR = _FakeCalculateFCR();
      controller = RecordingController(
        firebaseService: fakeFirebase,
        calculateFCR: fakeCalculateFCR,
      );
    });

    test('initial state is clean and uninitialized', () {
      expect(controller.activePeriod, isNull);
      expect(controller.activePeriodId, isNull);
      expect(controller.hospitalPen, isNull);
      expect(controller.isLoadingPeriod, isFalse);
      expect(controller.initialPopulation, 0);
      expect(controller.recordingsStream, isNull);
      expect(controller.weightStream, isNull);
    });

    test('loadActivePeriod sets activePeriod, population, and streams correctly', () async {
      fakeFirebase.mockActivePeriod = samplePeriod;

      await controller.loadActivePeriod();

      expect(controller.activePeriod, samplePeriod);
      expect(controller.activePeriodId, 'period-123');
      expect(controller.initialPopulation, 3000);
      expect(controller.hospitalPen?.count, 100);
      expect(controller.isLoadingPeriod, isFalse);
      expect(controller.recordingsStream, isNotNull);
      expect(controller.weightStream, isNotNull);
    });

    test('loadActivePeriod handles exception gracefully without crashing', () async {
      fakeFirebase.throwOnGetActivePeriod = true;

      await controller.loadActivePeriod();

      expect(controller.activePeriod, isNull);
      expect(controller.isLoadingPeriod, isFalse);
    });

    test('refreshStreams re-attaches streams when activePeriodId is present', () async {
      fakeFirebase.mockActivePeriod = samplePeriod;
      await controller.loadActivePeriod();

      controller.refreshStreams();

      expect(controller.recordingsStream, isNotNull);
      expect(controller.weightStream, isNotNull);
    });

    test('calculateWeeklyFCR returns empty list if recordings is empty or population is 0', () {
      final recordings = [
        RecordingData(
          id: 'r1',
          day: 1,
          avgWeightGram: 45,
          feedSack: 1,
          mortality: 0,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      // Population is 0
      expect(controller.calculateWeeklyFCR(recordings), isEmpty);

      // Recordings is empty
      controller.onAuthChanged('test-uid');
      expect(controller.calculateWeeklyFCR([]), isEmpty);
    });

    test('calculateWeeklyFCR delegates to CalculateFCR when valid', () async {
      fakeFirebase.mockActivePeriod = samplePeriod;
      await controller.loadActivePeriod();

      final recordings = [
        RecordingData(
          id: 'r1',
          day: 1,
          avgWeightGram: 45,
          feedSack: 1,
          mortality: 0,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      final result = controller.calculateWeeklyFCR(recordings);
      expect(result, isNotEmpty);
      expect(result.first.mingguKe, 1);
    });

    test('updateRecording delegates to FirebaseService', () async {
      fakeFirebase.mockActivePeriod = samplePeriod;
      await controller.loadActivePeriod();

      final rec = RecordingData(
        id: 'rec-1',
        day: 7,
        avgWeightGram: 180,
        feedSack: 3,
        mortality: 2,
        createdAt: DateTime(2026, 1, 7),
      );

      await controller.updateRecording(rec);

      expect(fakeFirebase.lastUpdatedRecordingPeriodId, 'period-123');
      expect(fakeFirebase.lastUpdatedRecordingId, 'rec-1');
      expect(fakeFirebase.lastUpdatedRecording?.avgWeightGram, 180);
    });

    test('saveHospitalPen updates service and local activePeriod state', () async {
      fakeFirebase.mockActivePeriod = samplePeriod;
      await controller.loadActivePeriod();

      const newPenData = HospitalPenData(
        count: 150,
        avgWeightGram: 1206,
        day: 28,
        conditions: ['Kerdil', 'Pincang'],
        notes: 'Sekat baru',
      );

      await controller.saveHospitalPen(newPenData);

      // 1. Service called
      expect(fakeFirebase.lastUpdatedHospitalPenPeriodId, 'period-123');
      expect(fakeFirebase.lastUpdatedHospitalPen?.count, 150);
      expect(fakeFirebase.lastUpdatedHospitalPen?.avgWeightGram, 1206);

      // 2. Local state updated
      expect(controller.hospitalPen?.count, 150);
      expect(controller.hospitalPen?.avgWeightGram, 1206);
      expect(controller.hospitalPen?.conditions, ['Kerdil', 'Pincang']);
    });

    test('saveHospitalPen with null resets sekat data locally and in service', () async {
      fakeFirebase.mockActivePeriod = samplePeriod;
      await controller.loadActivePeriod();

      expect(controller.hospitalPen, isNotNull);

      await controller.saveHospitalPen(null);

      expect(fakeFirebase.lastUpdatedHospitalPenPeriodId, 'period-123');
      expect(fakeFirebase.lastUpdatedHospitalPen, isNull);
      expect(controller.hospitalPen, isNull);
    });

    test('saveHospitalPen returns early if activePeriodId is null', () async {
      const penData = HospitalPenData(count: 50, avgWeightGram: 500, day: 10);
      await controller.saveHospitalPen(penData);

      expect(fakeFirebase.lastUpdatedHospitalPenPeriodId, isNull);
    });

    test('onAuthChanged clears state on null uid', () async {
      fakeFirebase.mockActivePeriod = samplePeriod;
      await controller.loadActivePeriod();

      expect(controller.activePeriod, isNotNull);

      controller.onAuthChanged(null);

      expect(controller.activePeriod, isNull);
      expect(controller.activePeriodId, isNull);
      expect(controller.initialPopulation, 0);
      expect(controller.recordingsStream, isNull);
    });

    test('onAuthChanged reloads active period when uid is provided', () async {
      fakeFirebase.mockActivePeriod = samplePeriod;

      controller.onAuthChanged('user-1');

      // Wait for async loadActivePeriod triggered inside onAuthChanged
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.activePeriodId, 'period-123');
    });

    test('clear resets all state variables', () async {
      fakeFirebase.mockActivePeriod = samplePeriod;
      await controller.loadActivePeriod();

      controller.clear();

      expect(controller.activePeriod, isNull);
      expect(controller.activePeriodId, isNull);
      expect(controller.initialPopulation, 0);
      expect(controller.recordingsStream, isNull);
      expect(controller.isLoadingPeriod, isFalse);
    });

    test('reload delegates to onAuthChanged', () async {
      fakeFirebase.mockActivePeriod = samplePeriod;

      controller.reload('user-2');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.activePeriodId, 'period-123');
    });
  });
}
