import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/presentation/pages/form_recording.dart';

class _FakeUser extends Fake implements fb.User {
  @override
  final String uid = 'test-user-123';
  @override
  final String displayName = 'Peternak Budi';
}

class _FakeAuthService extends ChangeNotifier implements AuthService {
  final fb.User? _currentUser;
  _FakeAuthService({fb.User? user}) : _currentUser = user;

  @override
  fb.User? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseService extends Fake implements FirebaseService {
  PeriodData? mockActivePeriod;
  List<RecordingData> mockRecordings = [];

  @override
  Future<PeriodData?> getActivePeriod([String? uid]) async => mockActivePeriod;

  @override
  Stream<List<RecordingData>> getRecordingsStream(String periodId, [String? uid]) =>
      Stream.value(mockRecordings);

  @override
  Future<List<RecordingData>> getRecordingsOnce(String periodId, [String? uid]) async =>
      mockRecordings;

  @override
  Future<void> addRecording(String periodId, RecordingData recording, [String? uid]) async {
    mockRecordings.add(recording);
  }
}

void main() {
  final testPeriod = PeriodData(
    id: 'period-123',
    name: 'Periode 1',
    initialCapacity: 1000,
    startDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
  );

  Widget createWidgetUnderTest({
    _FakeAuthService? authService,
    _FakeFirebaseService? firebaseService,
  }) {
    final fakeAuth = authService ?? _FakeAuthService(user: _FakeUser());
    final fakeFirebase = firebaseService ??
        (_FakeFirebaseService()..mockActivePeriod = testPeriod);

    return ChangeNotifierProvider<AuthService>.value(
      value: fakeAuth,
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: FormRecording(firebaseService: fakeFirebase),
      ),
    );
  }

  group('FormRecording Widget Tests', () {
    testWidgets('menampilkan header, form field, toggle satuan, dan guidance card', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Tambah Recording'), findsOneWidget);
      expect(find.text('Pencatatan Harian Ternak'), findsOneWidget);
      expect(find.text('WAKTU & KEMATIAN'), findsOneWidget);
      expect(find.text('PAKAN & PENIMBANGAN'), findsOneWidget);
      expect(find.text('Data Siap Disimpan (Standar Database)'), findsOneWidget);

      // Default labels and unit selectors
      expect(find.text('Umur Ayam (Hari)'), findsOneWidget);
      expect(find.text('Mati Ayam (Ekor)'), findsOneWidget);
      expect(find.text('Habis Pakan (Sak)'), findsOneWidget);
      expect(find.text('Berat Rata-rata (Gram)'), findsOneWidget);
      expect(find.text('Simpan Data Recording'), findsOneWidget);
    });

    testWidgets('dapat toggle satuan pakan antara Sak dan Kg dengan konversi nilai', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Input 2 sak pakan
      final pakanField = find.widgetWithText(TextFormField, 'Habis Pakan (Sak)');
      await tester.enterText(pakanField, '2');
      await tester.pumpAndSettle();

      // Memastikan helper text menunjukkan setara 100 kg
      expect(find.text('Setara ≈ 100 Kg (1 sak = 50 kg)'), findsOneWidget);

      // Tap toggle Kg pertama (pada pakan)
      await tester.tap(find.text('Kg').first);
      await tester.pumpAndSettle();

      // Field label berubah ke Kg dan nilainya otomatis dikonversi jadi 100
      expect(find.text('Habis Pakan (Kg)'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('Setara ≈ 2.00 Sak pakan'), findsOneWidget);
    });

    testWidgets('dapat toggle satuan bobot antara Gram dan Kg dengan konversi nilai', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Input 1250 gram
      final beratField = find.widgetWithText(TextFormField, 'Berat Rata-rata (Gram)');
      await tester.enterText(beratField, '1250');
      await tester.pumpAndSettle();

      expect(find.text('Setara ≈ 1.25 Kg per ekor'), findsOneWidget);

      // Tap toggle Kg kedua (pada bobot)
      final kgToggles = find.text('Kg');
      await tester.tap(kgToggles.last);
      await tester.pumpAndSettle();

      // Field label berubah ke Kg dan nilai otomatis terkonversi jadi 1.25
      expect(find.text('Berat Rata-rata (Kg)'), findsOneWidget);
      expect(find.text('1.25'), findsOneWidget);
      expect(find.text('Setara ≈ 1250 Gram per ekor'), findsOneWidget);
    });

    testWidgets('menampilkan validasi saat submit form kosong', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Clear umur
      final umurField = find.widgetWithText(TextFormField, 'Umur Ayam (Hari)');
      await tester.enterText(umurField, '');
      await tester.pumpAndSettle();

      // Tap Simpan
      await tester.ensureVisible(find.text('Simpan Data Recording'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Data Recording'));
      await tester.pumpAndSettle();

      expect(find.text('Umur ayam tidak boleh kosong.'), findsOneWidget);
      expect(find.text('Habis pakan tidak boleh kosong.'), findsOneWidget);
      expect(find.text('Berat ayam tidak boleh kosong.'), findsOneWidget);
    });
  });
}
