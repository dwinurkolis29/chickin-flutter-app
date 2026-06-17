import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/tour/tour_controller.dart';
import 'package:recording_app/core/tour/tour_step.dart';
import 'package:recording_app/core/tour/widgets/tour_aware_wrapper.dart';
import 'package:recording_app/core/tour/widgets/tour_overlay.dart';
import 'package:recording_app/core/tour/widgets/tour_tooltip.dart';
import 'package:recording_app/core/tour/widgets/tour_entry_dialog.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/statistics_section.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/datatable.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/population_widget.dart';
import 'package:recording_app/features/cage/presentation/pages/form_cage.dart';
import 'package:recording_app/features/cage/presentation/pages/cage_profile.dart';
import 'package:recording_app/features/recording/presentation/pages/form_recording.dart';
import 'package:recording_app/features/recording/presentation/pages/detail_recording.dart';
import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/period/presentation/list_period.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/user/presentation/pages/profile_screen.dart';
import 'package:recording_app/features/reporting/presentation/pages/period_report_page.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/features/reminder/presentation/widgets/reminder_badge_icon.dart';
import 'widgets/fcr_datacard.dart';

// ── Nav index constants ───────────────────────────────────────────────────────
const int _kHome = 0;
const int _kKandang = 1;
// index 2 is the FAB notch — not a real page
const int _kLaporan = 2;
const int _kProfil = 3;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  final GlobalKey _fabKey = GlobalKey();

  // Logical page index: 0=Home, 1=Kandang, 2=Laporan, 3=Profil
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const <Widget>[
      DashboardContent(),
      CageProfile(isTab: true),
      PeriodReportPage(isTab: true),
      ProfileScreen(),
    ];
  }

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  Future<void> _navigateToAddRecord() async {
    final cageData = await _firebaseService.getCage();

    if (cageData.capacity == 0 || cageData.type.isEmpty) {
      final shouldNavigate = await DialogHelper.showConfirm(
        context,
        'Data Kandang Belum Diisi',
        'Anda harus mengisi data kandang terlebih dahulu sebelum menambah recording.\n\nApakah Anda ingin mengisi data kandang sekarang?',
        confirmText: 'Isi Sekarang',
        cancelText: 'Nanti',
      );

      if (shouldNavigate == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FormCage()),
        );
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormRecording()),
    );

    if (result == true && mounted) {
      final controller = Provider.of<HomeController>(context, listen: false);
      controller.refreshStreams();
      AppSnackbar.showSuccess(context, 'Data berhasil ditambahkan');
    }
  }

  // ── Bottom nav helpers ────────────────────────────────────────────────────
  Widget _navItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onNavTap(index),
            splashColor: colorScheme.primary.withOpacity(0.12),
            highlightColor: colorScheme.primary.withOpacity(0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          // AppHeader muncul di semua tab nav (Home, Kandang, Laporan, Profil).
          // Badge reminder tampil di semua tab nav dan hilang ketika masuk halaman detail.
          appBar: AppHeader(
            title: switch (_selectedIndex) {
              _kHome    => 'BroilerKu',
              _kKandang => 'Kandang',
              _kLaporan => 'Laporan',
              _kProfil  => 'Profil',
              _         => 'BroilerKu',
            },
            isHome: true,
            actions: const [ReminderBadgeIcon()],
          ),
          body: SafeArea(bottom: false, child: _pages[_selectedIndex]),

          // ── FAB ──────────────────────────────────────────────────────────
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Semantics(
            button: true,
            label: 'Tambah recording',
            child: TourAwareWrapper(
              tourKey: _fabKey,
              child: FloatingActionButton(
                onPressed: _navigateToAddRecord,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ),

          // ── Bottom nav bar (5 slots: 2 + notch + 2) ──────────────────────
          bottomNavigationBar: BottomAppBar(
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surfaceContainer
                : Colors.white,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            elevation: 12,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Home
                  _navItem(
                    index: _kHome,
                    activeIcon: Icons.home,
                    inactiveIcon: Icons.home_outlined,
                    label: 'Beranda',
                  ),
                  // Kandang
                  _navItem(
                    index: _kKandang,
                    activeIcon: Icons.warehouse,
                    inactiveIcon: Icons.warehouse_outlined,
                    label: 'Kandang',
                  ),
                  // Centre gap for notched FAB
                  const SizedBox(width: 80),
                  // Laporan
                  _navItem(
                    index: _kLaporan,
                    activeIcon: Icons.bar_chart,
                    inactiveIcon: Icons.bar_chart_outlined,
                    label: 'Laporan',
                  ),
                  // Profil
                  _navItem(
                    index: _kProfil,
                    activeIcon: Icons.person,
                    inactiveIcon: Icons.person_outline,
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildFabTourOverlay(context),
      ],
    );
  }

  Widget _buildFabTourOverlay(BuildContext context) {
    final tourController = context.watch<TourController>();
    if (!tourController.isTourActive ||
        tourController.currentStep != TourStep.addRecording) {
      return const SizedBox.shrink();
    }

    if (_selectedIndex != _kHome) return const SizedBox.shrink();

    return TourOverlay(
      targetKey: _fabKey,
      tooltip: TourTooltip(
        title: 'Langkah 2: Tambah Recording',
        description:
            'Bagus! Periode sudah berjalan. Sekarang, klik tombol + ini setiap hari untuk mencatat data harian ayam (recording).',
        stepText: '2 / 3',
        showSkip: true,
        onSkip: () => tourController.skip(),
      ),
      onSkip: () {},
    );
  }
}

// ── DashboardContent — Home tab body ─────────────────────────────────────────

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final GlobalKey _createPeriodKey = GlobalKey();
  final GlobalKey _statisticsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<HomeController>().loadActivePeriod();

      final tourController = context.read<TourController>();
      final shouldShow = await tourController.shouldShowTour();

      if (shouldShow && mounted) {
        if (context.read<HomeController>().activePeriodId == null) {
          _showTourEntryDialog();
        }
      }
    });
  }

  void _showTourEntryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TourEntryDialog(
        onStart: () {
          Navigator.pop(context);
          context.read<TourController>().startTour();
        },
        onSkip: () {
          Navigator.pop(context);
          context.read<TourController>().skip();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tourController = context.watch<TourController>();

    return Stack(
      children: [
        _buildMainContent(context),
        if (tourController.isTourActive &&
            tourController.currentStep == TourStep.createPeriod)
          _buildCreatePeriodOverlay(tourController),
        if (tourController.isTourActive &&
            tourController.currentStep == TourStep.viewDashboard)
          _buildStatisticsOverlay(tourController),
      ],
    );
  }

  Widget _buildCreatePeriodOverlay(TourController controller) {
    return TourOverlay(
      targetKey: _createPeriodKey,
      tooltip: TourTooltip(
        title: 'Langkah 1: Mulai Periode',
        description:
            'Klik tombol di bawah untuk membuat periode peternakan pertama Anda. Periode digunakan untuk mengelompokkan data recording harian.',
        stepText: '1 / 3',
        showSkip: true,
        onSkip: () => controller.skip(),
      ),
      onSkip: () {},
    );
  }

  Widget _buildStatisticsOverlay(TourController controller) {
    return TourOverlay(
      targetKey: _statisticsKey,
      tooltip: TourTooltip(
        title: 'Langkah 3: Pantau Hasil',
        description:
            'Bagus! Data Anda sudah diolah menjadi statistik. Di sini Anda bisa melihat FCR, sisa ayam, dan pertumbuhan berat secara real-time.',
        stepText: '3 / 3',
        onSkip: () => controller.complete(),
        actionButtonText: 'Selesai',
        onAction: () => controller.complete(),
      ),
      onSkip: () {},
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 50,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 10),
                Text(
                  'Anda belum login',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Silahkan login terlebih dahulu',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  ),
                  child: const Text('Masuk'),
                ),
              ],
            ),
          );
        }

        if (controller.isLoadingPeriod) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.activePeriodId == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data recording',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Klik tombol di bawah untuk membuat periode pertama',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                TourAwareWrapper(
                  tourKey: _createPeriodKey,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PeriodListScreen(),
                        ),
                      ).then((_) {
                        if (mounted) {
                          context
                              .read<HomeController>()
                              .loadActivePeriod();
                        }
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Periode Baru'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // ── Active period — show banner + content ──────────────────────────
        final email = currentUser.email ?? '';
        final periodName = controller.activePeriodName ?? '';

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Banner (spec §3.1) ────────────────────────────────
              _TopBanner(periodName: periodName, email: email),

              // ── Existing content below — untouched ────────────────────
              Padding(
                padding: const EdgeInsets.all(10),
                child: StreamBuilder<List<RecordingData>>(
                  stream: controller.recordingsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final recordings = snapshot.data ?? <RecordingData>[];

                    if (recordings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada data recording',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Klik tombol + untuk menambah data',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    final fcrResults =
                        controller.calculateWeeklyFCR(recordings);
                    final fcr = fcrResults.isNotEmpty
                        ? fcrResults.last.fcr
                        : 0.0;
                    final populationRemain = fcrResults.isNotEmpty
                        ? fcrResults.last.sisaAyam
                        : 0;
                    final umur =
                        recordings.isNotEmpty ? recordings.last.day : 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        PopulationSection(
                          populationRemain: populationRemain,
                          capacity: controller.initialPopulation,
                        ),
                        const SizedBox(height: 15),
                        TourAwareWrapper(
                          tourKey: _statisticsKey,
                          child: StatisticsSection(
                            fcr: fcr,
                            umur: umur,
                            weightStream: controller.weightStream,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 720),
                            child: ChickenDataTable(
                              chickenDataList: recordings,
                              onViewAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DetailRecording(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FCRDataCard(fcrData: fcrResults),
                        const SizedBox(height: 80),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Top Banner widget (spec §3.1) ─────────────────────────────────────────────

class _TopBanner extends StatelessWidget {
  final String periodName;
  final String email;

  const _TopBanner({required this.periodName, required this.email});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with "Periode Aktif" and Green Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Periode Aktif',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PeriodListScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withOpacity(0.5)),
                  ),
                  child: Text(
                    '● Aktif',
                    style: textTheme.labelMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),

          // Kandang / period name
          Text(
            periodName.isNotEmpty ? periodName : 'Periode Tanpa Nama',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 4),

          // User email
          Text(
            email,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}