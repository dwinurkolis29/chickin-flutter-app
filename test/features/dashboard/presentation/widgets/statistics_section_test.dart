import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/statistics_section.dart';

void main() {
  Widget createWidgetUnderTest({
    required double fcr,
    required int umur,
    Stream<List<FlSpot>>? weightStream,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: StatisticsSection(
            fcr: fcr,
            umur: umur,
            weightStream: weightStream,
          ),
        ),
      ),
    );
  }

  group('StatisticsSection Widget Tests', () {
    testWidgets('menampilkan FCR dan Umur Ayam dengan benar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        fcr: 1.45,
        umur: 21,
        weightStream: Stream.value([
          const FlSpot(1, 45),
          const FlSpot(2, 60),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Umur\nAyam'), findsOneWidget);
      expect(find.text('21'), findsOneWidget);
      expect(find.text('FCR'), findsOneWidget);
      expect(find.text('1.45'), findsOneWidget);
      expect(find.text('Bobot Ayam'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      expect(find.text('+15 g'), findsOneWidget);
    });

    testWidgets('menampilkan warna hijau ketika bobot naik', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        fcr: 1.40,
        umur: 15,
        weightStream: Stream.value([
          const FlSpot(1, 100),
          const FlSpot(2, 150),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('+50 g'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final barData = lineChart.data.lineBarsData.first;
      expect(barData.color, equals(AppColors.success));
    });

    testWidgets('menampilkan warna merah ketika bobot turun', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        fcr: 1.55,
        umur: 16,
        weightStream: Stream.value([
          const FlSpot(1, 150),
          const FlSpot(2, 140),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('-10 g'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final barData = lineChart.data.lineBarsData.first;
      expect(barData.color, equals(AppColors.error));
    });

    testWidgets('menampilkan warna merah ketika bobot stagnan / tidak ada kenaikan', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        fcr: 1.50,
        umur: 17,
        weightStream: Stream.value([
          const FlSpot(1, 150),
          const FlSpot(2, 150),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0 g'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final barData = lineChart.data.lineBarsData.first;
      expect(barData.color, equals(AppColors.error));
    });
  });
}
