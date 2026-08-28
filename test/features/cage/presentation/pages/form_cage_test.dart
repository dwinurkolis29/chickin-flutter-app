import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';
import 'package:recording_app/features/cage/presentation/pages/form_cage.dart';

class _FakeCageController extends ChangeNotifier implements CageController {
  CageData? savedData;

  @override
  Future<void> saveCageData(CageData cage) async {
    savedData = cage;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createWidgetUnderTest({CageData? initialCage, _FakeCageController? controller}) {
    final fakeCtrl = controller ?? _FakeCageController();

    return ChangeNotifierProvider<CageController>.value(
      value: fakeCtrl,
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: FormCage(cageData: initialCage),
      ),
    );
  }

  group('FormCage Widget Tests', () {
    testWidgets('menampilkan header panduan, field input kandang, dan tombol simpan', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialCage: const CageData(
          type: 'Closed House',
          capacity: 12000,
          location: 'Kecamatan Ciawi Blok B',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Spesifikasi Kandang'), findsOneWidget);
      expect(find.text('Spesifikasi Fisik Kandang'), findsOneWidget);
      expect(find.text('Model / Tipe Konstruksi Kandang'), findsOneWidget);
      expect(find.text('Kapasitas Maksimal (Ekor DOC)'), findsOneWidget);
      expect(find.text('Alamat & Lokasi Kandang'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });

    testWidgets('mode tambah kandang baru menampilkan judul dan tombol yang sesuai', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Tambah Data Kandang'), findsOneWidget);
      expect(find.text('Tambah Kandang Baru'), findsOneWidget);
    });
  });
}
