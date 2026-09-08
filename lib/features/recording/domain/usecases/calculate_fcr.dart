import 'package:recording_app/features/period/data/models/harvest_record.dart';
import 'package:recording_app/features/recording/data/models/daily_fcr_data.dart';
import 'package:recording_app/features/recording/data/models/fcr_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

/// Use case for calculating weekly FCR (Feed Conversion Ratio)
///
/// Formula: FCR = total pakan / total berat ayam hidup
/// Where:
///   - total pakan = cumulative feed consumed (kg)
///   - total berat ayam hidup = remaining chickens × average weight (kg)
///
/// Week logic: Day 1-7 = Week 1, Day 8-14 = Week 2, etc.
class CalculateFCR {
  /// Calculate weekly FCR data from recordings
  ///
  /// [recordings] - List of recording data (treated as immutable)
  /// [initialCapacity] - Initial chicken population from period data
  ///
  /// Returns cumulative FCR data per week
  List<FCRData> execute(
    List<RecordingData> recordings,
    int initialCapacity, {
    List<HarvestRecord>? harvests,
  }) {
    if (recordings.isEmpty || initialCapacity == 0) return [];

    // Sort by day (treat input as immutable - create new list)
    final sortedRecordings = List<RecordingData>.from(recordings)
      ..sort((a, b) => a.day.compareTo(b.day));

    // Find max week based on day (1-7 = week 1, 8-14 = week 2, etc.)
    final maxDay = sortedRecordings.last.day;
    final maxWeek = ((maxDay - 1) / 7).floor() + 1;

    List<FCRData> weeklyFCR = [];

    // Cumulative metrics
    int cumulativeDeaths = 0;
    double cumulativeFeedKg = 0.0;

    for (int week = 1; week <= maxWeek; week++) {
      // Week range: 1-7 for week 1, 8-14 for week 2, etc.
      final weekStartDay = (week - 1) * 7 + 1;
      final weekEndDay = week * 7;

      // Filter recordings for this week
      final weekRecordings =
          sortedRecordings.where((rec) {
            return rec.day >= weekStartDay && rec.day <= weekEndDay;
          }).toList();

      if (weekRecordings.isEmpty) continue;

      // Calculate cumulative feed and deaths for this week
      double weekFeedSacks = 0;
      int weekDeaths = 0;

      for (var rec in weekRecordings) {
        weekFeedSacks += rec.feedSack;
        weekDeaths += rec.mortality;
      }

      // Update cumulative totals
      cumulativeFeedKg += weekFeedSacks * 50; // 1 sack = 50 kg
      cumulativeDeaths += weekDeaths;

      // Perhitungkan panen parsial hingga akhir minggu ini
      final lastDayInWeek = weekRecordings.last.day;
      final harvestedChicksUpToWeek =
          harvests
              ?.where((h) => h.day <= lastDayInWeek)
              .fold(0, (sum, h) => sum + h.chicks) ??
          0;
      final harvestedWeightUpToWeek =
          harvests
              ?.where((h) => h.day <= lastDayInWeek)
              .fold(0.0, (sum, h) => sum + h.weightKg) ??
          0.0;

      // Sisa ayam di kandang
      final remainingChickens = (initialCapacity -
              cumulativeDeaths -
              harvestedChicksUpToWeek)
          .clamp(0, initialCapacity);
      if (remainingChickens <= 0 && harvestedChicksUpToWeek == 0) continue;

      // Get last day recording for current average weight
      final lastDayRecording = weekRecordings.last;
      final currentAvgWeightKg = lastDayRecording.avgWeightGram / 1000;

      // Biomassa di kandang + biomassa daging yang sudah dipanen
      final inHouseBiomass = remainingChickens * currentAvgWeightKg;
      final totalBiomass = inHouseBiomass + harvestedWeightUpToWeek;

      // Calculate FCR: total pakan / total biomassa kumulatif
      final fcr = totalBiomass > 0 ? cumulativeFeedKg / totalBiomass : 0.0;

      weeklyFCR.add(
        FCRData(
          mingguKe: week,
          totalPakan: double.parse(cumulativeFeedKg.toStringAsFixed(2)),
          sisaAyam: remainingChickens,
          beratAyam: double.parse(totalBiomass.toStringAsFixed(2)),
          fcr: double.parse(fcr.toStringAsFixed(2)),
        ),
      );
    }

    return weeklyFCR;
  }

  /// Calculate daily FCR data from recordings
  ///
  /// [recordings] - List of recording data (treated as immutable)
  /// [initialCapacity] - Initial chicken population from period data
  /// [harvests] - Opsional: daftar panen parsial untuk mengurangi sisa ayam
  ///
  /// Returns cumulative FCR metrics per recording day
  List<DailyFCRData> executeDaily(
    List<RecordingData> recordings,
    int initialCapacity, {
    List<HarvestRecord>? harvests,
  }) {
    if (recordings.isEmpty || initialCapacity == 0) return [];

    final sortedRecordings = List<RecordingData>.from(recordings)
      ..sort((a, b) => a.day.compareTo(b.day));

    final List<DailyFCRData> dailyList = [];
    int cumulativeDeaths = 0;
    double cumulativeFeedKg = 0.0;

    for (final rec in sortedRecordings) {
      final dailyFeedKg = rec.feedSack * 50.0;
      cumulativeFeedKg += dailyFeedKg;
      cumulativeDeaths += rec.mortality;

      final harvestedChicksUpToDay =
          harvests
              ?.where((h) => h.day <= rec.day)
              .fold(0, (sum, h) => sum + h.chicks) ??
          0;
      final harvestedWeightUpToDay =
          harvests
              ?.where((h) => h.day <= rec.day)
              .fold(0.0, (sum, h) => sum + h.weightKg) ??
          0.0;

      final remainingChickens = (initialCapacity -
              cumulativeDeaths -
              harvestedChicksUpToDay)
          .clamp(0, initialCapacity);
      final avgWeightKg = rec.avgWeightGram / 1000.0;
      final inHouseBiomassKg = remainingChickens * avgWeightKg;
      final totalBiomassKg = inHouseBiomassKg + harvestedWeightUpToDay;
      final fcr = totalBiomassKg > 0 ? cumulativeFeedKg / totalBiomassKg : 0.0;

      dailyList.add(
        DailyFCRData(
          day: rec.day,
          date: rec.createdAt,
          dailyFeedKg: double.parse(dailyFeedKg.toStringAsFixed(2)),
          cumulativeFeedKg: double.parse(cumulativeFeedKg.toStringAsFixed(2)),
          dailyMortality: rec.mortality,
          cumulativeMortality: cumulativeDeaths,
          sisaAyam: remainingChickens,
          avgWeightGram: rec.avgWeightGram,
          totalBiomassKg: double.parse(totalBiomassKg.toStringAsFixed(2)),
          fcr: double.parse(fcr.toStringAsFixed(2)),
        ),
      );
    }

    return dailyList;
  }

  /// Get age range string for a given week
  /// Week 1 = 1-7 days, Week 2 = 8-14 days, etc.
  String getWeekAgeRange(int week) {
    final startAge = (week - 1) * 7 + 1;
    final endAge = week * 7;
    return '$startAge-$endAge hari';
  }
}
