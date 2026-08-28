import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';
import 'package:recording_app/features/cage/presentation/pages/cage_profile.dart';

class _FakeCageController extends ChangeNotifier implements CageController {
  final CageData? _cageData;
  final bool _isLoading;
  final String? _errorMessage;

  _FakeCageController({
    CageData? cageData,
    bool isLoading = false,
    String? errorMessage,
  })  : _cageData = cageData,
        _isLoading = isLoading,
        _errorMessage = errorMessage;

  @override
  CageData? get cageData => _cageData;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isUploadingImage => false;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<void> loadCageData([String? uid]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createWidgetUnderTest({_FakeCageController? controller}) {
    final fakeCtrl = controller ??
        _FakeCageController(
          cageData: const CageData(
            type: 'Closed House (Modern)',
            capacity: 10000,
            location: 'Kecamatan Ciawi, Blok A No. 12',
          ),
        );

    return ChangeNotifierProvider<CageController>.value(
      value: fakeCtrl,
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: const CageProfile(),
      ),
    );
  }

  group('CageProfile Widget Tests', () {
    testWidgets('menampilkan foto landscape, kapasitas hero, spesifikasi dan tombol edit', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Header & Title
      expect(find.text('Profil Kandang'), findsOneWidget);

      // Hero Landscape Banner
      expect(find.text('Foto Tampak Kandang'), findsOneWidget);
      expect(find.text('Unggah Foto'), findsOneWidget);

      // Hero Kapasitas
      expect(find.text('Kapasitas Maksimal'), findsOneWidget);
      expect(find.text('10.000'), findsOneWidget);
      expect(find.text('Ekor DOC'), findsOneWidget);

      // Spesifikasi Konstruksi & Lokasi
      expect(find.text('Spesifikasi Bangunan & Lokasi'), findsOneWidget);
      expect(find.text('Closed House (Modern)'), findsOneWidget);
      expect(find.text('Kecamatan Ciawi, Blok A No. 12'), findsOneWidget);

      // Tombol Utama
      expect(find.text('Ubah Spesifikasi Kandang'), findsOneWidget);
    });

    testWidgets('menampilkan empty state jika belum ada data kandang', (tester) async {
      final fakeCtrl = _FakeCageController(
        cageData: const CageData(type: '', capacity: 0, location: ''),
      );

      await tester.pumpWidget(createWidgetUnderTest(controller: fakeCtrl));
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Data Kandang'), findsOneWidget);
      expect(find.text('Tambah Data Kandang Sekarang'), findsOneWidget);
    });
  });
}
