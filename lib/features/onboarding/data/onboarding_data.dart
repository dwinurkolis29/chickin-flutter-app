class OnboardingItem {
  final String svgAsset;
  final String title;
  final String subtitle;

  const OnboardingItem({
    required this.svgAsset,
    required this.title,
    required this.subtitle,
  });
}

const List<OnboardingItem> onboardingItems = [
  OnboardingItem(
    svgAsset: 'assets/onboarding/notes.svg',
    title: 'Catat Data Peternakan\nHarian Anda.',
    subtitle: 'Pantau kinerja ayam pedaging harian dengan mudah.',
  ),
  OnboardingItem(
    svgAsset: 'assets/onboarding/formula.svg',
    title: 'Pantau Rasio\nKonversi Kinerja.',
    subtitle: 'Hitung secara otomatis FCR dari catatan harian Anda.',
  ),
  OnboardingItem(
    svgAsset: 'assets/onboarding/analysis.svg',
    title: 'Buat Laporan\nPeternakan.',
    subtitle: 'Lihat ringkasan lengkap untuk setiap periode peternakan.',
  ),
];
