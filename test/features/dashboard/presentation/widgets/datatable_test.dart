import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/datatable.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

void main() {
  Widget createWidgetUnderTest({
    required List<RecordingData> chickenDataList,
    VoidCallback? onViewAll,
  }) {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChickenDataTable(
            chickenDataList: chickenDataList,
            onViewAll: onViewAll,
          ),
        ),
      ),
    );
  }

  group('ChickenDataTable Widget Tests', () {
    testWidgets('menampilkan Empty State jika chickenDataList kosong', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(chickenDataList: []));
      await tester.pumpAndSettle();

      expect(find.text('Recording Data'), findsOneWidget);
      expect(find.text('Belum Ada Data Recording'), findsOneWidget);
      expect(find.text('Data harian ayam akan muncul di sini'), findsOneWidget);
    });

    testWidgets('menampilkan maksimal 7 data terakhir diurutkan dari hari terbaru', (tester) async {
      final sampleData = List.generate(
        10,
        (i) => RecordingData(
          day: i + 1,
          avgWeightGram: (i + 1) * 100,
          feedSack: i + 1,
          mortality: i % 2 == 0 ? 0 : 2,
          createdAt: DateTime(2026, 1, i + 1),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(chickenDataList: sampleData));
      await tester.pumpAndSettle();

      expect(find.text('Recording Data'), findsOneWidget);
      expect(find.text('7 Data Terakhir'), findsOneWidget);

      // Hari 10, 9, 8, 7, 6, 5, 4 harus ada (7 data teratas)
      expect(find.text('H-10'), findsOneWidget);
      expect(find.text('H-9'), findsOneWidget);
      expect(find.text('H-8'), findsOneWidget);
      expect(find.text('H-7'), findsOneWidget);
      expect(find.text('H-6'), findsOneWidget);
      expect(find.text('H-5'), findsOneWidget);
      expect(find.text('H-4'), findsOneWidget);

      // Hari 1, 2, 3 tidak boleh tampil di 7 data terakhir
      expect(find.text('H-1'), findsNothing);
      expect(find.text('H-2'), findsNothing);
      expect(find.text('H-3'), findsNothing);
    });

    testWidgets('memanggil onViewAll saat tombol Lihat Semua ditekan', (tester) async {
      bool viewAllCalled = false;

      await tester.pumpWidget(createWidgetUnderTest(
        chickenDataList: [
          RecordingData(
            day: 1,
            avgWeightGram: 150,
            feedSack: 2,
            mortality: 0,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        onViewAll: () => viewAllCalled = true,
      ));
      await tester.pumpAndSettle();

      final viewAllBtn = find.text('Lihat Semua');
      expect(viewAllBtn, findsOneWidget);

      await tester.tap(viewAllBtn);
      await tester.pumpAndSettle();

      expect(viewAllCalled, isTrue);
    });
  });
}
