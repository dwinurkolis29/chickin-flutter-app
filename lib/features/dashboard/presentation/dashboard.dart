import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/services/notification_service.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/statistics_section.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/datatable.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/population_widget.dart';
import 'package:recording_app/features/cage/presentation/pages/form_cage.dart';
import 'package:recording_app/features/recording/presentation/pages/form_recording.dart';
import 'package:recording_app/features/recording/presentation/pages/detail_recording.dart';
import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/period/presentation/list_period.dart';
import 'package:recording_app/features/period/presentation/screens/form_period.dart';
import 'package:recording_app/features/period/presentation/controllers/period_controller.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/user/presentation/pages/profile_screen.dart';
import 'package:recording_app/features/reporting/presentation/pages/period_report_page.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'widgets/fcr_datacard.dart';
import 'widgets/dashboard_greeting.dart';
import 'widgets/post_thinning_stress_alert.dart';
import 'package:recording_app/features/period/data/models/harvest_record.dart';
import 'package:recording_app/core/components/loading/shimmer_loading.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/finance/presentation/pages/finance_list_screen.dart';
import 'package:recording_app/features/recording/presentation/pages/sekat_seleksian_screen.dart';
import 'package:recording_app/features/recording/presentation/pages/chicken_weight_screen.dart';
import 'package:recording_app/features/reporting/presentation/pages/fcr_monitoring_screen.dart';
import 'package:recording_app/features/user/presentation/pages/quick_calculator_screen.dart';

// ── Nav index constants ───────────────────────────────────────────────────────
const int _kHome = 0;
const int _kPeriode = 1;
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

  // Logical page index: 0=Home, 1=Periode, 2=Laporan, 3=Profil
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const <Widget>[
      DashboardContent(),
      PeriodListScreen(isTab: true),
      PeriodReportPage(isTab: true),
      ProfileScreen(),
    ];
  }

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  Future<void> _navigateToAddRecord() async {
    final cageData = await _firebaseService.getCage();
    if (!mounted) return;

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

  Future<void> _navigateToAddPeriod() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormPeriod()),
    );

    if (mounted) {
      context.read<PeriodController>().reload();
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
          color: AppColors.transparent,
          child: InkWell(
            onTap: () => _onNavTap(index),
            hoverColor: AppColors.transparent,
            focusColor: AppColors.transparent,
            highlightColor: AppColors.transparent,
            splashColor: AppColors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color:
                      isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
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
      appBar: AppHeader(
        title: switch (_selectedIndex) {
          _kHome => 'BroilerKu',
          _kPeriode => 'Periode',
          _kLaporan => 'Laporan',
          _kProfil => 'Profil',
          _ => 'BroilerKu',
        },
        isHome: true,
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),

      // ── FAB ──────────────────────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Semantics(
        button: true,
        label:
            _selectedIndex == _kPeriode ? 'Tambah periode' : 'Tambah recording',
        child: FloatingActionButton(
          onPressed:
              _selectedIndex == _kPeriode
                  ? _navigateToAddPeriod
                  : _navigateToAddRecord,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
      ),

      // ── Bottom nav bar (5 slots: 2 + notch + 2) ──────────────────────
      bottomNavigationBar: BottomAppBar(
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 0,
        surfaceTintColor: colorScheme.surface,
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
              // Periode
              _navItem(
                index: _kPeriode,
                activeIcon: Icons.calendar_month,
                inactiveIcon: Icons.calendar_month_outlined,
                label: 'Periode',
              ),
              // Centre gap for notched FAB
              const SizedBox(width: 80),
              // Laporan
              _navItem(
                index: _kLaporan,
                activeIcon: Icons.assessment_rounded,
                inactiveIcon: Icons.assessment_outlined,
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

class _DashboardContentState extends State<DashboardContent>
    with AutomaticKeepAliveClientMixin {
  late final ScrollController _quickActionsScrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _quickActionsScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final ctrl = context.read<HomeController>();
        if (ctrl.activePeriodId == null && !ctrl.isLoadingPeriod) {
          ctrl.loadActivePeriod();
        }
      }
    });
  }

  @override
  void dispose() {
    _quickActionsScrollController.dispose();
    super.dispose();
  }

  Future<void> _navigateToAddRecord() async {
    final firebaseService = FirebaseService();
    final cageData = await firebaseService.getCage();

    if (cageData.capacity == 0 || cageData.type.isEmpty) {
      if (!mounted) return;
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

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormRecording()),
    );

    if (result == true && mounted) {
      final controller = context.read<HomeController>();
      controller.refreshStreams();
      AppSnackbar.showSuccess(context, 'Data berhasil ditambahkan');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            action: FilledButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  ),
              child: const Text('Masuk'),
            ),
          );
        }

        if (controller.isLoadingPeriod) {
          return const DashboardSkeleton();
        }

        if (controller.activePeriodId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService().syncDailyRecordingReminder(
              activePeriod: null,
              recordings: const [],
            );
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardGreeting(),
              Expanded(
                child: Center(
                  child: AppEmptyState(
                    icon: Icons.calendar_today_outlined,
                    message: 'Belum Ada Periode Aktif',
                    subtitle:
                        'Mulai siklus pemeliharaan baru untuk mencatat populasi DOC, konsumsi pakan, dan bobot ayam.',
                    actionLabel: 'Buat Periode Baru',
                    onAction: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FormPeriod(),
                        ),
                      );
                      if (context.mounted) {
                        context.read<HomeController>().loadActivePeriod();
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardGreeting(),
              Padding(
                padding: const EdgeInsets.all(10),
                child: StreamBuilder<List<RecordingData>>(
                  stream: controller.recordingsStream,
                  initialData: controller.cachedRecordings,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const TableSkeleton();
                    }

                    if (snapshot.hasError && !snapshot.hasData) {
                      return AppErrorState(
                        message: 'Gagal memuat data recording',
                        subtitle: snapshot.error.toString(),
                        onRetry: () => controller.loadActivePeriod(),
                      );
                    }

                    final recordings = snapshot.data ?? <RecordingData>[];
                    if (snapshot.hasData && snapshot.data != null) {
                      controller.setCachedRecordings(snapshot.data!);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        NotificationService().syncDailyRecordingReminder(
                          activePeriod: controller.activePeriod,
                          recordings: snapshot.data!,
                        );
                      });
                    }

                    if (recordings.isEmpty) {
                      return Column(
                        children: [
                          if (controller.activePeriod != null) ...[
                            _buildQuickActionsRow(context, controller),
                            const SizedBox(height: 16),
                          ],
                          AppEmptyState(
                            icon: Icons.assignment_outlined,
                            message: 'Belum Ada Data Recording',
                            subtitle:
                                'Mulai catat konsumsi pakan, kematian, dan penimbangan bobot ayam untuk hari ini.',
                            actionLabel: 'Tambah Recording',
                            onAction: _navigateToAddRecord,
                          ),
                        ],
                      );
                    }

                    final fcrResults = controller.calculateWeeklyFCR(
                      recordings,
                    );
                    final fcr =
                        fcrResults.isNotEmpty ? fcrResults.last.fcr : 0.0;
                    final populationRemain =
                        fcrResults.isNotEmpty ? fcrResults.last.sisaAyam : 0;
                    final umur =
                        recordings.isNotEmpty ? recordings.last.day : 0;

                    // Deteksi panen parsial dalam 72 jam terakhir untuk alert pemulihan stres
                    final activePeriod = controller.activePeriod;
                    HarvestRecord? recentPartialHarvest;
                    if (activePeriod?.summary?.partialHarvests.isNotEmpty ==
                        true) {
                      final partials = activePeriod!.summary!.partialHarvests;
                      final latest = partials.reduce(
                        (a, b) => a.date.isAfter(b.date) ? a : b,
                      );
                      final diffHours =
                          DateTime.now().difference(latest.date).inHours;
                      if (diffHours <= 72) {
                        recentPartialHarvest = latest;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (recentPartialHarvest != null)
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: PostThinningStressAlert(
                                lastPartialHarvest: recentPartialHarvest,
                                period: activePeriod,
                              ),
                            ),
                          ),
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
                        _buildQuickActionsRow(context, controller),
                        const SizedBox(height: 10),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: ChickenDataTable(
                              chickenDataList: recordings,
                              onViewAll:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DetailRecording(),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FCRDataCard(fcrData: fcrResults, showViewAllLink: true),
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

  Widget _buildQuickActionsRow(
    BuildContext context,
    HomeController controller,
  ) {
    final activePeriod = controller.activePeriod;
    if (activePeriod == null) return const SizedBox.shrink();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SizedBox(
          height: 108,
          child: SingleChildScrollView(
            controller: _quickActionsScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildPintasanCard(
                  context: context,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Pencatatan\nKeuangan',
                  subtitle: 'Biaya & panen',
                  semanticsLabel: 'Pencatatan Keuangan',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FinanceListScreen(period: activePeriod),
                      ),
                    );
                    if (context.mounted) {
                      controller.loadActivePeriod();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildPintasanCard(
                  context: context,
                  icon: Icons.fence_outlined,
                  label: 'Sekat\nSeleksian',
                  subtitle: 'Hospital pen',
                  semanticsLabel: 'Sekat Seleksian',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const SekatSeleksianScreen(),
                      ),
                    );
                    if (context.mounted) {
                      controller.loadActivePeriod();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildPintasanCard(
                  context: context,
                  icon: Icons.analytics_outlined,
                  label: 'Monitor\nFCR',
                  subtitle: 'Efisiensi pakan',
                  semanticsLabel: 'Monitor FCR',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FCRMonitoringScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildPintasanCard(
                  context: context,
                  icon: Icons.show_chart_rounded,
                  label: 'Pertumbuhan\nBobot',
                  subtitle: 'Kurva & ADG',
                  semanticsLabel: 'Pertumbuhan Bobot Ayam',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChickenWeightScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildPintasanCard(
                  context: context,
                  icon: Icons.calculate_outlined,
                  label: 'Kalkulator\nCepat',
                  subtitle: 'Simulasi panen',
                  semanticsLabel: 'Kalkulator Cepat',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuickCalculatorScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPintasanCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required String semanticsLabel,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: SizedBox(
        width: 106,
        child: AppCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: cs.primary,
                          size: 18,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          height: 1.2,
                          color: cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          fontSize: 9.5,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



}
