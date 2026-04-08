/// Enum untuk merepresentasikan tahapan dalam Interactive Feature Tour.
enum TourStep {
  /// Tour belum dimulai atau tidak aktif.
  none,

  /// Step 1: Membuat periode pertama (Highlight tombol "Buat Periode Baru").
  createPeriod,

  /// Step 2: Menambah pencatatan/recording (Highlight tombol "Tambah Recording").
  addRecording,

  /// Step 3: Melihat hasil di Dashboard (Highlight ringkasan FCR/Statistik).
  viewDashboard,

  /// Tour telah selesai.
  completed,
}
