import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:recording_app/core/services/firebase_service.dart';
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
import 'package:recording_app/core/components/loading/shimmer_loading.dart';

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
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
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

    return Scaffold(
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
        child: FloatingActionButton(
          onPressed: _navigateToAddRecord,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeController>().loadActivePeriod();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainContent(context);
  }

  Widget _buildMainContent(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        final currentUser = context.watch<AuthService>().currentUser;

        if (currentUser == null) {
          return AppErrorState(
            icon: Icons.lock_outline_rounded,
            message: 'Anda belum login',
            subtitle: 'Silakan login terlebih dahulu',
            action: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              ),
              child: const Text('Masuk'),
            ),
          );
        }

        if (controller.isLoadingPeriod) {
          return const ReportSkeleton();
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
                ElevatedButton.icon(
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
                      return const TableSkeleton();
                    }

                    if (snapshot.hasError) {
                      return AppErrorState(
                        message: 'Gagal memuat data recording',
                        subtitle: snapshot.error.toString(),
                        onRetry: () => controller.loadActivePeriod(),
                      );
                    }

                    final recordings = snapshot.data ?? <RecordingData>[];

                    if (recordings.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.inbox_outlined,
                        message: 'Belum ada data recording',
                        subtitle: 'Klik tombol + untuk menambah data',
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
                        StatisticsSection(
                          fcr: fcr,
                          umur: umur,
                          weightStream: controller.weightStream,
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
    final onPrimary = colorScheme.onPrimary;
    final onPrimaryMuted = colorScheme.onPrimary.withOpacity(0.75);

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
                  color: onPrimaryMuted,
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
                    style: textTheme.labelMedium?.copyWith(color: onPrimary),
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
              color: onPrimary,
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
              color: onPrimaryMuted,
            ),
          ),
        ],
      ),
    );
  }
}