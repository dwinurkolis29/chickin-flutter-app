import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/finance/data/models/finance_summary.dart';
import 'package:recording_app/features/finance/data/models/finance_transaction.dart';
import 'package:recording_app/features/finance/domain/usecases/calculate_finance_summary.dart';
import 'package:recording_app/features/finance/presentation/controllers/finance_controller.dart';
import 'package:recording_app/features/finance/presentation/pages/finance_list_screen.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {
  @override
  Stream<List<FinanceTransaction>> getFinanceTransactionsStream(
    String periodId, [
    String? uid,
  ]) {
    return Stream.value([]);
  }
}

class _MockFinanceController extends FinanceController {
  final List<FinanceTransaction> _mockTransactions;
  final FinanceSummary _mockSummary;
  final bool _mockLoading;
  final String? _mockError;

  _MockFinanceController({
    List<FinanceTransaction>? transactions,
    FinanceSummary? summary,
    bool isLoading = false,
    String? errorMessage,
  })  : _mockTransactions = transactions ?? [],
        _mockSummary = summary ?? const FinanceSummary(),
        _mockLoading = isLoading,
        _mockError = errorMessage,
        super(
          firebaseService: _FakeFirebaseService(),
          calculateSummary: CalculateFinanceSummary(),
        );

  @override
  List<FinanceTransaction> get transactions => _mockTransactions;

  @override
  FinanceSummary get summary => _mockSummary;

  @override
  bool get isLoading => _mockLoading;

  @override
  String? get errorMessage => _mockError;

  @override
  void setPeriod(PeriodData period) {
    // No-op for mock
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final testPeriod = PeriodData(
    id: 'period-1',
    name: 'Batch 1 Test',
    initialCapacity: 5000,
    startDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
  );

  Widget createWidgetUnderTest(FinanceController controller) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FinanceController>.value(value: controller),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: FinanceListScreen(period: testPeriod),
      ),
    );
  }

  group('FinanceListScreen Widget Tests', () {
    testWidgets('menampilkan empty state jika belum ada transaksi', (tester) async {
      final ctrl = _MockFinanceController(transactions: []);

      await tester.pumpWidget(createWidgetUnderTest(ctrl));
      await tester.pumpAndSettle();

      expect(find.text('Keuangan Batch 1 Test'), findsOneWidget);
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Belum Ada Transaksi'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Catat Transaksi'), findsOneWidget);
    });

    testWidgets('menampilkan daftar kartu transaksi dengan AppCard dan nominal rapi', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sampleTx = [
        FinanceTransaction(
          id: 'tx-1',
          periodId: 'period-1',
          type: 'income',
          category: 'main_harvest',
          amount: 50000000,
          date: DateTime(2026, 1, 30),
          notes: 'Penjualan panen',
          createdAt: DateTime(2026, 1, 30),
        ),
        FinanceTransaction(
          id: 'tx-2',
          periodId: 'period-1',
          type: 'expense',
          category: 'feed',
          amount: 30000000,
          date: DateTime(2026, 1, 10),
          notes: 'Pakan starter',
          createdAt: DateTime(2026, 1, 10),
        ),
      ];

      final ctrl = _MockFinanceController(
        transactions: sampleTx,
        summary: const FinanceSummary(
          totalRevenue: 50000000,
          totalExpense: 30000000,
          netProfit: 20000000,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(ctrl));
      await tester.pumpAndSettle();

      // Memastikan AppCard ter-render untuk setiap transaksi
      expect(find.byType(AppCard), findsWidgets);

      // Verifikasi teks kategori & nominal
      expect(find.text('Penjualan Utama'), findsOneWidget);
      expect(find.text('Pakan'), findsOneWidget);
      expect(find.text('+Rp 50.000.000'), findsOneWidget);
      expect(find.text('-Rp 30.000.000'), findsOneWidget);

      // Verifikasi icon hapus transaksi
      expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));

      // Verifikasi Filter Chips & Hero metrics
      expect(find.text('Semua (2)'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsNWidgets(2));
      expect(find.text('Pemasukan'), findsOneWidget);
    });
  });
}
