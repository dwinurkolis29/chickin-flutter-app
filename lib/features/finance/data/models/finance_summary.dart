import '../../../../core/models/safe_convert.dart';

/// Ringkasan agregat finansial suatu periode pemeliharaan ayam broiler
class FinanceSummary {
  final double totalRevenue;
  final double mainHarvestRevenue;
  final double rejectRevenue;

  final double totalExpense;
  final double feedExpense;
  final double docExpense;
  final double ovkExpense;
  final double operationalExpense;

  final double netProfit;
  final double hppPerKg;

  final double feedExpensePct;
  final double docExpensePct;
  final double ovkExpensePct;
  final double operationalExpensePct;

  final double totalHarvestWeightKg;
  final int totalChicksSold;

  const FinanceSummary({
    this.totalRevenue = 0.0,
    this.mainHarvestRevenue = 0.0,
    this.rejectRevenue = 0.0,
    this.totalExpense = 0.0,
    this.feedExpense = 0.0,
    this.docExpense = 0.0,
    this.ovkExpense = 0.0,
    this.operationalExpense = 0.0,
    this.netProfit = 0.0,
    this.hppPerKg = 0.0,
    this.feedExpensePct = 0.0,
    this.docExpensePct = 0.0,
    this.ovkExpensePct = 0.0,
    this.operationalExpensePct = 0.0,
    this.totalHarvestWeightKg = 0.0,
    this.totalChicksSold = 0,
  });

  bool get hasTransactions => totalRevenue > 0 || totalExpense > 0;

  factory FinanceSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const FinanceSummary();
    }

    return FinanceSummary(
      totalRevenue: asDouble(json, 'totalRevenue'),
      mainHarvestRevenue: asDouble(json, 'mainHarvestRevenue'),
      rejectRevenue: asDouble(json, 'rejectRevenue'),
      totalExpense: asDouble(json, 'totalExpense'),
      feedExpense: asDouble(json, 'feedExpense'),
      docExpense: asDouble(json, 'docExpense'),
      ovkExpense: asDouble(json, 'ovkExpense'),
      operationalExpense: asDouble(json, 'operationalExpense'),
      netProfit: asDouble(json, 'netProfit'),
      hppPerKg: asDouble(json, 'hppPerKg'),
      feedExpensePct: asDouble(json, 'feedExpensePct'),
      docExpensePct: asDouble(json, 'docExpensePct'),
      ovkExpensePct: asDouble(json, 'ovkExpensePct'),
      operationalExpensePct: asDouble(json, 'operationalExpensePct'),
      totalHarvestWeightKg: asDouble(json, 'totalHarvestWeightKg'),
      totalChicksSold: asInt(json, 'totalChicksSold'),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalRevenue': totalRevenue,
    'mainHarvestRevenue': mainHarvestRevenue,
    'rejectRevenue': rejectRevenue,
    'totalExpense': totalExpense,
    'feedExpense': feedExpense,
    'docExpense': docExpense,
    'ovkExpense': ovkExpense,
    'operationalExpense': operationalExpense,
    'netProfit': netProfit,
    'hppPerKg': hppPerKg,
    'feedExpensePct': feedExpensePct,
    'docExpensePct': docExpensePct,
    'ovkExpensePct': ovkExpensePct,
    'operationalExpensePct': operationalExpensePct,
    'totalHarvestWeightKg': totalHarvestWeightKg,
    'totalChicksSold': totalChicksSold,
  };
}
