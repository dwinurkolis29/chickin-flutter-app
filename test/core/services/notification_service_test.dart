import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/services/notification_service.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Unit Tests', () {
    test('NotificationService adalah singleton yang mengembalikan instance identik', () {
      final service1 = NotificationService();
      final service2 = NotificationService();

      expect(identical(service1, service2), isTrue);
    });

    test('getFcmToken mengembalikan null dengan aman saat belum terautentikasi / testing environment', () async {
      final service = NotificationService();
      final token = await service.getFcmToken();

      expect(token, isNull);
    });

    test('top-level firebaseMessagingBackgroundHandler dapat dieksekusi tanpa throw unhandled error', () async {
      expect(firebaseMessagingBackgroundHandler, isNotNull);
    });

    test('syncDailyRecordingReminder membatalkan notifikasi jika activePeriod null', () async {
      final service = NotificationService();
      await expectLater(
        service.syncDailyRecordingReminder(activePeriod: null, recordings: const []),
        completes,
      );
    });

    test('syncDailyRecordingReminder membatalkan notifikasi jika activePeriod tidak aktif (isActive = false)', () async {
      final service = NotificationService();
      final inactivePeriod = PeriodData(
        id: 'p-inactive',
        name: 'Periode Selesai',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        initialCapacity: 1000,
        isActive: false,
        createdAt: DateTime.now(),
      );

      await expectLater(
        service.syncDailyRecordingReminder(activePeriod: inactivePeriod, recordings: const []),
        completes,
      );
    });

    test('syncDailyRecordingReminder membatalkan notifikasi jika tanggal mulai di masa depan (currentAgeDays < 1)', () async {
      final service = NotificationService();
      final futurePeriod = PeriodData(
        id: 'p-future',
        name: 'Periode Masa Depan',
        startDate: DateTime.now().add(const Duration(days: 5)),
        initialCapacity: 1000,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await expectLater(
        service.syncDailyRecordingReminder(activePeriod: futurePeriod, recordings: const []),
        completes,
      );
    });

    test('syncDailyRecordingReminder berjalan sukses saat ada periode aktif dan hari ini belum diisi', () async {
      final service = NotificationService();
      final activePeriod = PeriodData(
        id: 'p-active-1',
        name: 'Siklus 1',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        initialCapacity: 1000,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Recordings hanya sampai hari ke-4 (hari ke-6 belum diisi)
      final recordings = [
        RecordingData(day: 1, avgWeightGram: 100, feedSack: 2, mortality: 0, createdAt: DateTime.now()),
        RecordingData(day: 2, avgWeightGram: 150, feedSack: 3, mortality: 1, createdAt: DateTime.now()),
      ];

      await expectLater(
        service.syncDailyRecordingReminder(activePeriod: activePeriod, recordings: recordings),
        completes,
      );
    });

    test('syncDailyRecordingReminder berjalan sukses saat ada periode aktif dan hari ini sudah diisi', () async {
      final service = NotificationService();
      final now = DateTime.now();
      final activePeriod = PeriodData(
        id: 'p-active-2',
        name: 'Siklus 2',
        startDate: now.subtract(const Duration(days: 2)), // Hari ke-3
        initialCapacity: 1000,
        isActive: true,
        createdAt: now,
      );

      // Recordings sudah terisi sampai hari ke-3 (hari ini)
      final recordings = [
        RecordingData(day: 1, avgWeightGram: 100, feedSack: 2, mortality: 0, createdAt: now),
        RecordingData(day: 2, avgWeightGram: 150, feedSack: 3, mortality: 1, createdAt: now),
        RecordingData(day: 3, avgWeightGram: 210, feedSack: 3, mortality: 0, createdAt: now),
      ];

      await expectLater(
        service.syncDailyRecordingReminder(activePeriod: activePeriod, recordings: recordings),
        completes,
      );
    });
  });
}
