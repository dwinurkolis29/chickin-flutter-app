import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/features/dashboard/data/models/fcr_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/statistics_section.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/datatable.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/population_widget.dart';
import 'package:recording_app/features/cage/presentation/pages/add_cage_page.dart';
import 'package:recording_app/features/dashboard/presentation/form_record.dart';
import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/setting/presentation/setting.dart';
import 'package:recording_app/features/dashboard/data/models/recording_data.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/core/theme/app_colors.dart'; // ← tambahkan import ini

import 'widgets/fcr_datatable.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseService _firebaseService = FirebaseService();

  // 0 = Home, 1 = Setting
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      HomeContent(),
      const Setting(),
    ];
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
          MaterialPageRoute(builder: (context) => const AddCagePage()),
        );
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddRecord()),
    );

    if (result == true && mounted) {
      final controller = Provider.of<HomeController>(context, listen: false);
      controller.refreshStreams();
      AppSnackbar.showSuccess(context, 'Data berhasil ditambahkan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Semantics(
        button: true,
        label: 'Tambah recording',
        child: FloatingActionButton(
          onPressed: _navigateToAddRecord,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
      ),

      // ── Bottom nav bar ─────────────────────────────────────────────────────
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
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
                      splashColor: AppColors.primary.withOpacity(0.12),
                      highlightColor: AppColors.primary.withOpacity(0.06),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedIndex == 0
                                ? Icons.home
                                : Icons.home_outlined,
                            color: _selectedIndex == 0
                                ? AppColors.primary
                                : AppColors.secondary,
                            size: 24,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _selectedIndex == 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _selectedIndex == 0
                                  ? AppColors.primary
                                  : AppColors.secondary,
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
                      splashColor: AppColors.primary.withOpacity(0.12),
                      highlightColor: AppColors.primary.withOpacity(0.06),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedIndex == 1
                                ? Icons.settings
                                : Icons.settings_outlined,
                            color: _selectedIndex == 1
                                ? AppColors.primary
                                : AppColors.secondary,
                            size: 24,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Setting',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _selectedIndex == 1
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _selectedIndex == 1
                                  ? AppColors.primary
                                  : AppColors.secondary,
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
    );
  }
}

// ── HomeContent tidak diubah sama sekali ────────────────────────────────────

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().loadActivePeriod();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  "Anda belum login",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  "Silahkan login terlebih dahulu",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                  },
                  child: const Text("Login"),
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
                Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data recording',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Klik tombol + untuk menambah data',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      final recordings = snapshot.data ?? <RecordingData>[];

                      if (recordings.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada data recording',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Klik tombol + untuk menambah data',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final chickenTable = ChickenDataTable(
                        chickenDataList: recordings,
                      );

                      final fcrResults = controller.calculateWeeklyFCR(recordings);

                      final fcr = fcrResults.isNotEmpty ? fcrResults.last.fcr : 0.0;
                      final populationRemain = fcrResults.isNotEmpty ? fcrResults.last.sisaAyam : 0;
                      final umur = recordings.isNotEmpty ? recordings.last.day : 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          PopulationSection(populationRemain: populationRemain),
                          const SizedBox(height: 15),
                          StatisticsSection(
                            fcr: fcr,
                            umur: umur,
                            weightStream: controller.weightStream,
                          ),
                          const SizedBox(height: 10),
                          chickenTable,
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