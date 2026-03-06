import 'package:flutter/material.dart';

import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

class RecordingTable extends StatefulWidget {
  final PeriodReport report;
  const RecordingTable({super.key, required this.report});

  @override
  State<RecordingTable> createState() => _RecordingTableState();
}

class _RecordingTableState extends State<RecordingTable> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final recordings = List<RecordingData>.from(widget.report.recordings);

    // sorting
    recordings.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.day.compareTo(b.day);
          break;
        case 1:
          cmp = a.avgWeightGram.compareTo(b.avgWeightGram);
          break;
        case 2:
          cmp = a.feedSack.compareTo(b.feedSack);
          break;
        case 3:
          cmp = a.mortality.compareTo(b.mortality);
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });

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
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
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
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Card(
                    elevation: 8,
                    child: DataTable(
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      columnSpacing: 16,
                      headingRowColor: WidgetStateProperty.all(
                        cs.surface,
                      ),
                      columns: [
                        DataColumn(
                          label: const Text(
                            'Hari',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text(
                            'Berat (g)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text(
                            'Pakan (sak)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text(
                            'Mati',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                          onSort: _onSort,
                        ),
                      ],
                      rows:
                          recordings.map((r) {
                            return DataRow(
                              cells: [
                                DataCell(Text('${r.day}')),
                                DataCell(Text('${r.avgWeightGram}')),
                                DataCell(Text('${r.feedSack}')),
                                DataCell(Text('${r.mortality}')),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
