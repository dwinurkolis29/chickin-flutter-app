import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: Scaffold(body: child),
    );
  }

  group('AppEmptyState Widget Tests', () {
    testWidgets('menampilkan icon, title, subtitle, dan tombol aksi standar', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          AppEmptyState(
            icon: Icons.calendar_today_outlined,
            message: 'Tidak Ada Periode Aktif',
            subtitle: 'Mulai siklus pemeliharaan baru untuk mencatat harian.',
            actionLabel: 'Mulai Siklus Baru',
            onAction: () => actionTriggered = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.text('Tidak Ada Periode Aktif'), findsOneWidget);
      expect(find.text('Mulai siklus pemeliharaan baru untuk mencatat harian.'), findsOneWidget);
      expect(find.text('Mulai Siklus Baru'), findsOneWidget);

      await tester.tap(find.text('Mulai Siklus Baru'));
      await tester.pumpAndSettle();
      expect(actionTriggered, isTrue);
    });

    testWidgets('mendukung mode compact dan custom action widget', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          AppEmptyState(
            icon: Icons.layers_outlined,
            message: 'Data Kosong',
            compact: true,
            action: ElevatedButton(
              onPressed: () {},
              child: const Text('Aksi Kustom'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Kosong'), findsOneWidget);
      expect(find.text('Aksi Kustom'), findsOneWidget);
    });
  });
}
