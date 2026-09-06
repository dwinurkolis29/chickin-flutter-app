import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/finance/data/models/finance_transaction.dart';
import 'package:recording_app/features/finance/domain/usecases/calculate_finance_summary.dart';

void main() {
  group('CalculateFinanceSummary', () {
    late CalculateFinanceSummary calculator;

    setUp(() {
      calculator = CalculateFinanceSummary();
    });

    test('kembalikan default empty summary jika transaksi kosong', () {
      final summary = calculator.execute(transactions: []);
      expect(summary.totalRevenue, 0.0);
      expect(summary.totalExpense, 0.0);
      expect(summary.netProfit, 0.0);
      expect(summary.hppPerKg, 0.0);
      expect(summary.feedExpensePct, 0.0);
      expect(summary.docExpensePct, 0.0);
      expect(summary.hasTransactions, false);
    });

    test('menghitung pendapatan, pengeluaran, laba bersih, dan persentase biaya dengan benar', () {
      final now = DateTime.now();
      final transactions = [
        // Pemasukan
        FinanceTransaction(
          id: 'tx-1',
          periodId: 'p-1',
          type: 'income',
          category: 'main_harvest',
          amount: 177120000.0,
          date: now,
          weightKg: 8500.0,
          birdCount: 4600,
          createdAt: now,
        ),
        FinanceTransaction(
          id: 'tx-2',
          periodId: 'p-1',
          type: 'income',
          category: 'reject',
          amount: 10380000.0,
          date: now,
          weightKg: 416.0,
          birdCount: 250,
          createdAt: now,
        ),
        // Pengeluaran
        FinanceTransaction(
          id: 'tx-3',
          periodId: 'p-1',
          type: 'expense',
          category: 'feed',
          amount: 76454000.0, // 60.2%
          date: now,
          createdAt: now,
        ),
        FinanceTransaction(
          id: 'tx-4',
          periodId: 'p-1',
          type: 'expense',
          category: 'doc',
          amount: 37465000.0, // 29.5%
          date: now,
          createdAt: now,
        ),
        FinanceTransaction(
          id: 'tx-5',
          periodId: 'p-1',
          type: 'expense',
          category: 'ovk',
          amount: 4953000.0, // 3.9%
          date: now,
          createdAt: now,
        ),
        FinanceTransaction(
          id: 'tx-6',
          periodId: 'p-1',
          type: 'expense',
          category: 'operational',
          amount: 8001000.0, // 6.3%
          date: now,
          createdAt: now,
        ),
      ];

      final summary = calculator.execute(transactions: transactions);

      // Pendapatan: 177,12 jt + 10,38 jt = 187,5 jt
      expect(summary.totalRevenue, 187500000.0);
      expect(summary.mainHarvestRevenue, 177120000.0);
      expect(summary.rejectRevenue, 10380000.0);

      // Pengeluaran: 76.454.000 + 37.465.000 + 4.953.000 + 8.001.000 = 126.873.000
      expect(summary.totalExpense, closeTo(126873000.0, 1.0));
      expect(summary.netProfit, closeTo(60627000.0, 1.0));

      // Persentase
      expect(summary.feedExpensePct, closeTo(60.2, 0.2));
      expect(summary.docExpensePct, closeTo(29.5, 0.2));
      expect(summary.ovkExpensePct, closeTo(3.9, 0.2));
      expect(summary.operationalExpensePct, closeTo(6.3, 0.2));

      // HPP: 126.873.000 / (8500 + 416 = 8916 kg) ≈ 14229.8
      expect(summary.totalHarvestWeightKg, 8916.0);
      expect(summary.hppPerKg, closeTo(14230.0, 10.0));
      expect(summary.totalChicksSold, 4850);
      expect(summary.hasTransactions, true);
    });

    test('menggunakan fallbackHarvestWeightKg jika transaksi penjualan tidak memiliki data bobot', () {
      final now = DateTime.now();
      final transactions = [
        FinanceTransaction(
          id: 'tx-1',
          periodId: 'p-1',
          type: 'expense',
          category: 'operational',
          amount: 10000000.0,
          date: now,
          createdAt: now,
        ),
      ];

      final summary = calculator.execute(
        transactions: transactions,
        fallbackHarvestWeightKg: 1000.0,
        fallbackHarvestedChicks: 500,
      );

      expect(summary.totalExpense, 10000000.0);
      expect(summary.hppPerKg, 10000.0);
      expect(summary.totalHarvestWeightKg, 1000.0);
      expect(summary.totalChicksSold, 500);
    });

    test('aman dari pembagian nol (zero-division safety) saat bobot 0', () {
      final now = DateTime.now();
      final transactions = [
        FinanceTransaction(
          id: 'tx-1',
          periodId: 'p-1',
          type: 'expense',
          category: 'operational',
          amount: 5000000.0,
          date: now,
          createdAt: now,
        ),
      ];

      final summary = calculator.execute(
        transactions: transactions,
        fallbackHarvestWeightKg: 0.0,
      );

      expect(summary.hppPerKg, 0.0);
    });
  });
}
