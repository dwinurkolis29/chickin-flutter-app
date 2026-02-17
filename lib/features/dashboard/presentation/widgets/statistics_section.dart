import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticsSection extends StatelessWidget {
  final double fcr;
  final int umur;
  final Stream<List<FlSpot>>? weightStream;

  const StatisticsSection({
    Key? key,
    required this.fcr,
    required this.umur,
    required this.weightStream,
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
            Expanded(
              flex: 2,
              child: WeightChartCard(weightStream: weightStream),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _InfoCard(
                    icon: Icons.edit_note_outlined,
                    iconColor: Colors.orange,
                    label: 'FCR',
                    value: fcr.toStringAsFixed(2),
                    unit: '',
                  ),
                  const SizedBox(height: 5),
                  _InfoCard(
                    icon: Icons.calendar_month,
                    iconColor: Colors.purple,
                    label: 'Umur',
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

class WeightChartCard extends StatelessWidget {
  final Stream<List<FlSpot>>? weightStream;

  const WeightChartCard({
    super.key,
    required this.weightStream,
  });

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
      child: weightStream == null
          ? const Center(
              child: Text(
                'Belum ada periode aktif',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : StreamBuilder<List<FlSpot>>(
              stream: weightStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
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
                  final lastWeight = flSpot.last.y;

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
                        '$lastWeight',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Gram',
                          style: TextStyle(color: Colors.grey)),
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
