import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/components/dialogs/app_form_bottom_sheet.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';

void main() {
  Widget createTestWidget(void Function(BuildContext) onOpen) {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => onOpen(context),
              child: const Text('Buka Form Sheet'),
            ),
          ),
        ),
      ),
    );
  }

  group('AppFormBottomSheet Tests', () {
    testWidgets('menampilkan title, subtitle, icon, dan builder content', (tester) async {
      await tester.pumpWidget(
        createTestWidget((context) {
          AppFormBottomSheet.show(
            context: context,
            title: 'Judul Form Interaktif',
            subtitle: 'Ini adalah deskripsi bantuan form.',
            icon: Icons.edit_note_rounded,
            builder: (sheetContext, setModalState) {
              return const Column(
                children: [
                  Text('Isi Konten Form Reusable'),
                ],
              );
            },
          );
        }),
      );

      await tester.tap(find.text('Buka Form Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Judul Form Interaktif'), findsOneWidget);
      expect(find.text('Ini adalah deskripsi bantuan form.'), findsOneWidget);
      expect(find.text('Isi Konten Form Reusable'), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
    });

    testWidgets('menampilkan widget mandiri AppFormBottomSheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemeOption.light),
          home: const Scaffold(
            body: AppFormBottomSheet(
              title: 'Widget Statis',
              subtitle: 'Subjudul statis',
              icon: Icons.shield_outlined,
              content: Text('Konten statis'),
            ),
          ),
        ),
      );

      expect(find.text('Widget Statis'), findsOneWidget);
      expect(find.text('Subjudul statis'), findsOneWidget);
      expect(find.text('Konten statis'), findsOneWidget);
    });
  });
}
