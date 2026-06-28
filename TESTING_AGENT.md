# TESTING_AGENT.md

# Unit Testing Guidelines — Chickin Flutter App

Dokumen ini berisi aturan yang WAJIB dipatuhi AI Agent saat membuat Unit Test untuk proyek Chickin.

Selalu baca CONTEXT.md terlebih dahulu.

Jangan membuat asumsi di luar dokumen tersebut.

---

# OBJECTIVE

Tujuan unit test adalah:

- memastikan business logic selalu benar
- mencegah regression
- menjaga kualitas production
- mempermudah refactoring

Target utama adalah kestabilan logic, bukan sekadar meningkatkan coverage.

---

# TESTING PHILOSOPHY

Gunakan Test Pyramid.

70% Unit Test

20% Widget Test

10% Integration Test

Prioritaskan Unit Test dibanding Widget Test.

---

# PRIORITAS

Urutan implementasi wajib sebagai berikut.

Priority 1

- safe_convert.dart
- seluruh model
- seluruh usecase/domain

Priority 2

- controller

Priority 3

- services (mock)

Priority 4

- widget

Priority 5

- integration test

Jangan membuat Widget Test sebelum seluruh Domain Layer selesai diuji.

---

# FOLDER STRUCTURE

Gunakan struktur berikut.

test/

    core/

        auth/

        models/

        services/

        theme/

        utils/

    features/

        auth/

        cage/

        dashboard/

        export/

        onboarding/

        period/

        recording/

        reminder/

        reporting/

        user/

Selalu mirror folder production.

Contoh

lib/features/recording/domain/usecases/calculate_fcr.dart

↓

test/features/recording/domain/usecases/calculate_fcr_test.dart

---

# NAMING

Gunakan nama yang konsisten.

calculate_fcr.dart

↓

calculate_fcr_test.dart

summary_calculator.dart

↓

summary_calculator_test.dart

PeriodController

↓

period_controller_test.dart

---

# TEST STYLE

Gunakan pola AAA.

Arrange

Act

Assert

Contoh

Arrange

buat data dummy

↓

Act

jalankan function

↓

Assert

bandingkan hasil

Jangan mencampur ketiganya.

---

# GROUP

Selalu gunakan group().

Contoh

group(
    "CalculateFCR",
)

Setiap method memiliki group sendiri.

---

# TEST CASE

Setiap function minimal memiliki test berikut.

Happy Path

Boundary Value

Null

Empty

Invalid Input

Edge Case

Regression Case

Jika salah satu tidak relevan,
berikan komentar mengapa tidak diperlukan.

---

# MODEL TEST

Seluruh model wajib memiliki test.

fromJson()

toJson()

copyWith()

equality (jika ada)

default value

null value

safe_convert

Factory fromJson() wajib diuji menggunakan:

null

{}

partial json

invalid type

missing key

Tidak boleh hanya menguji happy path.

---

# SAFE CONVERT

Seluruh helper safe_convert wajib memiliki test.

Contoh

asInt(null)

↓

0

asDouble("12")

↓

12.0

asBool("true")

↓

true

dst.

Coverage helper ini harus 100%.

---

# USE CASE

Semua file dalam

domain/usecases/

wajib memiliki coverage 100%.

Contoh

CalculateFCR

SummaryCalculator

AnalyticsCalculator

InsightGenerator

GeneratePeriodReport

BuildRealtimeReport

BuildSnapshotReport

Setiap rumus harus diuji menggunakan beberapa variasi data.

---

# CONTROLLER TEST

Controller tidak boleh mengakses Firebase asli.

Seluruh dependency harus di-mock.

Gunakan mocktail.

Yang diuji

loading

success

error

notifyListeners()

state berubah

uid berubah

logout

controller dispose

onAuthChanged(null)

clear state

---

# FIREBASE

Jangan pernah menggunakan Firestore production.

Gunakan

mocktail

atau

fake_cloud_firestore

atau fake service.

Semua dependency Firebase harus dapat di-inject.

---

# WIDGET TEST

Widget Test hanya untuk screen utama.

Contoh

Login

Dashboard

Profile

Reporting

Yang diuji

Loading State

Empty State

Error State

Success State

Button enabled

Button disabled

Navigation

Validation

Jangan menguji warna.

Jangan menguji padding.

Jangan menguji ukuran widget.

---

# GOLDEN TEST

Jangan membuat Golden Test.

Kecuali diminta secara eksplisit.

---

# MOCK DATA

Gunakan data dummy yang realistis.

Contoh

Period

35 hari

1000 ayam

Feed 3200 kg

Mortality 18

Weight 2.15 kg

Jangan gunakan

Foo

Bar

Test User

123

---

# ASSERTION

Gunakan assertion yang spesifik.

Lebih baik

expect(result.fcr, 1.42)

daripada

expect(result, isNotNull)

---

# COVERAGE TARGET

Domain

100%

Models

95%

Controllers

80%

Services

80%

Widgets

50%

Project

minimal 70%

Jangan membuat test hanya untuk mengejar coverage.

---

# CLEAN CODE

Setiap test harus

jelas

singkat

independen

repeatable

tidak bergantung urutan

tidak bergantung internet

tidak bergantung Firebase production

---

# DO NOT

Jangan mengubah source code hanya agar test lolos.

Jangan menghapus validasi.

Jangan menambah public method hanya untuk testing.

Jangan menggunakan Future.delayed().

Jangan menggunakan print().

Jangan membuat test yang flaky.

---

# IF SOURCE CODE IS HARD TO TEST

Jika menemukan kode yang sulit diuji,

JANGAN langsung membuat workaround.

Berikan rekomendasi refactoring terlebih dahulu.

Misalnya

- Dependency Injection
- Constructor Injection
- Extract Service
- Extract Pure Function
- Interface

Baru setelah itu buat unit test.

---

# OUTPUT FORMAT

Setiap kali membuat test,

AI wajib memberikan:

1. Ringkasan apa yang diuji.

2. Daftar seluruh test case.

3. Potensi bug yang ditemukan.

4. Rekomendasi refactoring (jika ada).

5. File test yang dibuat.

6. Estimasi coverage.

Jangan hanya memberikan source code.

Selalu jelaskan alasan setiap test penting bagi kualitas aplikasi.
