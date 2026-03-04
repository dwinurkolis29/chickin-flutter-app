import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/features/recording/data/models/fcr_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';

/// Halaman yang menampilkan semua data recording beserta tombol Edit di tiap baris.
class DetailRecording extends StatelessWidget {
  const DetailRecording({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecordingController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Recording'),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          // Fase 1: controller sedang loadActivePeriod() — stream belum tersedia
          if (controller.isLoadingPeriod) {
            return const Center(child: CircularProgressIndicator());
          }

          // Fase 2: tidak ada periode aktif
          if (controller.recordingsStream == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada periode aktif',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          // Fase 3: stream tersedia — pantau data
          return StreamBuilder<List<RecordingData>>(
            stream: controller.recordingsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
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
                    ],
                  ),
                );
              }

              final fcrResults = controller.calculateWeeklyFCR(recordings);
              return _RecordingTable(recordings: recordings, controller: controller, fcrResults: fcrResults);
            },
          );
        },
      ),
    );
  }
}

class _RecordingTable extends StatefulWidget {
  const _RecordingTable({
    required this.recordings,
    required this.controller,
    required this.fcrResults,
  });

  final List<RecordingData> recordings;
  final RecordingController controller;
  final List<FCRData> fcrResults;

  @override
  State<_RecordingTable> createState() => _RecordingTableState();
}

class _RecordingTableState extends State<_RecordingTable> {
  // --- filter controllers ---
  final _dayMinCtrl    = TextEditingController();
  final _dayMaxCtrl    = TextEditingController();
  final _weightMinCtrl = TextEditingController();
  final _weightMaxCtrl = TextEditingController();
  final _feedMinCtrl   = TextEditingController();
  final _feedMaxCtrl   = TextEditingController();
  final _mortMinCtrl   = TextEditingController();
  final _mortMaxCtrl   = TextEditingController();

  // --- sort state ---
  int _sortColumnIndex = 0;
  bool _sortAscending  = true;

  @override
  void dispose() {
    _dayMinCtrl.dispose();
    _dayMaxCtrl.dispose();
    _weightMinCtrl.dispose();
    _weightMaxCtrl.dispose();
    _feedMinCtrl.dispose();
    _feedMaxCtrl.dispose();
    _mortMinCtrl.dispose();
    _mortMaxCtrl.dispose();
    super.dispose();
  }

  // Parse helper — null means "no filter"
  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  List<RecordingData> get _filtered {
    final dayMin    = _int(_dayMinCtrl);
    final dayMax    = _int(_dayMaxCtrl);
    final wMin      = _int(_weightMinCtrl);
    final wMax      = _int(_weightMaxCtrl);
    final fMin      = _int(_feedMinCtrl);
    final fMax      = _int(_feedMaxCtrl);
    final mMin      = _int(_mortMinCtrl);
    final mMax      = _int(_mortMaxCtrl);

    var list = widget.recordings.where((r) {
      if (dayMin != null && r.day < dayMin) return false;
      if (dayMax != null && r.day > dayMax) return false;
      if (wMin   != null && r.avgWeightGram < wMin) return false;
      if (wMax   != null && r.avgWeightGram > wMax) return false;
      if (fMin   != null && r.feedSack < fMin) return false;
      if (fMax   != null && r.feedSack > fMax) return false;
      if (mMin   != null && r.mortality < mMin) return false;
      if (mMax   != null && r.mortality > mMax) return false;
      return true;
    }).toList();

    // sort
    list.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0: cmp = a.day.compareTo(b.day); break;
        case 1: cmp = a.avgWeightGram.compareTo(b.avgWeightGram); break;
        case 2: cmp = a.feedSack.compareTo(b.feedSack); break;
        case 3: cmp = a.mortality.compareTo(b.mortality); break;
        default: cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending   = ascending;
    });
  }

  Widget _filterRow(String label, TextEditingController minC, TextEditingController maxC) {
    const inputDeco = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(),
      hintText: '–',
    );
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: minC,
            keyboardType: TextInputType.number,
            decoration: inputDeco.copyWith(labelText: 'Min'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: maxC,
            keyboardType: TextInputType.number,
            decoration: inputDeco.copyWith(labelText: 'Max'),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered    = _filtered;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // ── Filter panel ────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.filter_list, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Filter',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              _dayMinCtrl.clear();
                              _dayMaxCtrl.clear();
                              _weightMinCtrl.clear();
                              _weightMaxCtrl.clear();
                              _feedMinCtrl.clear();
                              _feedMaxCtrl.clear();
                              _mortMinCtrl.clear();
                              _mortMaxCtrl.clear();
                              setState(() {});
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _filterRow('Hari',       _dayMinCtrl,    _dayMaxCtrl),
                      const SizedBox(height: 8),
                      _filterRow('Berat (g)',  _weightMinCtrl, _weightMaxCtrl),
                      const SizedBox(height: 8),
                      _filterRow('Pakan (sak)',_feedMinCtrl,   _feedMaxCtrl),
                      const SizedBox(height: 8),
                      _filterRow('Mati',       _mortMinCtrl,   _mortMaxCtrl),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ── Result count ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${filtered.length} dari ${widget.recordings.length} data',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 4),
              // ── Period Summary ────────────────────────────────────────────
              if (widget.fcrResults.isNotEmpty)
                _PeriodSummaryCard(
                  recordings: widget.recordings,
                  fcrResults: widget.fcrResults,
                ),
              const SizedBox(height: 4),
              // ── Table ─────────────────────────────────────────────────────
              Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Card(
                  elevation: 8,
                  child: DataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columnSpacing: 16,
                    headingRowColor: WidgetStateProperty.all(
                      colorScheme.secondaryContainer,
                    ),
                    columns: [
                      DataColumn(
                        label: const Text('Hari', style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Berat (g)', style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Pakan (sak)', style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Mati', style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      const DataColumn(
                        label: Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                    rows: filtered.map((rec) {
                      return DataRow(cells: [
                        DataCell(Text('${rec.day}')),
                        DataCell(Text('${rec.avgWeightGram}')),
                        DataCell(Text('${rec.feedSack}')),
                        DataCell(Text('${rec.mortality}')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Edit recording',
                            onPressed: () => _showEditSheet(context, rec),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, RecordingData recording) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditRecordingSheet(
        recording: recording,
        onSave: (updated) async {
          try {
            await widget.controller.updateRecording(updated);
            if (context.mounted) {
              AppSnackbar.showSuccess(context, 'Data berhasil diperbarui');
            }
          } catch (e) {
            if (context.mounted) {
              AppSnackbar.showError(context, 'Gagal memperbarui data: $e');
            }
          }
        },
      ),
    );
  }
}


/// Bottom sheet form untuk mengedit satu baris recording.
class _EditRecordingSheet extends StatefulWidget {
  const _EditRecordingSheet({required this.recording, required this.onSave});

  final RecordingData recording;
  final Future<void> Function(RecordingData updated) onSave;

  @override
  State<_EditRecordingSheet> createState() => _EditRecordingSheetState();
}

class _EditRecordingSheetState extends State<_EditRecordingSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _ctrlDay;
  late final TextEditingController _ctrlWeight;
  late final TextEditingController _ctrlFeed;
  late final TextEditingController _ctrlMortality;

  @override
  void initState() {
    super.initState();
    _ctrlDay = TextEditingController(text: '${widget.recording.day}');
    _ctrlWeight = TextEditingController(text: '${widget.recording.avgWeightGram}');
    _ctrlFeed = TextEditingController(text: '${widget.recording.feedSack}');
    _ctrlMortality = TextEditingController(text: '${widget.recording.mortality}');
  }

  @override
  void dispose() {
    _ctrlDay.dispose();
    _ctrlWeight.dispose();
    _ctrlFeed.dispose();
    _ctrlMortality.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final updated = widget.recording.copyWith(
      day: int.tryParse(_ctrlDay.text),
      avgWeightGram: int.tryParse(_ctrlWeight.text),
      feedSack: int.tryParse(_ctrlFeed.text),
      mortality: int.tryParse(_ctrlMortality.text),
    );

    await widget.onSave(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + padding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Edit Recording', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _ctrlDay,
              label: 'Umur Ayam (hari)',
              icon: Icons.data_saver_on_rounded,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _ctrlWeight,
              label: 'Berat Ayam (gram)',
              icon: Icons.scale,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _ctrlFeed,
              label: 'Habis pakan (sak)',
              icon: Icons.arrow_circle_up,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _ctrlMortality,
              label: 'Mati ayam (Ekor)',
              icon: Icons.highlight_remove,
              required: false,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? '$label tidak boleh kosong.' : null
          : null,
    );
  }
}

class _PeriodSummaryCard extends StatelessWidget {
  const _PeriodSummaryCard({
    required this.recordings,
    required this.fcrResults,
  });

  final List<RecordingData> recordings;
  final List<FCRData> fcrResults;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final numFmt      = NumberFormat.decimalPattern('id_ID');

    final last         = fcrResults.last;
    final totalFeed    = last.totalPakan;
    final totalMort    = recordings.fold<int>(0, (sum, r) => sum + r.mortality);
    final sortedRecs   = List<RecordingData>.from(recordings)..sort((a, b) => a.day.compareTo(b.day));
    final finalWeight  = sortedRecs.last.avgWeightGram;
    final fcr          = last.fcr;

    return Card.filled(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Period Summary',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.8,
              children: [
                _SummaryTile(
                  label: 'Total Feed',
                  value: '${numFmt.format(totalFeed)} kg',
                  icon: Icons.grass_outlined,
                  color: colorScheme.onSecondaryContainer,
                ),
                _SummaryTile(
                  label: 'Total Mortality',
                  value: '${numFmt.format(totalMort)} ekor',
                  icon: Icons.remove_circle_outline,
                  color: colorScheme.onSecondaryContainer,
                ),
                _SummaryTile(
                  label: 'Final Avg Weight',
                  value: '${numFmt.format(finalWeight)} g',
                  icon: Icons.scale_outlined,
                  color: colorScheme.onSecondaryContainer,
                ),
                _SummaryTile(
                  label: 'FCR',
                  value: fcr.toStringAsFixed(2),
                  icon: Icons.analytics_outlined,
                  color: colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color.withOpacity(0.7),
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
