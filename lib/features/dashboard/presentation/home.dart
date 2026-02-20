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
import 'package:recording_app/features/cage/presentation/pages/cage_profile_page.dart';
import 'package:recording_app/features/cage/presentation/pages/add_cage_page.dart';
import 'package:recording_app/features/dashboard/presentation/form_record.dart';
import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/setting/presentation/setting.dart';
import 'package:recording_app/features/user/presentation/user.dart';
import 'package:recording_app/features/dashboard/data/models/recording_data.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';

import 'widgets/fcr_datatable.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseService _firebaseService = FirebaseService();

  // selectedindex digunakan untuk menentukan halaman yang aktif
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // Menambahkan widget untuk setiap halaman
      // HomeContent() tidak menggunakan const karena ada perubahan di dalamnya
      HomeContent(),
      const CageProfilePage(),
      const User(),
      const Setting(),
    ];
  }

  // fungsi ini digunakan untuk mengubah halaman yang aktif
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // fungsi ini digunakan untuk menampilkan dialog logout
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


  // fungsi ini digunakan untuk navigasi ke halaman tambah data
  Future<void> _navigateToAddRecord() async {
    // VALIDASI: Cek apakah data kandang sudah diisi
    final cageData = await _firebaseService.getCage();
    
    if (cageData.capacity == 0 || cageData.type.isEmpty) {
      // Tampilkan dialog konfirmasi
      final shouldNavigate = await DialogHelper.showConfirm(
        context,
        'Data Kandang Belum Diisi',
        'Anda harus mengisi data kandang terlebih dahulu sebelum menambah recording.\n\nApakah Anda ingin mengisi data kandang sekarang?',
        confirmText: 'Isi Sekarang',
        cancelText: 'Nanti',
      );

      // Jika user pilih "Isi Sekarang", navigasi ke halaman kandang
      if (shouldNavigate == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddCagePage(),
          ),
        );
      }
      return;
    }

    // Data kandang sudah ada, navigasi ke halaman tambah data
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddRecord()),
    );

    // Jika result adalah true, refresh streams untuk dapat data terbaru
    if (result == true && mounted) {
      final controller = Provider.of<HomeController>(context, listen: false);
      controller.refreshStreams();
      AppSnackbar.showSuccess(context, 'Data berhasil ditambahkan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // mengatur warna background appbar
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: const Text("Recording App"),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DecoratedBox(
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: IconButton(
                // memanggil fungsi untuk menampilkan dialog logout
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.login_outlined),
              ),
            ),
          ),
        ],
      ),
      // mengatur elemen body sesuai dengan halaman yang aktif
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const <BottomNavigationBarItem>[
          // menambahkan item untuk setiap halaman
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_max_outlined),
            label: 'Kandang',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Peternak'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) => _onItemTapped(index),
      ),
      // menambahkan floating action tambah data
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton.extended(
                onPressed: () {
                  _navigateToAddRecord();
                },
                icon: Icon(Icons.add),
                label: Text("Tambah"),
              )
              : null,
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    // Load active period when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().loadActivePeriod();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        // Gunakan FirebaseAuth sebagai single source of truth
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

        // Jika tidak ada periode aktif, tampilkan empty state
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
                    
                    // Calculate metrics directly from data
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
