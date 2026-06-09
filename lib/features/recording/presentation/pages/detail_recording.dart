import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recording_app/core/components/buttons/circle_icon_button.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/features/recording/data/models/fcr_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';

/// Halaman yang menampilkan semua data recording beserta tombol Edit di tiap baris.
class DetailRecording extends StatefulWidget {
  final List<RecordingData>? recordings;
  final bool readOnly;

  const DetailRecording({super.key, this.recordings, this.readOnly = false});

  @override
  State<DetailRecording> createState() => _DetailRecordingState();
}

class _DetailRecordingState extends State<DetailRecording> {
  @override
  void initState() {
    super.initState();
    if (widget.recordings == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<RecordingController>().loadActivePeriod();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecordingController>();

    return Scaffold(
      appBar: AppHeader(
        title: widget.readOnly ? 'Laporan Recording' : 'Semua Recording',
      ),
      body: Builder(
        builder: (context) {
          if (widget.recordings != null) {
            final fcrResults = controller.calculateWeeklyFCR(
              widget.recordings!,
            );
            return _RecordingTable(
              recordings: widget.recordings!,
              controller: controller,
              fcrResults: fcrResults,
              readOnly: widget.readOnly,
            );
          }

          if (controller.isLoadingPeriod) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.recordingsStream == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada data recording',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final fcrResults = controller.calculateWeeklyFCR(recordings);
              return _RecordingTable(
                recordings: recordings,
                controller: controller,
                fcrResults: fcrResults,
                readOnly: widget.readOnly,
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RecordingTable
// ─────────────────────────────────────────────────────────────────────────────

class _RecordingTable extends StatefulWidget {
  const _RecordingTable({
    required this.recordings,
    required this.controller,
    required this.fcrResults,
    this.readOnly = false,
  });

  final List<RecordingData> recordings;
  final RecordingController controller;
  final List<FCRData> fcrResults;
  final bool readOnly;

  @override
  State<_RecordingTable> createState() => _RecordingTableState();
}

class _RecordingTableState extends State<_RecordingTable> {
  // --- filter controllers ---
  final _dayMinCtrl = TextEditingController();
  final _dayMaxCtrl = TextEditingController();
  final _weightMinCtrl = TextEditingController();
  final _weightMaxCtrl = TextEditingController();
  final _feedMinCtrl = TextEditingController();
  final _feedMaxCtrl = TextEditingController();
  final _mortMinCtrl = TextEditingController();
  final _mortMaxCtrl = TextEditingController();

  // --- sort state ---
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

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

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  List<RecordingData> get _filtered {
    final dayMin = _int(_dayMinCtrl);
    final dayMax = _int(_dayMaxCtrl);
    final wMin = _int(_weightMinCtrl);
    final wMax = _int(_weightMaxCtrl);
    final fMin = _int(_feedMinCtrl);
    final fMax = _int(_feedMaxCtrl);
    final mMin = _int(_mortMinCtrl);
    final mMax = _int(_mortMaxCtrl);

    var list =
        widget.recordings.where((r) {
          if (dayMin != null && r.day < dayMin) return false;
          if (dayMax != null && r.day > dayMax) return false;
          if (wMin != null && r.avgWeightGram < wMin) return false;
          if (wMax != null && r.avgWeightGram > wMax) return false;
          if (fMin != null && r.feedSack < fMin) return false;
          if (fMax != null && r.feedSack > fMax) return false;
          if (mMin != null && r.mortality < mMin) return false;
          if (mMax != null && r.mortality > mMax) return false;
          return true;
        }).toList();

    list.sort((a, b) {
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

    return list;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void _resetFilters() {
    _dayMinCtrl.clear();
    _dayMaxCtrl.clear();
    _weightMinCtrl.clear();
    _weightMaxCtrl.clear();
    _feedMinCtrl.clear();
    _feedMaxCtrl.clear();
    _mortMinCtrl.clear();
    _mortMaxCtrl.clear();
    setState(() {});
  }

  // ── Filter row widget ──────────────────────────────────────────────────────

  Widget _filterRow(
    String label,
    TextEditingController minC,
    TextEditingController maxC,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    InputDecoration inputDeco(String hint) => InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );

    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: minC,
            keyboardType: TextInputType.number,
            style: textTheme.bodyMedium,
            decoration: inputDeco('Min'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: maxC,
            keyboardType: TextInputType.number,
            style: textTheme.bodyMedium,
            decoration: inputDeco('Max'),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filtered = _filtered;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Period Summary — paling atas ───────────────────────────
              if (widget.fcrResults.isNotEmpty)
                _PeriodSummaryCard(
                  recordings: widget.recordings,
                  fcrResults: widget.fcrResults,
                ),
              const SizedBox(height: 12),

              // ── 2. Filter panel ───────────────────────────────────────────
              _RecordingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Filter',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _resetFilters,
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Reset', style: textTheme.labelLarge),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _filterRow(
                      'Hari',
                      _dayMinCtrl,
                      _dayMaxCtrl,
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 8),
                    _filterRow(
                      'Berat (g)',
                      _weightMinCtrl,
                      _weightMaxCtrl,
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 8),
                    _filterRow(
                      'Pakan (sak)',
                      _feedMinCtrl,
                      _feedMaxCtrl,
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 8),
                    _filterRow(
                      'Mati',
                      _mortMinCtrl,
                      _mortMaxCtrl,
                      colorScheme,
                      textTheme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── 3. Result count ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '${filtered.length} dari ${widget.recordings.length} data',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // ── 4. Table ──────────────────────────────────────────────────
              _RecordingCard(
                clipBehavior: Clip.antiAlias,
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columnSpacing: 20,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 52,
                    headingRowHeight: 46,
                    dividerThickness: 0.5,
                    // ── Header: primaryContainer ──────────────────────────
                    headingRowColor: WidgetStateProperty.all(
                      colorScheme.onPrimary,
                    ),
                    dataRowColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return colorScheme.primaryContainer.withOpacity(0.3);
                      }
                      return null;
                    }),
                    columns: [
                      DataColumn(
                        label: Text(
                          'Hari',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: Text(
                          'Berat (g)',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: Text(
                          'Pakan (sak)',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: Text(
                          'Mati',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      if (!widget.readOnly)
                        DataColumn(
                          label: Text(
                            'Edit',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                    rows:
                        filtered.map((rec) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Center(
                                  child: Text(
                                    '${rec.day}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    '${rec.avgWeightGram}',
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    '${rec.feedSack}',
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    '${rec.mortality}',
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                              if (!widget.readOnly)
                                DataCell(
                                  Center(
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: colorScheme.secondary,
                                      ),
                                      tooltip: 'Edit recording',
                                      onPressed:
                                          () => _showEditSheet(context, rec),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
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
      builder:
          (_) => _EditRecordingSheet(
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

class _RecordingCard extends StatelessWidget {
  const _RecordingCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: clipBehavior,
      child: Padding(
        padding: padding,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PeriodSummaryCard  —  primary background, onPrimary content
// ─────────────────────────────────────────────────────────────────────────────

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
    final textTheme = Theme.of(context).textTheme;
    final numFmt = NumberFormat.decimalPattern('id_ID');

    final last = fcrResults.last;
    final totalFeed = last.totalPakan;
    final totalMort = recordings.fold<int>(0, (sum, r) => sum + r.mortality);
    final sortedRecs = List<RecordingData>.from(recordings)
      ..sort((a, b) => a.day.compareTo(b.day));
    final finalWeight = sortedRecs.last.avgWeightGram;
    final fcr = last.fcr;

    // Warna konten di atas primary
    final onPrimary = colorScheme.onPrimary;
    final onPrimaryMuted = colorScheme.onPrimary.withOpacity(0.65);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header label
            Text(
              'Ringkasan Periode',
              style: textTheme.labelMedium?.copyWith(
                color: onPrimaryMuted,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Period Summary',
              style: textTheme.titleMedium?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Divider(color: onPrimary.withOpacity(0.2), height: 1, thickness: 1),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Total Feed',
                    value: '${numFmt.format(totalFeed)} kg',
                    icon: Icons.grass_outlined,
                    labelColor: onPrimaryMuted,
                    valueColor: onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    label: 'Total Mortality',
                    value: '${numFmt.format(totalMort)} ekor',
                    icon: Icons.remove_circle_outline,
                    labelColor: onPrimaryMuted,
                    valueColor: onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Final Avg Weight',
                    value: '${numFmt.format(finalWeight)} g',
                    icon: Icons.scale_outlined,
                    labelColor: onPrimaryMuted,
                    valueColor: onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    label: 'FCR',
                    value: fcr.toStringAsFixed(2),
                    icon: Icons.analytics_outlined,
                    labelColor: onPrimaryMuted,
                    valueColor: onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SummaryTile  —  tile di dalam PeriodSummaryCard
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.labelColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: labelColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: labelColor),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
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

// ─────────────────────────────────────────────────────────────────────────────
// _EditRecordingSheet — Dioptimalkan untuk Peternak Lapangan
// ─────────────────────────────────────────────────────────────────────────────

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
    _ctrlWeight = TextEditingController(
      text: '${widget.recording.avgWeightGram}',
    );
    _ctrlFeed = TextEditingController(text: '${widget.recording.feedSack}');
    // Jika data awal 0, tetap tampilkan 0 agar peternak sadar angka tersebut harus valid
    _ctrlMortality = TextEditingController(
      text: '${widget.recording.mortality}',
    );
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
      day: int.tryParse(_ctrlDay.text.trim()),
      avgWeightGram: int.tryParse(_ctrlWeight.text.trim()),
      feedSack: int.tryParse(_ctrlFeed.text.trim()),
      mortality: int.tryParse(_ctrlMortality.text.trim()),
    );

    await widget.onSave(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final padding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + padding),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  'Edit Recording',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildField(
              controller: _ctrlDay,
              label: 'Umur Ayam (Hari)',
              icon:
                  Icons
                      .calendar_today_rounded, // Mengganti ikon internet data saver
            ),
            const SizedBox(height: 16),

            _buildField(
              controller: _ctrlWeight,
              label:
                  'Berat Rata-Rata (Gram)', // Lebih jelas secara teknis lapangan
              icon: Icons.scale_rounded,
            ),
            const SizedBox(height: 16),

            _buildField(
              controller: _ctrlFeed,
              label:
                  'Pakan Terpakai (Sak)', // Mengganti kata "Habis pakan" yang kasual
              icon:
                  Icons
                      .inventory_2_rounded, // Mengganti ikon panah yang membingungkan
            ),
            const SizedBox(height: 16),

            _buildField(
              controller: _ctrlMortality,
              label:
                  'Jumlah Kematian (Ekor)', // Struktur kata diperbaiki, bukan "Mati ayam"
              icon:
                  Icons
                      .heart_broken_rounded, // Lebih merepresentasikan kematian/deplesi
              required:
                  true, // WAJIB diisi. Jika tidak ada yang mati, peternak harus isi 0.
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52, // Dipertebal sedikit agar mudah ditekan di lapangan
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _submit,
                child:
                    _isLoading
                        ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                        : Text(
                          'Simpan Perubahan',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.surface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
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
    return AppTextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: false,
        signed: false,
      ),
      // Memaksa keyboard hanya memunculkan angka. Menghindari peternak salah ketik simbol/huruf.
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      labelText: label,
      prefixIcon: icon,
      validator:
          required
              ? (v) {
                if (v == null || v.trim().isEmpty) {
                  return '$label tidak boleh kosong';
                }
                return null;
              }
              : null,
    );
  }
}
