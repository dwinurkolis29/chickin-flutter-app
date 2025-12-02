import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/fcr_data.dart';

class FCRDataTable extends StatelessWidget {

  // membuat list fcr data
  final List<FCRData> fcrData;

  const FCRDataTable({
    Key? key,
    required this.fcrData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormat = NumberFormat.decimalPattern('id_ID');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // membungkus tabel dengan card
      child: Card.filled(
        color: Colors.white,
        // membuat shadow pada card
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              child: const Text(
                'FCR Data',
                style: TextStyle(
                  fontSize: 20,
                  // fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 5),
            DataTable(
              columnSpacing: 20,
              headingRowHeight: 50,
              dataRowHeight: 45,
              columns: const [
                // membuat header tabel
                DataColumn(
                  label: Text(
                    'Minggu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Total Pakan (kg)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Sisa Ayam (ekor)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Berat Ayam (kg)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'FCR',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                  numeric: true,
                ),
              ],
              // membuat isi tabel berdasarkan list fcr data
              rows: fcrData.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text('Minggu ${data.mingguKe}')),
                    DataCell(
                      Text(
                        numberFormat.format(data.totalPakan),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    DataCell(
                      Text(
                        numberFormat.format(data.sisaAyam),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    DataCell(
                      Text(
                        numberFormat.format(data.beratAyam),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    DataCell(
                      Text(
                        numberFormat.format(data.fcr),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}