import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/recording_validator.dart';

void main() {
  group('RecordingValidator Unit Tests', () {
    group('validateDay', () {
      test('mengembalikan error jika kosong atau null', () {
        expect(RecordingValidator.validateDay(null), isNotNull);
        expect(RecordingValidator.validateDay(''), isNotNull);
        expect(RecordingValidator.validateDay('   '), isNotNull);
      });

      test('mengembalikan error jika angka <= 0', () {
        expect(RecordingValidator.validateDay('0'), contains('lebih dari 0'));
        expect(RecordingValidator.validateDay('-5'), contains('lebih dari 0'));
      });

      test('mengembalikan error jika umur > 60 hari', () {
        expect(RecordingValidator.validateDay('65'), contains('maksimal 60 hari'));
      });

      test('mengembalikan null jika umur valid', () {
        expect(RecordingValidator.validateDay('1'), isNull);
        expect(RecordingValidator.validateDay('28'), isNull);
        expect(RecordingValidator.validateDay('45'), isNull);
      });
    });

    group('validateFeedInput', () {
      test('mengembalikan error jika kosong atau <= 0', () {
        expect(RecordingValidator.validateFeedInput('', 'Sak'), isNotNull);
        expect(RecordingValidator.validateFeedInput('0', 'Sak'), contains('lebih dari 0'));
      });

      test('menolak typo sak terlalu besar (> 250 sak)', () {
        expect(
          RecordingValidator.validateFeedInput('300', 'Sak'),
          contains('terlalu besar'),
        );
      });

      test('menolak kg terlalu besar (> 15.000 kg)', () {
        expect(
          RecordingValidator.validateFeedInput('20000', 'Kg'),
          contains('melebihi batas wajar'),
        );
      });

      test('menerima input pakan wajar dalam Sak dan Kg', () {
        expect(RecordingValidator.validateFeedInput('3', 'Sak'), isNull);
        expect(RecordingValidator.validateFeedInput('150', 'Kg'), isNull);
        expect(RecordingValidator.validateFeedInput('2.5', 'Sak'), isNull);
      });
    });

    group('validateWeightInput', () {
      test('menolak typo gram terlalu kecil (< 25g) dengan saran satuan Kg', () {
        final err = RecordingValidator.validateWeightInput('1.5', 'Gram');
        expect(err, contains('terlalu kecil'));
        expect(err, contains('Apakah satuan Anda Kg'));
      });

      test('menolak typo gram terlalu besar (> 6000g)', () {
        expect(
          RecordingValidator.validateWeightInput('7500', 'Gram'),
          contains('melebihi batas wajar'),
        );
      });

      test('menolak typo kg terlalu besar (> 6.0 kg) dengan saran satuan Gram', () {
        final err = RecordingValidator.validateWeightInput('1250', 'Kg');
        expect(err, contains('terlalu berat'));
        expect(err, contains('Apakah satuan Anda Gram'));
      });

      test('menerima input bobot wajar dalam Gram dan Kg', () {
        expect(RecordingValidator.validateWeightInput('1450', 'Gram'), isNull);
        expect(RecordingValidator.validateWeightInput('1.45', 'Kg'), isNull);
      });
    });

    group('validateMortality', () {
      test('mengembalikan error jika angka negatif', () {
        expect(RecordingValidator.validateMortality('-1'), contains('0 atau lebih'));
      });

      test('menerima input angka 0 dan bilangan positif', () {
        expect(RecordingValidator.validateMortality('0'), isNull);
        expect(RecordingValidator.validateMortality('5'), isNull);
      });
    });

    group('checkAnomalies', () {
      test('mendeteksi mortalitas melebihi sisa populasi (BLOCKING)', () {
        final newRec = RecordingData(
          day: 10,
          avgWeightGram: 300,
          feedSack: 2,
          mortality: 1050, // Lebih dari populasi 1000
          createdAt: DateTime(2026, 1, 10),
        );

        final anomalies = RecordingValidator.checkAnomalies(
          newRecording: newRec,
          initialPopulation: 1000,
          existingRecordings: [],
        );

        expect(anomalies, isNotEmpty);
        expect(anomalies.first.isBlocking, isTrue);
        expect(anomalies.first.title, 'Mortalitas Melebihi Populasi');
      });

      test('mendeteksi mortalitas massal tinggi > 10% (Non-blocking warning)', () {
        final newRec = RecordingData(
          day: 10,
          avgWeightGram: 300,
          feedSack: 2,
          mortality: 150, // 15% dari 1000
          createdAt: DateTime(2026, 1, 10),
        );

        final anomalies = RecordingValidator.checkAnomalies(
          newRecording: newRec,
          initialPopulation: 1000,
          existingRecordings: [],
        );

        expect(anomalies.any((a) => a.title == 'Mortalitas Tinggi Terdeteksi'), isTrue);
      });

      test('mendeteksi bobot terlalu ringan atau terlalu berat untuk umur ayam', () {
        // Hari 1 bobot 500g (standar DOC max 75g)
        final heavyDoc = RecordingData(
          day: 1,
          avgWeightGram: 500,
          feedSack: 1,
          mortality: 0,
          createdAt: DateTime(2026, 1, 1),
        );

        final anomalies = RecordingValidator.checkAnomalies(
          newRecording: heavyDoc,
          initialPopulation: 1000,
          existingRecordings: [],
        );

        expect(anomalies.any((a) => a.title == 'Bobot di Atas Standar'), isTrue);
      });

      test('mendeteksi penurunan bobot drastis dibanding hari sebelumnya', () {
        final day7 = RecordingData(
          day: 7,
          avgWeightGram: 200,
          feedSack: 1,
          mortality: 0,
          createdAt: DateTime(2026, 1, 7),
        );
        final day8Typo = RecordingData(
          day: 8,
          avgWeightGram: 100, // Turun 50% dari hari 7
          feedSack: 1,
          mortality: 0,
          createdAt: DateTime(2026, 1, 8),
        );

        final anomalies = RecordingValidator.checkAnomalies(
          newRecording: day8Typo,
          initialPopulation: 1000,
          existingRecordings: [day7],
        );

        expect(anomalies.any((a) => a.title == 'Penurunan Bobot Drastis'), isTrue);
      });
    });
  });
}
