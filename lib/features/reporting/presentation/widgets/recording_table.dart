import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';

class RecordingTable extends StatelessWidget {
  final PeriodReport report;
  const RecordingTable({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final recordings = report.recordings;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(Icons.table_rows_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Rekap Harian',
                  style: tt.labelLarge?.copyWith(color: cs.onSurface),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          if (recordings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Tidak ada data recording',
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurface.withOpacity(0.5)),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  cs.primary.withOpacity(0.08),
                ),
                headingTextStyle: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
                dataTextStyle: tt.bodySmall?.copyWith(color: cs.onSurface),
                columnSpacing: 24,
                horizontalMargin: 16,
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(label: Text('Hari')),
                  DataColumn(label: Text('Mati'), numeric: true),
                  DataColumn(label: Text('Sak Pakan'), numeric: true),
                  DataColumn(label: Text('Bobot (g)'), numeric: true),
                ],
                rows: recordings
                    .map(
                      (r) => DataRow(cells: [
                        DataCell(Text('Hari ${r.day}')),
                        DataCell(Text('${r.mortality}')),
                        DataCell(Text('${r.feedSack}')),
                        DataCell(Text(
                            NumberFormat('#,###').format(r.avgWeightGram))),
                      ]),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
