import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recording_app/features/dashboard/data/models/fcr_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/statistics_section.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/datatable.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/population_widget.dart';
import 'package:recording_app/features/cage/presentation/cage.dart';
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
      const Cage(),
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
                // Menggunakan FirebaseAuth untuk logout
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                // Menghapus data login dari Hive
                _boxLogin.clear();
                _boxLogin.put("loginStatus", false);
                Navigator.pushReplacement(
                  context,
                  // Navigasi ke halaman login
                  MaterialPageRoute(
                    builder: (context) => const Login(),
                  ),
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
    // Navigasi ke halaman tambah data
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: IconButton(
                // memanggil fungsi untuk menampilkan dialog logout
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.login_outlined),
              ),
            ),
          )
        ],
      ),
      // mengatur elemen body sesuai dengan halaman yang aktif
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const <BottomNavigationBarItem>[
          // menambahkan item untuk setiap halaman
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_max_outlined),
            label: 'Kandang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Peternak',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) => _onItemTapped(index),
      ),
      // menambahkan floating action tambah data
      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton.extended(
              onPressed: (){
                _navigateToAddRecord();
              },
              icon: Icon(Icons.add),
              label: Text("Tambah"),
            )
          : null,
    );
  }
}

class HomeContent extends StatelessWidget {

  double _fcr = 0;
  int _umur = 0;
  int? _populationRemain;
  bool _isLoading = true;

  HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    // mengambil data login dari Hive
    final Box _boxLogin = Hive.box("login");

    return Container(
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline_outlined,
                ),
                const SizedBox(width: 10),
                Text(
                  // menampilkan email yang disimpan di Hive
                  _boxLogin.get("Email"),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            PopulationSection(
              populationRemain: _populationRemain ?? 0,
            ),
            const SizedBox(height: 15),
            // menampilkan komponen statistik dengan mengirim data fcr dan umur
            StatisticsSection(
              fcr: _fcr,
              umur: _umur,
            ),
            const SizedBox(height: 10),
            // menampilkan data recording ayam ke dalam tabel dari stream builder firestore
            StreamBuilder<List<RecordingData>>(
              stream: FirebaseService().getRecordingsStream(1, _boxLogin.get("Email")),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  print(snapshot.data);
                  return ChickenDataTable(chickenDataList: snapshot.data!);
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
            const SizedBox(height: 10),
            // menampilkan data fcr ke dalam tabel dari stream builder
            StreamBuilder<List<RecordingData>>(
              stream: FirebaseService().getRecordingsStream(1, _boxLogin.get("Email")),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  // menghitung fcr dan memanggil fungsi calculateWeeklyFCR didalam model
                  final fcrResults = FCRCalculator.calculateWeeklyFCR(
                      snapshot.data!,
                      3000
                  );

                  // mengambil data terakhir untuk ditampilkan di statistik section
                  if (fcrResults.isNotEmpty) {
                    final lastFCR = fcrResults.last;
                    _fcr = lastFCR.fcr;
                    _populationRemain = lastFCR.sisaAyam;
                    final lastRecord = snapshot.data!.last;
                    _umur = lastRecord.umur;
                  }

                  print(fcrResults.map((e) => e.toJson()).toList());
                  return FCRDataTable(fcrData: fcrResults);
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
