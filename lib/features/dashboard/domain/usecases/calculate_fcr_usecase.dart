import 'package:recording_app/features/dashboard/data/models/fcr_data.dart';
import 'package:recording_app/features/dashboard/data/models/recording_data.dart';

/// Use case for calculating weekly FCR (Feed Conversion Ratio)
/// 
/// Formula: FCR = total pakan / total berat ayam hidup
/// Where:
///   - total pakan = cumulative feed consumed (kg)
///   - total berat ayam hidup = remaining chickens × average weight (kg)
/// 
/// Week logic: Day 1-7 = Week 1, Day 8-14 = Week 2, etc.
class CalculateFCRUseCase {
  
  /// Calculate weekly FCR data from recordings
  /// 
  /// [recordings] - List of recording data (treated as immutable)
  /// [initialCapacity] - Initial chicken population from period data
  /// 
  /// Returns cumulative FCR data per week
  List<FCRData> execute(List<RecordingData> recordings, int initialCapacity) {
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
      final weekRecordings = sortedRecordings.where((rec) {
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

      // Calculate remaining chickens
      final remainingChickens = initialCapacity - cumulativeDeaths;
      if (remainingChickens <= 0) continue;

      // Get last day recording for current average weight
      final lastDayRecording = weekRecordings.last;
      final currentAvgWeightKg = lastDayRecording.avgWeightGram / 1000;
      
      // Calculate total weight / final biomass (kg)
      // Total berat ayam hidup = sisa ayam × berat rata-rata
      final finalBiomass = remainingChickens * currentAvgWeightKg;

      // Calculate FCR: total pakan / total berat ayam hidup
      final fcr = finalBiomass > 0 ? cumulativeFeedKg / finalBiomass : 0;

      weeklyFCR.add(FCRData(
        mingguKe: week,
        totalPakan: double.parse(cumulativeFeedKg.toStringAsFixed(2)),
        sisaAyam: remainingChickens,
        beratAyam: double.parse(finalBiomass.toStringAsFixed(2)),
        fcr: double.parse(fcr.toStringAsFixed(2)),
      ));
    }

    return weeklyFCR;
  }

  /// Get age range string for a given week
  /// Week 1 = 1-7 days, Week 2 = 8-14 days, etc.
  String getWeekAgeRange(int week) {
    final startAge = (week - 1) * 7 + 1;
    final endAge = week * 7;
    return '$startAge-$endAge hari';
  }
}
