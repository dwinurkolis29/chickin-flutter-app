import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/period/presentation/controllers/period_controller.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {
  final List<PeriodData> createdPeriods = [];
  final List<PeriodData> updatedPeriods = [];

  @override
  Stream<List<PeriodData>> getPeriodsStream([String? uid]) {
    return Stream.value([]);
  }

  @override
  Future<String> createPeriod(PeriodData period, [String? uid]) async {
    createdPeriods.add(period);
    return 'new-id';
  }

  @override
  Future<void> updatePeriod(String periodId, PeriodData period, [String? uid]) async {
    updatedPeriods.add(period);
  }
}

void main() {
  group('PeriodController.createPeriod', () {
    test('belum ada periode aktif -> otomatis menjadi periode aktif (isActive = true)', () async {
      final fakeFirebase = _FakeFirebaseService();
      final controller = PeriodController(firebaseService: fakeFirebase);

      final newPeriod = PeriodData(
        name: 'Periode Pertama',
        initialCapacity: 3000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
      );

      await controller.createPeriod(newPeriod);

      expect(fakeFirebase.createdPeriods.length, 1);
      expect(fakeFirebase.createdPeriods.first.name, 'Periode Pertama');
      expect(fakeFirebase.createdPeriods.first.isActive, isTrue);
    });

    test('sudah ada periode aktif -> otomatis disimpan sebagai draft (isActive = false)', () async {
      final fakeFirebase = _FakeFirebaseService();
      final controller = PeriodController(firebaseService: fakeFirebase);

      // Simulasikan ada periode yang sedang aktif
      final activePeriod = PeriodData(
        id: 'active-1',
        name: 'Periode Berjalan',
        initialCapacity: 5000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 7, 1),
        createdAt: DateTime(2026, 7, 1),
        isActive: true,
      );

      // Gunakan onAuthChanged atau inject data ke controller
      controller.periods.add(activePeriod);

      final secondPeriod = PeriodData(
        name: 'Periode Kedua',
        initialCapacity: 4000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
      );

      await controller.createPeriod(secondPeriod);

      expect(fakeFirebase.createdPeriods.length, 1);
      expect(fakeFirebase.createdPeriods.first.name, 'Periode Kedua');
      expect(fakeFirebase.createdPeriods.first.isActive, isFalse);
    });
  });

  group('PeriodController.updatePeriodDetails', () {
    test('periode aktif dapat diedit detailnya (kapasitas/nama/bobot)', () async {
      final fakeFirebase = _FakeFirebaseService();
      final controller = PeriodController(firebaseService: fakeFirebase);

      final activePeriod = PeriodData(
        id: 'active-1',
        name: 'Batch Lama',
        initialCapacity: 5000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 7, 1),
        createdAt: DateTime(2026, 7, 1),
        isActive: true,
      );
      controller.periods.add(activePeriod);

      final updatedData = activePeriod.copyWith(
        name: 'Batch Baru Terkoreksi',
        initialCapacity: 5100,
      );

      await controller.updatePeriodDetails('active-1', updatedData);

      expect(fakeFirebase.updatedPeriods.length, 1);
      expect(fakeFirebase.updatedPeriods.first.name, 'Batch Baru Terkoreksi');
      expect(fakeFirebase.updatedPeriods.first.initialCapacity, 5100);
      expect(fakeFirebase.updatedPeriods.first.isActive, isTrue);
    });

    test('periode selesai panen (closed) tidak dapat diedit', () async {
      final fakeFirebase = _FakeFirebaseService();
      final controller = PeriodController(firebaseService: fakeFirebase);

      final closedPeriod = PeriodData(
        id: 'closed-1',
        name: 'Batch Selesai',
        initialCapacity: 5000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 7, 10),
        createdAt: DateTime(2026, 6, 1),
        isActive: false,
      );
      controller.periods.add(closedPeriod);

      expect(
        () => controller.updatePeriodDetails('closed-1', closedPeriod.copyWith(name: 'Ubah Nama')),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PeriodController.activatePeriod', () {
    test('menolak aktivasi jika ada periode lain yang sedang berjalan', () async {
      final fakeFirebase = _FakeFirebaseService();
      final controller = PeriodController(firebaseService: fakeFirebase);

      final activePeriod = PeriodData(
        id: 'active-1',
        name: 'Batch Sedang Aktif',
        initialCapacity: 5000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 7, 1),
        createdAt: DateTime(2026, 7, 1),
        isActive: true,
      );
      final draftPeriod = PeriodData(
        id: 'draft-1',
        name: 'Batch Draft',
        initialCapacity: 4000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
        isActive: false,
      );
      controller.periods.addAll([activePeriod, draftPeriod]);

      expect(
        () => controller.activatePeriod('draft-1'),
        throwsA(predicate((e) => e.toString().contains('Ada periode lain yang sedang berjalan'))),
      );
    });
  });
}
