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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // membungkus tabel dengan card
      child: Card.filled(
        color: colorScheme.surfaceBright,
        // membuat shadow pada card
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              child: Text(
                'FCR Data',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 5),
            DataTable(
              columnSpacing: 20,
              headingRowHeight: 50,
              dataRowHeight: 45,
              columns: [
                // membuat header tabel
                DataColumn(
                  label: Text(
                    'Minggu',
                    style: textTheme.labelMedium,
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Total Pakan (kg)',
                    style: textTheme.labelMedium,
                    textAlign: TextAlign.end,
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Sisa Ayam (ekor)',
                    style: textTheme.labelMedium,
                    textAlign: TextAlign.end,
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Berat Ayam (kg)',
                    style: textTheme.labelMedium,
                    textAlign: TextAlign.end,
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'FCR',
                    style: textTheme.labelMedium,
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