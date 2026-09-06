import '../../data/models/finance_summary.dart';
import '../../data/models/finance_transaction.dart';

/// Usecase murni (pure function) untuk menghitung agregasi finansial dari daftar transaksi.
class CalculateFinanceSummary {
  FinanceSummary execute({
    required List<FinanceTransaction> transactions,
    double? fallbackHarvestWeightKg,
    int? fallbackHarvestedChicks,
  }) {
    if (transactions.isEmpty) {
      return const FinanceSummary();
    }

    double mainHarvestRevenue = 0.0;
    double rejectRevenue = 0.0;

    double feedExpense = 0.0;
    double docExpense = 0.0;
    double ovkExpense = 0.0;
    double operationalExpense = 0.0;

    double transHarvestWeight = 0.0;
    int transChicksSold = 0;

    for (final tx in transactions) {
      if (tx.isIncome) {
        if (tx.category == 'main_harvest') {
          mainHarvestRevenue += tx.amount;
        } else if (tx.category == 'reject') {
          rejectRevenue += tx.amount;
        } else {
          mainHarvestRevenue += tx.amount;
        }

        if (tx.weightKg != null && tx.weightKg! > 0) {
          transHarvestWeight += tx.weightKg!;
        }
        if (tx.birdCount != null && tx.birdCount! > 0) {
          transChicksSold += tx.birdCount!;
        }
      } else {
        if (tx.category == 'feed') {
          feedExpense += tx.amount;
        } else if (tx.category == 'doc') {
          docExpense += tx.amount;
        } else if (tx.category == 'ovk') {
          ovkExpense += tx.amount;
        } else {
          operationalExpense += tx.amount;
        }
      }
    }

    final totalRevenue = mainHarvestRevenue + rejectRevenue;
    final totalExpense = feedExpense + docExpense + ovkExpense + operationalExpense;
    final netProfit = totalRevenue - totalExpense;

    final effectiveWeightKg = transHarvestWeight > 0
        ? transHarvestWeight
        : (fallbackHarvestWeightKg ?? 0.0);

    final effectiveChicks = transChicksSold > 0
        ? transChicksSold
        : (fallbackHarvestedChicks ?? 0);

    final double hppPerKg = effectiveWeightKg > 0
        ? totalExpense / effectiveWeightKg
        : 0.0;

    final double feedExpensePct = totalExpense > 0
        ? (feedExpense / totalExpense) * 100.0
        : 0.0;
    final double docExpensePct = totalExpense > 0
        ? (docExpense / totalExpense) * 100.0
        : 0.0;
    final double ovkExpensePct = totalExpense > 0
        ? (ovkExpense / totalExpense) * 100.0
        : 0.0;
    final double operationalExpensePct = totalExpense > 0
        ? (operationalExpense / totalExpense) * 100.0
        : 0.0;

    return FinanceSummary(
      totalRevenue: totalRevenue,
      mainHarvestRevenue: mainHarvestRevenue,
      rejectRevenue: rejectRevenue,
      totalExpense: totalExpense,
      feedExpense: feedExpense,
      docExpense: docExpense,
      ovkExpense: ovkExpense,
      operationalExpense: operationalExpense,
      netProfit: netProfit,
      hppPerKg: hppPerKg,
      feedExpensePct: feedExpensePct,
      docExpensePct: docExpensePct,
      ovkExpensePct: ovkExpensePct,
      operationalExpensePct: operationalExpensePct,
      totalHarvestWeightKg: effectiveWeightKg,
      totalChicksSold: effectiveChicks,
    );
  }
}
