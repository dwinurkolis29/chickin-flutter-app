import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/finance/data/models/finance_transaction.dart';
import 'package:recording_app/features/finance/presentation/controllers/finance_controller.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {
  final StreamController<List<FinanceTransaction>> _streamController =
      StreamController<List<FinanceTransaction>>.broadcast();
  final List<FinanceTransaction> createdTransactions = [];
  final List<String> deletedTransactionIds = [];

  @override
  Stream<List<FinanceTransaction>> getFinanceTransactionsStream(
    String periodId, [
    String? uid,
  ]) {
    return _streamController.stream;
  }

  @override
  Future<String> createFinanceTransaction(
    FinanceTransaction transaction, [
    String? uid,
  ]) async {
    createdTransactions.add(transaction);
    return 'tx-new-id';
  }

  @override
  Future<void> deleteFinanceTransaction(
    String periodId,
    String transactionId, [
    String? uid,
  ]) async {
    deletedTransactionIds.add(transactionId);
  }

  void emit(List<FinanceTransaction> items) {
    _streamController.add(items);
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  late _FakeFirebaseService fakeFirebase;
  late FinanceController controller;

  final testPeriod = PeriodData(
    id: 'p-1',
    name: 'Periode 1',
    initialCapacity: 1000,
    initialWeight: 0.04,
    startDate: DateTime(2026, 7, 1),
    createdAt: DateTime(2026, 7, 1),
  );

  setUp(() {
    fakeFirebase = _FakeFirebaseService();
    controller = FinanceController(firebaseService: fakeFirebase);
  });

  tearDown(() {
    fakeFirebase.dispose();
    controller.dispose();
  });

  group('FinanceController', () {
    test('initial state has empty transactions and summary', () {
      expect(controller.transactions, isEmpty);
      expect(controller.summary.totalExpense, 0.0);
      expect(controller.summary.totalRevenue, 0.0);
      expect(controller.isLoading, isFalse);
    });

    test('setPeriod triggers stream listen and calculates summary on emission', () async {
      controller.setPeriod(testPeriod);

      expect(controller.currentPeriod?.id, 'p-1');
      expect(controller.isLoading, isTrue);

      final now = DateTime(2026, 7, 10);
      final tx1 = FinanceTransaction(
        id: 't1',
        periodId: 'p-1',
        type: 'expense',
        category: 'feed',
        amount: 25000000,
        date: now,
        createdAt: now,
      );
      final tx2 = FinanceTransaction(
        id: 't2',
        periodId: 'p-1',
        type: 'income',
        category: 'main_harvest',
        amount: 50000000,
        date: DateTime(2026, 8, 5),
        createdAt: DateTime(2026, 8, 5),
      );

      fakeFirebase.emit([tx1, tx2]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isLoading, isFalse);
      expect(controller.transactions.length, 2);
      expect(controller.summary.totalExpense, 25000000);
      expect(controller.summary.totalRevenue, 50000000);
      expect(controller.summary.netProfit, 25000000);
    });

    test('addTransaction delegates to FirebaseService', () async {
      final now = DateTime(2026, 7, 1);
      final tx = FinanceTransaction(
        id: 't1',
        periodId: 'p-1',
        type: 'expense',
        category: 'doc',
        amount: 7000000,
        date: now,
        createdAt: now,
      );

      await controller.addTransaction(tx);

      expect(fakeFirebase.createdTransactions.length, 1);
      expect(fakeFirebase.createdTransactions.first.amount, 7000000);
    });

    test('deleteTransaction delegates to FirebaseService when currentPeriod is set', () async {
      controller.setPeriod(testPeriod);
      await controller.deleteTransaction('t1');

      expect(fakeFirebase.deletedTransactionIds, contains('t1'));
    });

    test('onAuthChanged resets state when uid changes', () async {
      controller.setPeriod(testPeriod);
      final now = DateTime(2026, 7, 2);
      fakeFirebase.emit([
        FinanceTransaction(
          id: 't1',
          periodId: 'p-1',
          type: 'expense',
          category: 'ovk',
          amount: 500000,
          date: now,
          createdAt: now,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.transactions.isNotEmpty, isTrue);

      // Auth changes to another user
      controller.onAuthChanged('different-uid');

      expect(controller.transactions, isEmpty);
      expect(controller.summary.totalExpense, 0.0);
    });
  });
}
