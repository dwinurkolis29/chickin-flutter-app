import '../../data/models/recording_data.dart';

/// Jenis peringatan anomali pada data recording
class RecordingAnomaly {
  final String title;
  final String message;
  final bool isBlocking; // Jika true, user tidak bisa melanjutkan sama sekali

  const RecordingAnomaly({
    required this.title,
    required this.message,
    this.isBlocking = false,
  });
}

/// Helper validasi input dan pencegahan typo/anomali biologis pada pencatatan recording ayam broiler.
class RecordingValidator {
  // ── 1. Field-Level Validators ──────────────────────────────────────────────

  /// Validasi umur ayam (Hari)
  static String? validateDay(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Umur ayam tidak boleh kosong.';
    }
    final day = int.tryParse(input.trim());
    if (day == null || day <= 0) {
      return 'Umur harus berupa angka lebih dari 0.';
    }
    if (day > 60) {
      return 'Umur ayam maksimal 60 hari untuk siklus broiler.';
    }
    return null;
  }

  /// Validasi input pakan dengan pengecekan typo satuan
  static String? validateFeedInput(String? input, String unit) {
    if (input == null || input.trim().isEmpty) {
      return 'Habis pakan tidak boleh kosong.';
    }
    final raw = input.trim().replaceAll(',', '.');
    final val = double.tryParse(raw);
    final maxInputSak = 250.0;
    if (val == null || val <= 0) {
      return 'Habis pakan harus lebih dari 0.';
    }

    if (unit == 'Sak') {
      if (val > maxInputSak) {
        return 'Habis pakan ($val sak) terlalu besar (maks wajar ~${maxInputSak.toInt()} sak per hari). '
            'Apakah satuan yang Anda maksud adalah Kg?';
      }
    } else {
      // Satuan Kg
      if (val > 15000) {
        return 'Jumlah pakan ($val kg) melebihi batas wajar harian.';
      }
    }
    return null;
  }

  /// Validasi input bobot ayam dengan deteksi salah satuan (Gram vs Kg)
  static String? validateWeightInput(String? input, String unit) {
    if (input == null || input.trim().isEmpty) {
      return 'Berat ayam tidak boleh kosong.';
    }
    final raw = input.trim().replaceAll(',', '.');
    final val = double.tryParse(raw);
    if (val == null || val <= 0) {
      return 'Berat ayam harus lebih dari 0.';
    }

    if (unit == 'Gram') {
      if (val < 25) {
        return 'Bobot ($val g) terlalu kecil (DOC min ~35g). Apakah satuan Anda Kg (misal: $val kg)?';
      }
      if (val > 6000) {
        return 'Bobot ($val g) melebihi batas wajar ayam broiler (maks 6.000g).';
      }
    } else {
      // Satuan Kg
      if (val < 0.025) {
        return 'Bobot ($val kg) terlalu kecil untuk ayam broiler.';
      }
      if (val > 6.0) {
        return 'Bobot ($val kg) terlalu berat untuk broiler. Apakah satuan Anda Gram (misal: ${(val).toInt()} gram)?';
      }
    }
    return null;
  }

  /// Validasi jumlah kematian ayam
  static String? validateMortality(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Mati ayam tidak boleh kosong.';
    }
    final mortality = int.tryParse(input.trim());
    if (mortality == null || mortality < 0) {
      return 'Jumlah mati harus berupa angka 0 atau lebih.';
    }
    if (mortality > 50000) {
      return 'Jumlah kematian tidak wajar (maks 50.000).';
    }
    return null;
  }

  // ── 2. Biological Range & Anomaly Checks ────────────────────────────────────

  /// Menghitung bobot standar broiler berdasarkan umur (Hari)
  static double getStandardWeightGram(int day) {
    if (day <= 0) return 42.0;
    if (day == 1) return 45.0;
    return 42.0 + (day * 14.0) + (day * day * 1.05);
  }

  /// Batas minimal bobot wajar per umur (toleransi 45% di bawah standar)
  static double getExpectedMinWeightGram(int day) {
    if (day <= 1) return 30.0;
    if (day <= 7) return 100.0;
    if (day <= 14) return 250.0;
    if (day <= 21) return 550.0;
    if (day <= 28) return 950.0;
    if (day <= 35) return 1400.0;
    return getStandardWeightGram(day) * 0.55;
  }

  /// Batas maksimal bobot wajar per umur (toleransi atas)
  static double getExpectedMaxWeightGram(int day) {
    if (day <= 1) return 75.0;
    if (day <= 7) return 300.0;
    if (day <= 14) return 750.0;
    if (day <= 21) return 1450.0;
    if (day <= 28) return 2300.0;
    if (day <= 35) return 3200.0;
    return (day * 95.0) + 100.0;
  }

  static bool _isDifferentRecord(RecordingData a, RecordingData b) {
    if (a.id.isNotEmpty && b.id.isNotEmpty) {
      return a.id != b.id;
    }
    return a.day != b.day;
  }

  /// Memeriksa anomali biologis, sisa populasi, dan penurunan drastis
  static List<RecordingAnomaly> checkAnomalies({
    required RecordingData newRecording,
    required int initialPopulation,
    required List<RecordingData> existingRecordings,
  }) {
    final anomalies = <RecordingAnomaly>[];

    // 1. Hitung total mortalitas dari recording hari-hari lain
    int totalPreviousMortality = 0;
    for (final r in existingRecordings) {
      if (_isDifferentRecord(r, newRecording)) {
        totalPreviousMortality += r.mortality;
      }
    }

    final currentLivePopulation = initialPopulation > 0
        ? (initialPopulation - totalPreviousMortality)
        : 1000;

    // A. Kematian melebihi sisa populasi (BLOCKING)
    if (initialPopulation > 0 && newRecording.mortality > currentLivePopulation) {
      anomalies.add(
        RecordingAnomaly(
          title: 'Mortalitas Melebihi Populasi',
          message:
              'Jumlah kematian (${newRecording.mortality} ekor) melebihi sisa populasi ayam saat ini ($currentLivePopulation ekor dari awal $initialPopulation ekor).',
          isBlocking: true,
        ),
      );
      return anomalies; // Langsung return jika blocking
    }

    // B. Kematian massal sangat tinggi (> 10% dari sisa populasi dalam 1 hari)
    if (currentLivePopulation > 0 &&
        newRecording.mortality > (currentLivePopulation * 0.10) &&
        newRecording.mortality > 10) {
      final pct = ((newRecording.mortality / currentLivePopulation) * 100).toStringAsFixed(1);
      anomalies.add(
        RecordingAnomaly(
          title: 'Mortalitas Tinggi Terdeteksi',
          message:
              'Jumlah kematian ${newRecording.mortality} ekor mencapai $pct% dari sisa populasi ($currentLivePopulation ekor). Pastikan angka ini bukan kesalahan ketik.',
          isBlocking: false,
        ),
      );
    }

    // C. Pengecekan bobot ayam di luar rentang umur wajar
    final weight = newRecording.avgWeightGram;
    if (weight > 0) {
      final minWeight = getExpectedMinWeightGram(newRecording.day);
      final maxWeight = getExpectedMaxWeightGram(newRecording.day);

      if (weight < minWeight) {
        anomalies.add(
          RecordingAnomaly(
            title: 'Bobot di Bawah Standar',
            message:
                'Bobot $weight gram terlalu ringan untuk umur ${newRecording.day} hari (standar minimal ~${minWeight.toInt()} gram).',
            isBlocking: false,
          ),
        );
      } else if (weight > maxWeight) {
        anomalies.add(
          RecordingAnomaly(
            title: 'Bobot di Atas Standar',
            message:
                'Bobot $weight gram (${(weight / 1000).toStringAsFixed(2)} kg) terlalu berat untuk umur ${newRecording.day} hari (standar maksimal ~${maxWeight.toInt()} gram).',
            isBlocking: false,
          ),
        );
      }
    }

    // D. Pengecekan penurunan bobot dibanding recording hari sebelumnya
    final prevRecordings = existingRecordings
        .where((r) => _isDifferentRecord(r, newRecording) && r.day < newRecording.day)
        .toList();
    if (prevRecordings.isNotEmpty) {
      prevRecordings.sort((a, b) => b.day.compareTo(a.day));
      final lastRec = prevRecordings.first;
      if (lastRec.avgWeightGram > 0 && weight > 0) {
        if (weight < (lastRec.avgWeightGram * 0.80)) {
          anomalies.add(
            RecordingAnomaly(
              title: 'Penurunan Bobot Drastis',
              message:
                  'Bobot hari ke-${newRecording.day} ($weight g) turun drastis dibanding hari ke-${lastRec.day} (${lastRec.avgWeightGram} g). Pastikan sampel timbang sudah akurat.',
              isBlocking: false,
            ),
          );
        }
      }
    }

    // E. Pengecekan konsumsi pakan per ekor
    if (currentLivePopulation > 0 && newRecording.feedSack > 0) {
      final feedGramsTotal = newRecording.feedSack * 50 * 1000.0;
      final feedPerBirdGrams = feedGramsTotal / currentLivePopulation;

      if (feedPerBirdGrams > 300.0) {
        anomalies.add(
          RecordingAnomaly(
            title: 'Konsumsi Pakan Sangat Tinggi',
            message:
                'Konsumsi pakan tercatat ${feedPerBirdGrams.toStringAsFixed(0)} gram/ekor/hari (${newRecording.feedSack} sak untuk $currentLivePopulation ekor). Standar konsumsi maks ~220 g/ekor/hari.',
            isBlocking: false,
          ),
        );
      }
    }

    return anomalies;
  }
}
