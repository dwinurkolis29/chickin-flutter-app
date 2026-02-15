import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recording_app/features/dashboard/data/models/fcr_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';
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

import 'widgets/fcr_datatable.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Box _boxLogin = Hive.box("login");
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah kamu yakin ingin logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (e) {
                  debugPrint(e.toString());
                }

                _boxLogin.delete("Email");
                _boxLogin.put("loginStatus", false);
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  // Navigasi ke halaman login
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // fungsi ini digunakan untuk navigasi ke halaman tambah data
  Future<void> _navigateToAddRecord() async {
    // VALIDASI: Cek apakah data kandang sudah diisi
    final cageData = await _firebaseService.getCage();
    
    if (cageData.capacity == 0 || cageData.type.isEmpty) {
      // Tampilkan dialog konfirmasi
      final shouldNavigate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Data Kandang Belum Diisi'),
          content: const Text(
            'Anda harus mengisi data kandang terlebih dahulu sebelum menambah recording.\n\nApakah Anda ingin mengisi data kandang sekarang?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Isi Sekarang'),
            ),
          ],
        ),
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

    // Jika result adalah true, StreamBuilder akan otomatis memperbarui
    if (result == true && mounted) {
      // StreamBuilder akan otomatis memperbarui karena data di Firestore sudah berubah
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil ditambahkan')),
      );
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
  HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final Box _boxLogin = Hive.box("login");
  final FirebaseService _firebaseService = FirebaseService();

  double _fcr = 0;
  int _umur = 0;
  int _populationRemain = 0;
  String? _activePeriodId;
  bool _isLoadingPeriod = true;

  @override
  void initState() {
    super.initState();
    _loadActivePeriod();
  }

  Future<void> _loadActivePeriod() async {
    try {
      final activePeriod = await _firebaseService.getActivePeriod();
      if (mounted) {
        setState(() {
          _activePeriodId = activePeriod?.id;
          _isLoadingPeriod = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPeriod = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _boxLogin.get("Email") as String?;

    if (email == null || email.isEmpty) {
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

    if (_isLoadingPeriod) {
      return const Center(child: CircularProgressIndicator());
    }

    // Jika tidak ada periode aktif, tampilkan empty state
    if (_activePeriodId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Belum ada data recording',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Klik tombol + untuk menambah data',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final recordingStream = _firebaseService.getRecordingsStream(_activePeriodId!);

    return Container(
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.person_outline_outlined),
                const SizedBox(width: 10),
                Text(email, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder(
              stream: recordingStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final recordings = snapshot.data ?? <RecordingData>[];

                if (recordings.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada data recording',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Klik tombol + untuk menambah data',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final chickenTable = ChickenDataTable(
                  chickenDataList: recordings,
                );

                final fcrResults =
                    recordings.isNotEmpty
                        ? FCRCalculator.calculateWeeklyFCR(recordings, 3000)
                        : <FCRData>[];

                if (fcrResults.isNotEmpty) {
                  final lastFCR = fcrResults.last;
                  _fcr = lastFCR.fcr;
                  _populationRemain = lastFCR.sisaAyam;
                  _umur = recordings.last.day;
                } else {
                  _fcr = 0;
                  _populationRemain = 0;
                  _umur = 0;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PopulationSection(populationRemain: _populationRemain),
                    const SizedBox(height: 15),
                    StatisticsSection(fcr: _fcr, umur: _umur),
                    const SizedBox(height: 10),
                    chickenTable,
                    const SizedBox(height: 10),
                    FCRDataTable(fcrData: fcrResults),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
