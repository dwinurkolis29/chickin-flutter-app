import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../period/data/models/period_data.dart';
import '../../data/models/finance_summary.dart';
import '../../data/models/finance_transaction.dart';
import '../../domain/usecases/calculate_finance_summary.dart';

class FinanceController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final CalculateFinanceSummary _calculateSummary;

  FinanceController({
    FirebaseService? firebaseService,
    CalculateFinanceSummary? calculateSummary,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _calculateSummary = calculateSummary ?? CalculateFinanceSummary();

  String? _uid;
  PeriodData? _currentPeriod;
  List<FinanceTransaction> _transactions = [];
  FinanceSummary _summary = const FinanceSummary();
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<FinanceTransaction>>? _subscription;

  // Getters
  PeriodData? get currentPeriod => _currentPeriod;
  List<FinanceTransaction> get transactions => _transactions;
  FinanceSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void onAuthChanged(String? uid) {
    if (_uid != uid) {
      _uid = uid;
      _subscription?.cancel();
      _transactions = [];
      _summary = const FinanceSummary();
      if (_uid != null && _currentPeriod != null) {
        _listenTransactions(_currentPeriod!.id);
      }
      notifyListeners();
    }
  }

  void setPeriod(PeriodData period) {
    if (_currentPeriod?.id == period.id) {
      _currentPeriod = period;
      _recalculate();
      notifyListeners();
      return;
    }

    _currentPeriod = period;
    _listenTransactions(period.id);
  }

  void _listenTransactions(String periodId) {
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscription = _firebaseService
          .getFinanceTransactionsStream(periodId, _uid)
          .listen(
        (txList) {
          _transactions = txList;
          _isLoading = false;
          _errorMessage = null;
          _recalculate();
          notifyListeners();
        },
        onError: (e) {
          _isLoading = false;
          _errorMessage = e.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _recalculate() {
    _summary = _calculateSummary.execute(
      transactions: _transactions,
      fallbackHarvestWeightKg: _currentPeriod?.summary?.harvestedWeightKg ??
          _currentPeriod?.summary?.finalBiomass,
      fallbackHarvestedChicks: _currentPeriod?.summary?.harvestedChicks ??
          _currentPeriod?.summary?.finalPopulation,
    );
  }

  Future<void> addTransaction(FinanceTransaction tx) async {
    try {
      await _firebaseService.createFinanceTransaction(tx, _uid);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (_currentPeriod == null) return;
    try {
      await _firebaseService.deleteFinanceTransaction(
        _currentPeriod!.id,
        transactionId,
        _uid,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
