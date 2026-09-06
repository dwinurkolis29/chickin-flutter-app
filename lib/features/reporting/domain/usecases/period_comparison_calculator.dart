import 'package:intl/intl.dart';
import 'package:recording_app/features/finance/data/models/finance_summary.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';

/// Ringkasan delta perbandingan metrik antara periode saat ini dengan periode sebelumnya
class PeriodDeltaComparison {
  final String? previousPeriodName;

  // Delta Values
  final double deltaNetProfit;
  final double deltaMortalityPct;
  final double deltaWeightKg;
  final double deltaFcr;
  final double deltaHpp;

  // Formatted Strings for display (e.g. "↑ Rp8,5 jt", "↓ 0,5%", "↑ 0,08", "↓ 0,03")
  final String netProfitText;
  final String netProfitDeltaText;
  final bool isProfitImproved;

  final String mortalityText;
  final String mortalityDeltaText;
  final bool isMortalityImproved;

  final String weightText;
  final String weightDeltaText;
  final bool isWeightImproved;

  final String fcrText;
  final String fcrDeltaText;
  final bool isFcrImproved;

  final String hppText;
  final String hppComparisonLabel;

  // 3-Period Trend
  final String threePeriodSequence; // e.g. "P10 → P11 → P12"
  final String threePeriodTrendSummary; // e.g. "laba ↑ | mortalitas ↓ | FCR ↓"

  // Insight Bullets
  final List<String> periodInsights;

  const PeriodDeltaComparison({
    this.previousPeriodName,
    this.deltaNetProfit = 0.0,
    this.deltaMortalityPct = 0.0,
    this.deltaWeightKg = 0.0,
    this.deltaFcr = 0.0,
    this.deltaHpp = 0.0,
    required this.netProfitText,
    required this.netProfitDeltaText,
    this.isProfitImproved = true,
    required this.mortalityText,
    required this.mortalityDeltaText,
    this.isMortalityImproved = true,
    required this.weightText,
    required this.weightDeltaText,
    this.isWeightImproved = true,
    required this.fcrText,
    required this.fcrDeltaText,
    this.isFcrImproved = true,
    required this.hppText,
    required this.hppComparisonLabel,
    required this.threePeriodSequence,
    required this.threePeriodTrendSummary,
    this.periodInsights = const [],
  });
}

/// Helper untuk format rupiah ringkas: e.g. 60.500.000 -> "Rp60,5 JT", 8.500.000 -> "Rp8,5 jt"
String formatCompactRupiah(double amount, {bool uppercase = false}) {
  final abs = amount.abs();
  final suffix = uppercase ? 'JT' : 'jt';
  if (abs >= 1000000000) {
    final val = amount / 1000000000.0;
    return 'Rp${val.toStringAsFixed(2).replaceAll('.', ',')} M';
  } else if (abs >= 1000000) {
    final val = amount / 1000000.0;
    return 'Rp${val.toStringAsFixed(1).replaceAll('.', ',')} $suffix';
  } else if (abs > 0) {
    final numFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return numFmt.format(amount);
  }
  return 'Rp0';
}

/// Usecase murni (pure calculator) untuk komparasi periode dan tren multi-periode
class PeriodComparisonCalculator {
  PeriodDeltaComparison execute({
    required PeriodReport currentReport,
    required FinanceSummary currentFinance,
    PeriodReport? previousReport,
    FinanceSummary? previousFinance,
    List<PeriodData> recentPeriods = const [],
    Map<String, FinanceSummary> pastFinanceMap = const {},
  }) {
    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    // 1. Current values
    final currentProfit = currentFinance.netProfit;
    final currentMortality = currentReport.mortalityRate;
    final currentWeightKg = currentReport.finalAvgWeightGram / 1000.0;
    final currentFcr = currentReport.fcr;
    final currentHpp = currentFinance.hppPerKg;

    final profitText = currentFinance.hasTransactions
        ? formatCompactRupiah(currentProfit, uppercase: true)
        : 'Rp0 (Belum Dicatat)';
    final mortalityText = '${currentMortality.toStringAsFixed(1).replaceAll('.', ',')}%';
    final weightText = '${currentWeightKg.toStringAsFixed(2).replaceAll('.', ',')} KG';
    final fcrText = currentFcr > 0 ? currentFcr.toStringAsFixed(2).replaceAll('.', ',') : '-';
    final hppText = currentHpp > 0
        ? 'HPP ${currencyFmt.format(currentHpp)}/kg'
        : 'HPP -';

    // 2. Previous values & Deltas
    double deltaProfit = 0.0;
    double deltaMortality = 0.0;
    double deltaWeight = 0.0;
    double deltaFcr = 0.0;
    double deltaHpp = 0.0;

    String profitDeltaText = '-';
    String mortalityDeltaText = '-';
    String weightDeltaText = '-';
    String fcrDeltaText = '-';
    String hppComparisonLabel = 'Periode Pertama';

    bool isProfitBetter = true;
    bool isMortalityBetter = true;
    bool isWeightBetter = true;
    bool isFcrBetter = true;

    final prevPeriodName = previousReport?.period.name;

    if (previousReport != null) {
      final prevProfit = previousFinance?.netProfit ?? 0.0;
      final prevMortality = previousReport.mortalityRate;
      final prevWeightKg = previousReport.finalAvgWeightGram / 1000.0;
      final prevFcr = previousReport.fcr;
      final prevHpp = previousFinance?.hppPerKg ?? 0.0;

      deltaProfit = currentProfit - prevProfit;
      deltaMortality = currentMortality - prevMortality;
      deltaWeight = currentWeightKg - prevWeightKg;
      deltaFcr = currentFcr - prevFcr;
      deltaHpp = currentHpp - prevHpp;

      hppComparisonLabel = 'dibanding ${prevPeriodName ?? 'P Sebelumnya'}';

      // Format Profit Delta
      if (currentFinance.hasTransactions && (previousFinance?.hasTransactions ?? false)) {
        final arrow = deltaProfit >= 0 ? '↑' : '↓';
        profitDeltaText = '$arrow ${formatCompactRupiah(deltaProfit.abs())}';
        isProfitBetter = deltaProfit >= 0;
      } else {
        profitDeltaText = '-';
      }

      // Format Mortality Delta (Mortalitas turun = lebih bagus)
      final mortArrow = deltaMortality <= 0 ? '↓' : '↑';
      mortalityDeltaText = '$mortArrow ${deltaMortality.abs().toStringAsFixed(1).replaceAll('.', ',')}%';
      isMortalityBetter = deltaMortality <= 0;

      // Format Weight Delta (Bobot naik = lebih bagus)
      final weightArrow = deltaWeight >= 0 ? '↑' : '↓';
      weightDeltaText = '$weightArrow ${deltaWeight.abs().toStringAsFixed(2).replaceAll('.', ',')}';
      isWeightBetter = deltaWeight >= 0;

      // Format FCR Delta (FCR turun = lebih efisien)
      if (currentFcr > 0 && prevFcr > 0) {
        final fcrArrow = deltaFcr <= 0 ? '↓' : '↑';
        fcrDeltaText = '$fcrArrow ${deltaFcr.abs().toStringAsFixed(2).replaceAll('.', ',')}';
        isFcrBetter = deltaFcr <= 0;
      } else {
        fcrDeltaText = '-';
      }
    }

    // 3. Insight Bullets
    final insights = <String>[];
    if (previousReport != null) {
      if (isFcrBetter && isMortalityBetter) {
        insights.add('✓ Kinerja periode membaik dibanding siklus sebelumnya');
      }
      if (isFcrBetter && currentFcr > 0) {
        insights.add('✓ FCR semakin efisien (${currentFcr.toStringAsFixed(2)})');
      } else if (!isFcrBetter && currentFcr > 0) {
        insights.add('⚠ FCR meningkat dibanding siklus sebelumnya');
      }

      if (isMortalityBetter) {
        insights.add('✓ Mortalitas menurun menjadi ${currentMortality.toStringAsFixed(1)}%');
      } else {
        insights.add('⚠ Mortalitas meningkat (${currentMortality.toStringAsFixed(1)}%) — cek biosekuriti');
      }
    } else {
      if (currentFcr > 0 && currentFcr <= 1.80) {
        insights.add('✓ FCR efisien (${currentFcr.toStringAsFixed(2)}) sesuai standar broiler komersial');
      }
      if (currentMortality <= 5.0) {
        insights.add('✓ Mortalitas rendah (${currentMortality.toStringAsFixed(1)}%) — kesehatan ayam terjaga');
      }
    }

    // Insight tambahan dari catatan harian jika ada (misal lonjakan mortalitas)
    if (currentReport.recordings.isNotEmpty) {
      int highestMortDay = 1;
      int highestMortCount = 0;
      for (final r in currentReport.recordings) {
        if (r.mortality > highestMortCount) {
          highestMortCount = r.mortality;
          highestMortDay = r.day;
        }
      }
      if (highestMortCount > 10) {
        final weekNum = ((highestMortDay - 1) ~/ 7) + 1;
        insights.add('⚠ Mortalitas tertinggi tercatat pada minggu ke-$weekNum (Hari $highestMortDay)');
      }
    }

    // 4. Tren 3 Periode
    String sequenceStr = currentReport.period.name;
    String trendStr = 'Periode Pertama';

    if (recentPeriods.isNotEmpty) {
      // Ambil hingga 3 periode terakhir (diurutkan kronologis)
      final sortedRecent = List<PeriodData>.from(recentPeriods)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      final lastThree = sortedRecent.length > 3
          ? sortedRecent.sublist(sortedRecent.length - 3)
          : sortedRecent;

      sequenceStr = lastThree.map((p) => p.name).join(' → ');

      if (lastThree.length >= 2) {
        final first = lastThree.first;
        final last = lastThree.last;

        final firstProfit = pastFinanceMap[first.id]?.netProfit ?? 0.0;
        final lastProfit = (last.id == currentReport.period.id)
            ? currentProfit
            : (pastFinanceMap[last.id]?.netProfit ?? 0.0);

        final firstFcr = first.summary?.finalFCR ?? 0.0;
        final lastFcr = (last.id == currentReport.period.id)
            ? currentFcr
            : (last.summary?.finalFCR ?? 0.0);

        final firstMort = (first.initialCapacity > 0 && first.summary != null)
            ? (first.summary!.totalMortality / first.initialCapacity) * 100.0
            : 0.0;
        final lastMort = (last.id == currentReport.period.id)
            ? currentMortality
            : ((last.initialCapacity > 0 && last.summary != null)
                ? (last.summary!.totalMortality / last.initialCapacity) * 100.0
                : 0.0);

        final profitArrow = lastProfit >= firstProfit ? '↑' : '↓';
        final mortArrow = lastMort <= firstMort ? '↓' : '↑';
        final fcrArrow = lastFcr <= firstFcr ? '↓' : '↑';

        trendStr = 'laba $profitArrow | mortalitas $mortArrow | FCR $fcrArrow';
      }
    }

    return PeriodDeltaComparison(
      previousPeriodName: prevPeriodName,
      deltaNetProfit: deltaProfit,
      deltaMortalityPct: deltaMortality,
      deltaWeightKg: deltaWeight,
      deltaFcr: deltaFcr,
      deltaHpp: deltaHpp,
      netProfitText: profitText,
      netProfitDeltaText: profitDeltaText,
      isProfitImproved: isProfitBetter,
      mortalityText: mortalityText,
      mortalityDeltaText: mortalityDeltaText,
      isMortalityImproved: isMortalityBetter,
      weightText: weightText,
      weightDeltaText: weightDeltaText,
      isWeightImproved: isWeightBetter,
      fcrText: fcrText,
      fcrDeltaText: fcrDeltaText,
      isFcrImproved: isFcrBetter,
      hppText: hppText,
      hppComparisonLabel: hppComparisonLabel,
      threePeriodSequence: sequenceStr,
      threePeriodTrendSummary: trendStr,
      periodInsights: insights,
    );
  }
}
