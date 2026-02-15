import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/core/services/firebase_service.dart';

class StatisticsSection extends StatelessWidget {
  double fcr;
  int umur;

  StatisticsSection({
    Key? key,
    required this.fcr,
    required this.umur
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: WeightChartCard()),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _InfoCard(
                    icon: Icons.edit_note_outlined,
                    iconColor: Colors.orange,
                    label: 'FCR',
                    // menampilkan fcr dengan 2 angka dibelakang koma
                    value: fcr.toStringAsFixed(2),
                    unit: '',
                  ),
                  const SizedBox(height: 5),
                  _InfoCard(
                    icon: Icons.calendar_month,
                    iconColor: Colors.purple,
                    label: 'Umur',
                    // menampilkan umur
                    value: umur.toString(),
                    unit: 'Hari',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Anda bisa menamai ulang class ini, misalnya menjadi _WeightChartCard

class WeightChartCard extends StatefulWidget {
  WeightChartCard({super.key});

  @override
  State<WeightChartCard> createState() => _WeightChartCardState();
}

class _WeightChartCardState extends State<WeightChartCard> {

  // Inisialisasi FirebaseService
  final FirebaseService _firebaseService = FirebaseService();
  // Inisialisasi FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String _errorMessage = '';
  String? _activePeriodId;

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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat periode: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.white.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activePeriodId == null
              ? const Center(
                  child: Text(
                    'Belum ada periode aktif',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : StreamBuilder<List<FlSpot>>(
                  // Stream data bobot ayam yang nantinya ditampilkan grafik pertumbuhannya
                  stream: _firebaseService.getWeightStream(_activePeriodId!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      print(snapshot.data);
                      final flSpot = snapshot.data ?? [];

                      // Cek apakah data bobot ayam kosong
                      if (flSpot.isEmpty) {
                        return const Center(
                          child: Text(
                            'Data recording belum diisi',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      // Ambil data bobot terakhir untuk ditampilkan
                      final lastWeight = flSpot.isEmpty ? 0 : flSpot.last.y;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.show_chart,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Bobot Ayam',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 70,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: flSpot,
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            // menampilkan bobot ayam terakhir
                            '$lastWeight',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Gram', style: TextStyle(color: Colors.grey)),
                        ],
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(unit),
            ],
          ),
        ],
      ),
    );
  }
}
