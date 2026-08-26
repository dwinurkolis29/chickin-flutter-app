import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';

void main() {
  Widget createWidgetUnderTest({
    required String title,
    bool isHome = false,
    List<Widget>? actions,
  }) {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: Scaffold(
        appBar: AppHeader(
          title: title,
          isHome: isHome,
          actions: actions,
        ),
      ),
    );
  }

  group('AppHeader Widget Tests', () {
    testWidgets('menampilkan title dan actions dengan benar', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          title: 'Judul Halaman',
          isHome: true,
          actions: const [
            Icon(Icons.more_vert, key: Key('test_action')),
          ],
        ),
      );

      expect(find.text('Judul Halaman'), findsOneWidget);
      expect(find.byKey(const Key('test_action')), findsOneWidget);
      // isHome = true -> tidak ada back button
      expect(find.byIcon(Icons.chevron_left), findsNothing);
    });

    testWidgets('menampilkan back button IconButton saat navigator canPop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemeOption.light),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          appBar: AppHeader(title: 'Sub Page'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Go to Sub Page'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap to navigate to sub page
      await tester.tap(find.text('Go to Sub Page'));
      await tester.pumpAndSettle();

      // Memastikan title dan back button tampil
      expect(find.text('Sub Page'), findsOneWidget);
      final backButtonFinder = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Kembali',
      );
      expect(backButtonFinder, findsOneWidget);

      // Back button icon size adalah 24
      final iconFinder = find.byIcon(Icons.chevron_left);
      expect(iconFinder, findsOneWidget);
      final Icon iconWidget = tester.widget(iconFinder);
      expect(iconWidget.size, equals(24.0));

      // Tap back button
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // Kembali ke home page
      expect(find.text('Go to Sub Page'), findsOneWidget);
    });
  });
}
