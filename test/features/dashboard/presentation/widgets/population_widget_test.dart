import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/population_widget.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createWidgetUnderTest({
    required int populationRemain,
    required int capacity,
  }) {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: PopulationSection(
            populationRemain: populationRemain,
            capacity: capacity,
          ),
        ),
      ),
    );
  }

  group('PopulationSection Widget Tests', () {
    testWidgets('menampilkan metrik populasi dan kelangsungan hidup dengan benar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        populationRemain: 2988,
        capacity: 3000,
      ));
      await tester.pumpAndSettle();

      // Judul Card
      expect(find.text('Populasi Ayam'), findsOneWidget);
      expect(find.text('Ayam Hidup'), findsOneWidget);
      expect(find.text('Ekor'), findsOneWidget);

      // Angka Terformat
      expect(find.text('2.988'), findsOneWidget);

      // Survival & Badge Sangat Baik
      expect(find.text('99.6%'), findsOneWidget);
      expect(find.text('Survival'), findsOneWidget);
      expect(find.text('Sangat Baik'), findsOneWidget);
    });

    testWidgets('menampilkan status Perhatian jika survival rate antara 90% - 95%', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        populationRemain: 2750,
        capacity: 3000,
      ));
      await tester.pumpAndSettle();

      expect(find.text('2.750'), findsOneWidget);
      expect(find.text('91.7%'), findsOneWidget);
      expect(find.text('Perhatian'), findsOneWidget);
    });

    testWidgets('menangani kapasitas 0 dengan aman tanpa error', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        populationRemain: 0,
        capacity: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
    });
  });
}
