import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

void main() {
  Widget createTestWidget(void Function(BuildContext) onOpen) {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => onOpen(context),
              child: const Text('Buka Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  group('DialogHelper & Unified Dialogs Tests', () {
    testWidgets('showError menampilkan judul, pesan, dan icon error konsisten', (tester) async {
      await tester.pumpWidget(
        createTestWidget((context) {
          DialogHelper.showError(
            context,
            'Terjadi Kesalahan',
            'Data gagal disimpan ke server.',
          );
        }),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Terjadi Kesalahan'), findsOneWidget);
      expect(find.text('Data gagal disimpan ke server.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      expect(find.text('Terjadi Kesalahan'), findsNothing);
    });

    testWidgets('showInfo menampilkan judul, pesan, dan icon info konsisten', (tester) async {
      await tester.pumpWidget(
        createTestWidget((context) {
          DialogHelper.showInfo(
            context,
            'Informasi Siklus',
            'Siklus pemeliharaan saat ini telah mencapai 21 hari.',
          );
        }),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Informasi Siklus'), findsOneWidget);
      expect(find.text('Siklus pemeliharaan saat ini telah mencapai 21 hari.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('Informasi Siklus'), findsNothing);
    });

    testWidgets('showSuccess menampilkan judul, pesan, dan icon check sukses', (tester) async {
      await tester.pumpWidget(
        createTestWidget((context) {
          DialogHelper.showSuccess(
            context,
            'Berhasil Disimpan',
            'Catatan recording hari ini telah tercatat.',
          );
        }),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Berhasil Disimpan'), findsOneWidget);
      expect(find.text('Catatan recording hari ini telah tercatat.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      expect(find.text('Berhasil Disimpan'), findsNothing);
    });

    testWidgets('showConfirm mengembalikan nilai true saat tombol konfirmasi ditekan', (tester) async {
      bool? confirmResult;
      await tester.pumpWidget(
        createTestWidget((context) async {
          confirmResult = await DialogHelper.showConfirm(
            context,
            'Tutup Periode',
            'Apakah Anda yakin ingin menutup periode aktif ini?',
            confirmText: 'Ya, Tutup',
            cancelText: 'Batal',
            isDestructive: true,
          );
        }),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Tutup Periode'), findsOneWidget);
      expect(find.text('Apakah Anda yakin ingin menutup periode aktif ini?'), findsOneWidget);
      expect(find.text('Ya, Tutup'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      await tester.tap(find.text('Ya, Tutup'));
      await tester.pumpAndSettle();

      expect(confirmResult, isTrue);
      expect(find.text('Tutup Periode'), findsNothing);
    });

    testWidgets('showConfirm mengembalikan nilai false saat tombol batal ditekan', (tester) async {
      bool? confirmResult;
      await tester.pumpWidget(
        createTestWidget((context) async {
          confirmResult = await DialogHelper.showConfirm(
            context,
            'Hapus Data',
            'Data recording akan dihapus secara permanen.',
            isDestructive: true,
          );
        }),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(confirmResult, isFalse);
    });

    testWidgets('showAbout menampilkan identitas aplikasi dengan styling konsisten', (tester) async {
      await tester.pumpWidget(
        createTestWidget((context) {
          DialogHelper.showAbout(context);
        }),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('BroilerKu'), findsOneWidget);
      expect(find.textContaining('Aplikasi Manajemen Peternakan'), findsOneWidget);
      expect(find.text('Versi 1.0.0 • Production Ready'), findsOneWidget);
      expect(find.byIcon(Icons.egg_outlined), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('BroilerKu'), findsNothing);
    });

    testWidgets('showPeriodPicker memilih periode yang diklik', (tester) async {
      String? selectedId;
      final List<PeriodData> periods = [
        PeriodData(
          id: 'p1',
          name: 'Periode Batch 1',
          startDate: DateTime(2026, 1, 1),
          endDate: null,
          initialCapacity: 5000,
          createdAt: DateTime(2026, 1, 1),
        ),
        PeriodData(
          id: 'p2',
          name: 'Periode Batch 2',
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 3, 1),
          initialCapacity: 6000,
          createdAt: DateTime(2026, 2, 1),
        ),
      ];

      await tester.pumpWidget(
        createTestWidget((context) {
          DialogHelper.showPeriodPicker(
            context,
            periods: periods,
            selectedPeriodId: 'p1',
            onSelected: (id) => selectedId = id,
          );
        }),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Periode'), findsOneWidget);
      expect(find.text('Periode Batch 1'), findsOneWidget);
      expect(find.text('Periode Batch 2'), findsOneWidget);

      await tester.tap(find.text('Periode Batch 2'));
      await tester.pumpAndSettle();

      expect(selectedId, equals('p2'));
      expect(find.text('Pilih Periode'), findsNothing);
    });

    testWidgets('showStringPicker memilih opsi string yang diklik', (tester) async {
      String? selectedOption;
      final options = ['Pakan Pokok', 'Vitamin / Suplemen', 'Obat Vaksin'];

      await tester.pumpWidget(
        createTestWidget((context) {
          DialogHelper.showStringPicker(
            context,
            title: 'Pilih Kategori',
            options: options,
            selectedOption: 'Pakan Pokok',
            onSelected: (val) => selectedOption = val,
          );
        }),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Kategori'), findsOneWidget);
      expect(find.text('Vitamin / Suplemen'), findsOneWidget);

      await tester.tap(find.text('Vitamin / Suplemen'));
      await tester.pumpAndSettle();

      expect(selectedOption, equals('Vitamin / Suplemen'));
      expect(find.text('Pilih Kategori'), findsNothing);
    });

    testWidgets('showImageSourcePicker menampilkan bottom sheet dan mengembalikan ImageSource.gallery', (tester) async {
      ImageSource? pickedSource;

      await tester.pumpWidget(
        createTestWidget((context) async {
          pickedSource = await DialogHelper.showImageSourcePicker(
            context,
            title: 'Pilih Foto Profil',
          );
        }),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Foto Profil'), findsOneWidget);
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
      expect(find.text('Ambil Foto Kamera'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      await tester.tap(find.text('Pilih dari Galeri'));
      await tester.pumpAndSettle();

      expect(pickedSource, equals(ImageSource.gallery));
      expect(find.text('Pilih dari Galeri'), findsNothing);
    });

    testWidgets('showImageSourcePicker mengembalikan ImageSource.camera saat memilih kamera', (tester) async {
      ImageSource? pickedSource;

      await tester.pumpWidget(
        createTestWidget((context) async {
          pickedSource = await DialogHelper.showImageSourcePicker(
            context,
            title: 'Pilih Foto Kandang',
          );
        }),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Foto Kandang'), findsOneWidget);

      await tester.tap(find.text('Ambil Foto Kamera'));
      await tester.pumpAndSettle();

      expect(pickedSource, equals(ImageSource.camera));
      expect(find.text('Ambil Foto Kamera'), findsNothing);
    });
  });
}
