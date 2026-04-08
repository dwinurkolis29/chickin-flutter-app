import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:recording_app/features/recording/presentation/pages/form_recording.dart';
import 'package:recording_app/features/recording/presentation/pages/detail_recording.dart';
import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/setting/presentation/setting.dart';
import 'package:recording_app/features/period/presentation/list_period.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';

import 'widgets/fcr_datatable.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  final GlobalKey _fabKey = GlobalKey();

  // 0 = Home, 1 = Setting
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[const DashboardContent(), const Setting()];
  }

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  void _showLogoutDialog(BuildContext context) {
    DialogHelper.showConfirm(
      context,
      'Logout',
      'Apakah kamu yakin ingin logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        try {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        } catch (e) {
          debugPrint('Logout error: $e');
        }
      },
    );
  }

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
      MaterialPageRoute(
        builder: (context) => const FormRecording(),
      ),
    );

    if (result == true && mounted) {
      final controller = Provider.of<HomeController>(context, listen: false);
      controller.refreshStreams();
      AppSnackbar.showSuccess(context, 'Data berhasil ditambahkan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(child: _pages[_selectedIndex]),

          // ── FAB ────────────────────────────────────────────────────────────────
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Semantics(
            button: true,
            label: 'Tambah recording',
            child: TourAwareWrapper(
              tourKey: _fabKey,
              child: FloatingActionButton(
                onPressed: _navigateToAddRecord,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ),

      // ── Bottom nav bar ─────────────────────────────────────────────────────
      bottomNavigationBar: BottomAppBar(
        clipBehavior: Clip.antiAlias,
        color:
            Theme.of(context).brightness == Brightness.dark
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
              // Home tab
              Expanded(
                child: Semantics(
                  selected: _selectedIndex == 0,
                  button: true,
                  label: 'Home',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onNavTap(0),
                      splashColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.12),
                      highlightColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.06),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedIndex == 0
                                ? Icons.home
                                : Icons.home_outlined,
                            color:
                                _selectedIndex == 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  _selectedIndex == 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                              color:
                                  _selectedIndex == 0
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Centre gap for the notched FAB
              const SizedBox(width: 80),

              // Setting tab
              Expanded(
                child: Semantics(
                  selected: _selectedIndex == 1,
                  button: true,
                  label: 'Setting',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onNavTap(1),
                      splashColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.12),
                      highlightColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.06),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedIndex == 1
                                ? Icons.settings
                                : Icons.settings_outlined,
                            color:
                                _selectedIndex == 1
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Setting',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  _selectedIndex == 1
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                              color:
                                  _selectedIndex == 1
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
    // Jika tidak aktif, tutup overlay
    if (!tourController.isTourActive || tourController.currentStep != TourStep.addRecording) {
      return const SizedBox.shrink();
    }
    
    // Khusus: pastikan kita berada di Dashboard tab (selectedIndex == 0)
    // Jika di setting tab, sebaiknya skip dlu atau paksa ke tab 0
    if (_selectedIndex != 0) return const SizedBox.shrink();

    return TourOverlay(
      targetKey: _fabKey,
      tooltip: TourTooltip(
        title: 'Langkah 2: Tambah Recording',
        description: 'Bagus! Periode sudah berjalan. Sekarang, klik tombol + ini setiap hari untuk mencatat data harian ayam (recording).',
        stepText: '2 / 3',
        showSkip: true,
        onSkip: () => tourController.skip(),
      ),
      onSkip: () {},
    );
  }
}

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
        // Tampilkan dialog selamat datang hanya jika belum ada period
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
        if (tourController.isTourActive && tourController.currentStep == TourStep.createPeriod)
          _buildCreatePeriodOverlay(tourController),
        if (tourController.isTourActive && tourController.currentStep == TourStep.viewDashboard)
          _buildStatisticsOverlay(tourController),
      ],
    );
  }

  Widget _buildCreatePeriodOverlay(TourController controller) {

    return TourOverlay(
      targetKey: _createPeriodKey,
      tooltip: TourTooltip(
        title: 'Langkah 1: Mulai Periode',
        description: 'Klik tombol di bawah untuk membuat periode peternakan pertama Anda. Periode digunakan untuk mengelompokkan data recording harian.',
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
        description: 'Bagus! Data Anda sudah diolah menjadi statistik. Di sini Anda bisa melihat FCR, sisa ayam, dan pertumbuhan berat secara real-time.',
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
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      ),
                  child: const Text('Login'),
                ),
              ],
            ),
          );
        }

        final email = currentUser.email ?? 'No Email';

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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Klik tombol di bawah untuk membuat periode pertama',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          context.read<HomeController>().loadActivePeriod();
                        }
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Periode Baru'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_outlined),
                    const SizedBox(width: 10),
                    Text(email, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 10),
                if (controller.recordingsStream != null)
                  StreamBuilder<List<RecordingData>>(
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
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada data recording',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Klik tombol + untuk menambah data',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
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
                          FCRDataTable(fcrData: fcrResults),
                          const SizedBox(height: 80),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
