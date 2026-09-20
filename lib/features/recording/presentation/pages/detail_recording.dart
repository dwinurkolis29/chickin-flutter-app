import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/dialogs/app_form_bottom_sheet.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/loading/shimmer_loading.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/period/data/models/harvest_record.dart';
import 'package:recording_app/features/period/data/models/hospital_pen_data.dart';
import 'package:recording_app/features/period/presentation/screens/form_period.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_feed_intake.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_separated_flock.dart';
import 'package:recording_app/features/recording/domain/usecases/recording_validator.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';
import 'package:recording_app/features/recording/presentation/pages/form_recording.dart';
import 'package:recording_app/features/recording/presentation/pages/sekat_seleksian_screen.dart';

/// Halaman yang menampilkan daftar lengkap catatan recording harian.
/// Didesain mobile-first dengan kartu interaktif yang mudah dibaca dan diedit oleh peternak.
class DetailRecording extends StatefulWidget {
  final List<RecordingData>? recordings;
  final bool readOnly;
  final int? initialCapacity;
  final List<HarvestRecord>? harvests;

  const DetailRecording({
    super.key,
    this.recordings,
    this.readOnly = false,
    this.initialCapacity,
    this.harvests,
  });

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
        actions: [
          if (!widget.readOnly)
            IconButton(
              icon: const Icon(Icons.fence_outlined, size: 22),
              tooltip: 'Sekat Seleksian',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SekatSeleksianScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton:
          widget.readOnly
              ? null
              : FloatingActionButton.extended(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Tambah Recording',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FormRecording()),
                  );
                },
              ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (widget.recordings != null) {
              if (widget.recordings!.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.assignment_outlined,
                  message: 'Belum Ada Data Recording',
                  subtitle:
                      'Riwayat catatan harian pemeliharaan akan ditampilkan di sini.',
                );
              }
              return _RecordingListView(
                recordings: widget.recordings!,
                controller: controller,
                readOnly: widget.readOnly,
                initialCapacity: widget.initialCapacity,
                harvests: widget.harvests,
              );
            }

            if (controller.isLoadingPeriod) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: TableSkeleton(),
              );
            }

            if (controller.recordingsStream == null) {
              return AppEmptyState(
                icon: Icons.calendar_today_outlined,
                message: 'Tidak Ada Periode Aktif',
                subtitle:
                    'Buat atau aktifkan siklus pemeliharaan terlebih dahulu untuk mulai mencatat harian.',
                actionLabel: 'Buat Periode Baru',
                onAction:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FormPeriod()),
                    ),
              );
            }

            return StreamBuilder<List<RecordingData>>(
              stream: controller.recordingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: TableSkeleton(),
                  );
                }

                if (snapshot.hasError) {
                  return AppErrorState(
                    message: 'Gagal memuat data recording',
                    subtitle: snapshot.error.toString(),
                    onRetry: () => controller.loadActivePeriod(),
                  );
                }

                final recordings = snapshot.data ?? <RecordingData>[];

                if (recordings.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.assignment_outlined,
                    message: 'Belum Ada Catatan Harian',
                    subtitle:
                        'Mulai input konsumsi pakan, kematian, dan penimbangan bobot ayam untuk hari ini.',
                    actionLabel:
                        widget.readOnly ? null : 'Isi Catatan Hari Ini',
                    onAction:
                        widget.readOnly ? null : () => Navigator.pop(context),
                  );
                }

                return _RecordingListView(
                  recordings: recordings,
                  controller: controller,
                  readOnly: widget.readOnly,
                  initialCapacity: widget.initialCapacity,
                  harvests: widget.harvests,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RecordingListView
// ─────────────────────────────────────────────────────────────────────────────

class _RecordingListView extends StatefulWidget {
  const _RecordingListView({
    required this.recordings,
    required this.controller,
    this.readOnly = false,
    this.initialCapacity,
    this.harvests,
  });

  final List<RecordingData> recordings;
  final RecordingController controller;
  final bool readOnly;
  final int? initialCapacity;
  final List<HarvestRecord>? harvests;

  @override
  State<_RecordingListView> createState() => _RecordingListViewState();
}

class _RecordingListViewState extends State<_RecordingListView> {
  final _searchCtrl = TextEditingController();

  /// 0 = Semua, 1 = Minggu 1, 2 = Minggu 2, 3 = Minggu 3, 4 = Minggu 4+, -1 = Ada Kematian
  int _selectedWeekFilter = 0;

  /// Default true: Hari terbaru tampil paling atas (H-terakhir -> H-1)
  bool _sortDescending = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RecordingData> get _filteredRecordings {
    final query = _searchCtrl.text.trim().toLowerCase();
    final searchDay = int.tryParse(query);

    var list =
        widget.recordings.where((r) {
          // 1. Filter Search (hari / query)
          if (query.isNotEmpty) {
            if (searchDay != null) {
              if (r.day != searchDay) return false;
            } else {
              final dayStr = 'hari ${r.day}';
              if (!dayStr.contains(query)) return false;
            }
          }

          // 2. Filter Tab / Chip
          if (_selectedWeekFilter == 1) {
            if (r.day < 1 || r.day > 7) return false;
          } else if (_selectedWeekFilter == 2) {
            if (r.day < 8 || r.day > 14) return false;
          } else if (_selectedWeekFilter == 3) {
            if (r.day < 15 || r.day > 21) return false;
          } else if (_selectedWeekFilter == 4) {
            if (r.day < 22) return false;
          } else if (_selectedWeekFilter == -1) {
            if (r.mortality <= 0) return false;
          }

          return true;
        }).toList();

    // 3. Sorting
    list.sort((a, b) {
      return _sortDescending ? b.day.compareTo(a.day) : a.day.compareTo(b.day);
    });

    return list;
  }

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _selectedWeekFilter = 0;
      _sortDescending = true;
    });
  }

  void _showEditSheet(BuildContext context, RecordingData recording) {
    AppFormBottomSheet.show(
      context: context,
      title: 'Edit Recording',
      subtitle:
          'Sesuaikan catatan umur, pakan, bobot, atau kematian ayam hari ke-${recording.day}:',
      icon: Icons.edit_note_rounded,
      builder: (sheetContext, setModalState) {
        return _EditRecordingSheet(
          recording: recording,
          allRecordings: widget.recordings,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final filtered = _filteredRecordings;

    final initialCap = widget.initialCapacity ??
        (widget.controller.initialPopulation > 0
            ? widget.controller.initialPopulation
            : 1000);
    final harvestList = widget.harvests ??
        widget.controller.activePeriod?.summary?.harvests ??
        const <HarvestRecord>[];

    final feedIntakeMap = const CalculateFeedIntake().execute(
      recordings: widget.recordings,
      initialCapacity: initialCap,
      harvests: harvestList,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: CustomScrollView(
          slivers: [
            // ── Sticky / Header Filter Panel ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchCtrl,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Cari umur ayam / hari ke-...',
                        hintStyle: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: cs.primary,
                        ),
                        suffixIcon:
                            _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                                : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Quick Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(label: 'Semua', filterValue: 0),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Minggu 1 (H1-7)',
                            filterValue: 1,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Minggu 2 (H8-14)',
                            filterValue: 2,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Minggu 3 (H15-21)',
                            filterValue: 3,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Minggu 4+ (H22+)',
                            filterValue: 4,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Ada Kematian',
                            filterValue: -1,
                            isWarning: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Baris Status & Sort Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Menampilkan ${filtered.length} dari ${widget.recordings.length} hari',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _sortDescending = !_sortDescending;
                            });
                          },
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _sortDescending
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 16,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _sortDescending
                                      ? 'Hari Terbaru'
                                      : 'Hari Terlama',
                                  style: tt.labelMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Sekat Seleksian Banner (Jika Terisi) ──────────────────────────
            if (widget.controller.hospitalPen != null &&
                widget.controller.hospitalPen!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildHospitalPenBanner(
                    context: context,
                    hospitalPen: widget.controller.hospitalPen!,
                    initialCapacity: initialCap,
                    readOnly: widget.readOnly,
                  ),
                ),
              ),

            // ── List Catatan Harian ───────────────────────────────────────────
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_alt_off_rounded,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada data yang cocok dengan filter',
                          style: tt.titleSmall?.copyWith(color: cs.onSurface),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _resetFilters,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.pillRadius,
                              ),
                            ),
                          ),
                          child: const Text('Reset Filter'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final rec = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecordingDayCard(
                        recording: rec,
                        feedIntake: feedIntakeMap[rec.day],
                        hospitalPen: widget.controller.hospitalPen,
                        initialCapacity: initialCap,
                        allRecordings: widget.recordings,
                        readOnly: widget.readOnly,
                        onEdit: () => _showEditSheet(context, rec),
                      ),
                    );
                  }, childCount: filtered.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int filterValue,
    bool isWarning = false,
  }) {
    final isSelected = _selectedWeekFilter == filterValue;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      labelStyle: tt.labelMedium?.copyWith(
        color:
            isSelected
                ? cs.onPrimary
                : (isWarning ? AppColors.error : cs.onSurfaceVariant),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      backgroundColor:
          isWarning
              ? AppColors.error.withValues(alpha: 0.08)
              : cs.surfaceContainer,
      selectedColor: isWarning ? AppColors.error : cs.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        side: BorderSide(
          color:
              isSelected
                  ? (isWarning ? AppColors.error : cs.primary)
                  : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedWeekFilter = filterValue;
        });
      },
    );
  }

  Widget _buildHospitalPenBanner({
    required BuildContext context,
    required HospitalPenData hospitalPen,
    required int initialCapacity,
    required bool readOnly,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final numFmt = NumberFormat.decimalPattern('id_ID');

    final totalMortality = widget.recordings.fold<int>(
      0,
      (sum, r) => sum + r.mortality,
    );
    final totalHarvested =
        widget.controller.activePeriod?.summary?.harvestedChicks ?? 0;
    final currentLive = (initialCapacity - totalMortality - totalHarvested)
        .clamp(0, initialCapacity);

    final summary = const CalculateSeparatedFlock().execute(
      totalLiveBirds: currentLive,
      regularAvgWeightGram: 0,
      hospitalPen: hospitalPen,
    );

    final Color statusColor;
    final Color statusBg;
    switch (summary.status) {
      case SeparatedFlockStatus.normal:
        statusColor = AppColors.success;
        statusBg = AppColors.success.withValues(alpha: 0.12);
        break;
      case SeparatedFlockStatus.warning:
        statusColor = AppColors.warning;
        statusBg = AppColors.warning.withValues(alpha: 0.12);
        break;
      case SeparatedFlockStatus.danger:
        statusColor = AppColors.error;
        statusBg = AppColors.error.withValues(alpha: 0.12);
        break;
    }

    return AppCard(
      child: InkWell(
        onTap: readOnly
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SekatSeleksianScreen(),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.health_and_safety_outlined,
                  size: 20,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Sekat: ${hospitalPen.count} ekor (${numFmt.format(hospitalPen.avgWeightGram)} g)',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            summary.statusLabel,
                            style: tt.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.sekatPercentage.toStringAsFixed(1)}% populasi • Hari ke-${hospitalPen.day}${hospitalPen.conditions.isNotEmpty ? ' (${hospitalPen.conditions.join(', ')})' : ''}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!readOnly) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RecordingDayCard  —  Kartu Ringkasan Harian Ramah Peternak
// ─────────────────────────────────────────────────────────────────────────────

class _RecordingDayCard extends StatelessWidget {
  const _RecordingDayCard({
    required this.recording,
    this.feedIntake,
    this.hospitalPen,
    this.initialCapacity,
    this.allRecordings,
    required this.readOnly,
    required this.onEdit,
  });

  final RecordingData recording;
  final DailyFeedIntake? feedIntake;
  final HospitalPenData? hospitalPen;
  final int? initialCapacity;
  final List<RecordingData>? allRecordings;
  final bool readOnly;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final numFmt = NumberFormat.decimalPattern('id_ID');
    final dateFmt = DateFormat('dd MMM yyyy');

    final weekNum = ((recording.day - 1) ~/ 7) + 1;
    final hasMortality = recording.mortality > 0;

    final feedSackText = recording.feedSack % 1 == 0
        ? '${recording.feedSack.toInt()} sak'
        : '${recording.feedSack.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} sak';
    final feedKg = recording.feedSack * 50.0;
    final feedKgText = feedKg % 1 == 0
        ? '~${feedKg.toInt()} kg'
        : '~${feedKg.toStringAsFixed(1)} kg';

    return AppCard(
      child: InkWell(
        onTap: readOnly ? null : onEdit,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Kartu: Badge Hari & Tombol Edit ─────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Badge Hari
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    ),
                    child: Text(
                      'Hari ${recording.day}',
                      style: tt.titleSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Info Minggu & Tanggal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Minggu ke-$weekNum',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          dateFmt.format(recording.createdAt),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tombol Edit
                  if (!readOnly)
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        side: BorderSide(
                          color: cs.primary.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 14),

              // ── 3 Metrik Fisik Utama ──────────────────────────────────────
              Row(
                children: [
                  // 1. Bobot Rata-rata
                  Expanded(
                    child: _buildMetricTile(
                      context: context,
                      icon: Icons.scale_rounded,
                      iconBgColor: cs.secondaryContainer,
                      iconColor: cs.primary,
                      label: 'Bobot Ayam',
                      value:
                          recording.avgWeightGram > 0
                              ? '${numFmt.format(recording.avgWeightGram)} g'
                              : '-',
                      subtitle:
                          recording.avgWeightGram > 0
                              ? '${(recording.avgWeightGram / 1000).toStringAsFixed(2)} kg'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Pakan Terpakai
                  Expanded(
                    child: _buildMetricTile(
                      context: context,
                      icon: Icons.inventory_2_rounded,
                      iconBgColor: cs.secondaryContainer,
                      iconColor: cs.primary,
                      label: 'Pakan',
                      value: feedSackText,
                      subtitle: feedKgText,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Kematian (Mortalitas)
                  Expanded(
                    child: _buildMetricTile(
                      context: context,
                      icon:
                          hasMortality
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                      iconBgColor:
                          hasMortality
                              ? AppColors.error.withValues(alpha: 0.12)
                              : AppColors.success.withValues(alpha: 0.12),
                      iconColor:
                          hasMortality ? AppColors.error : AppColors.success,
                      label: 'Kematian',
                      value: '${recording.mortality} ekor',
                      valueColor: hasMortality ? AppColors.error : cs.onSurface,
                      subtitle: hasMortality ? 'Perlu dicek' : 'Aman',
                    ),
                  ),
                ],
              ),

              // ── Sekat Seleksian Sub-Info (Khusus Hari Sekat) ────────────────
              if (hospitalPen != null &&
                  hospitalPen!.day == recording.day &&
                  hospitalPen!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildHospitalPenStrip(context),
              ],

              // ── 4. Feed Intake (FI) Sub-Card ───────────────────────────────
              const SizedBox(height: 12),
              _buildFeedIntakeCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalPenStrip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final numFmt = NumberFormat.decimalPattern('id_ID');
    final hp = hospitalPen!;

    // Hitung estimasi populasi hidup di hari recording ini
    int cumulativeMortality = 0;
    for (final r in (allRecordings ?? [recording])) {
      if (r.day <= recording.day) {
        cumulativeMortality += r.mortality;
      }
    }
    final liveTotal = ((initialCapacity ?? 1000) - cumulativeMortality)
        .clamp(0, initialCapacity ?? 1000);

    final summary = const CalculateSeparatedFlock().execute(
      totalLiveBirds: liveTotal,
      regularAvgWeightGram: recording.avgWeightGram,
      hospitalPen: hp,
    );

    final Color statusColor;
    final Color statusBg;
    switch (summary.status) {
      case SeparatedFlockStatus.normal:
        statusColor = AppColors.success;
        statusBg = AppColors.success.withValues(alpha: 0.12);
        break;
      case SeparatedFlockStatus.warning:
        statusColor = AppColors.warning;
        statusBg = AppColors.warning.withValues(alpha: 0.12);
        break;
      case SeparatedFlockStatus.danger:
        statusColor = AppColors.error;
        statusBg = AppColors.error.withValues(alpha: 0.12);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fence_outlined,
              size: 18,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sekat Seleksian',
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      ),
                      child: Text(
                        summary.statusLabel,
                        style: tt.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${hp.count} ekor (${numFmt.format(hp.avgWeightGram)} g)  •  Rata-rata riil: ${numFmt.format(summary.weightedAvgWeightGram)} g',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedIntakeCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final numFmt = NumberFormat.decimalPattern('id_ID');
    final fi = feedIntake;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Badge (Circular secondaryContainer)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_rounded,
              size: 18,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header bar: Label & Warning Chip (if drop)
                Row(
                  children: [
                    Text(
                      'Konsumsi Pakan (FI)',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    if (fi != null && fi.isDrop) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_down_rounded,
                                size: 12,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'Nafsu makan turun (-${fi.dropPercentage.toStringAsFixed(0)}%)',
                                  style: tt.labelSmall?.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // Value Text: Harian & Kumulatif
                if (fi != null && fi.dailyGrams > 0)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${numFmt.format(fi.dailyGrams.round())} g',
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: '/ekor/hari  •  Kumulatif: ',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        TextSpan(
                          text: '${numFmt.format(fi.cumulativeGrams.round())} g',
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: '/ekor',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Belum ada konsumsi pakan dicatat',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    String? subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Icon (Tengah)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),

          // 2. Teks label (Tengah)
          Text(
            label,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // 3. Nilai Metrik (Tengah)
          Text(
            value,
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditRecordingSheet — Dioptimalkan untuk Peternak Lapangan
// ─────────────────────────────────────────────────────────────────────────────

class _EditRecordingSheet extends StatefulWidget {
  const _EditRecordingSheet({
    required this.recording,
    required this.allRecordings,
    required this.onSave,
  });

  final RecordingData recording;
  final List<RecordingData> allRecordings;
  final Future<void> Function(RecordingData updated) onSave;

  @override
  State<_EditRecordingSheet> createState() => _EditRecordingSheetState();
}

class _EditRecordingSheetState extends State<_EditRecordingSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String _feedUnit = 'Sak';
  String _weightUnit = 'Gram';

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
    final feedVal = widget.recording.feedSack;
    final feedStr =
        feedVal % 1 == 0 ? feedVal.toInt().toString() : feedVal.toString();
    _ctrlFeed = TextEditingController(text: feedStr);
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

  void _onFeedUnitChanged(String newUnit) {
    if (_feedUnit == newUnit) return;
    setState(() {
      final raw = _ctrlFeed.text.trim().replaceAll(',', '.');
      if (raw.isNotEmpty) {
        final val = double.tryParse(raw);
        if (val != null) {
          if (newUnit == 'Kg') {
            final kg = val * 50.0;
            _ctrlFeed.text =
                kg % 1 == 0 ? kg.toInt().toString() : kg.toStringAsFixed(1);
          } else {
            final sacks = val / 50.0;
            _ctrlFeed.text =
                sacks % 1 == 0
                    ? sacks.toInt().toString()
                    : sacks
                        .toStringAsFixed(2)
                        .replaceAll(RegExp(r'0+$'), '')
                        .replaceAll(RegExp(r'\.$'), '');
          }
        }
      }
      _feedUnit = newUnit;
    });
  }

  void _onWeightUnitChanged(String newUnit) {
    if (_weightUnit == newUnit) return;
    setState(() {
      final raw = _ctrlWeight.text.trim().replaceAll(',', '.');
      if (raw.isNotEmpty) {
        final val = double.tryParse(raw);
        if (val != null) {
          if (newUnit == 'Kg') {
            final kg = val / 1000.0;
            _ctrlWeight.text =
                kg % 1 == 0
                    ? kg.toInt().toString()
                    : kg
                        .toStringAsFixed(3)
                        .replaceAll(RegExp(r'0+$'), '')
                        .replaceAll(RegExp(r'\.$'), '');
          } else {
            final grams = (val * 1000).round();
            _ctrlWeight.text = grams.toString();
          }
        }
      }
      _weightUnit = newUnit;
    });
  }

  double get _parsedFeedSack {
    final raw = _ctrlFeed.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return 0.0;
    final val = double.tryParse(raw) ?? 0.0;
    if (_feedUnit == 'Sak') {
      return val;
    } else {
      return val / 50.0;
    }
  }

  int get _parsedWeightGram {
    final raw = _ctrlWeight.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return 0;
    final val = double.tryParse(raw) ?? 0.0;
    if (_weightUnit == 'Gram') {
      return val.round();
    } else {
      return (val * 1000).round();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final newDay = int.tryParse(_ctrlDay.text.trim()) ?? widget.recording.day;

    // Validasi duplikat hari (exclude recording yang sedang diedit)
    final isDuplicate = widget.allRecordings.any(
      (r) => r.id != widget.recording.id && r.day == newDay,
    );

    if (isDuplicate) {
      setState(() => _isLoading = false);
      if (mounted) {
        DialogHelper.showError(
          context,
          'Hari Sudah Ada',
          'Recording untuk hari ke-$newDay sudah ada. '
              'Setiap hari hanya boleh ada satu catatan dalam satu periode.',
        );
      }
      return;
    }

    final updated = widget.recording.copyWith(
      day: newDay,
      avgWeightGram: _parsedWeightGram,
      feedSack: _parsedFeedSack,
      mortality: int.tryParse(_ctrlMortality.text.trim()) ?? 0,
    );

    // Validasi anomali dan typo
    final initialPop =
        context.read<RecordingController>().initialPopulation > 0
            ? context.read<RecordingController>().initialPopulation
            : 1000;
    final anomalies = RecordingValidator.checkAnomalies(
      newRecording: updated,
      initialPopulation: initialPop,
      existingRecordings: widget.allRecordings,
    );

    for (final anomaly in anomalies) {
      if (anomaly.isBlocking) {
        setState(() => _isLoading = false);
        if (mounted) {
          DialogHelper.showError(context, anomaly.title, anomaly.message);
        }
        return;
      }
    }

    final nonBlocking = anomalies.where((a) => !a.isBlocking).toList();
    if (nonBlocking.isNotEmpty && mounted) {
      final messages = nonBlocking.map((a) => '• ${a.message}').join('\n\n');
      final isConfirmed = await DialogHelper.showConfirm(
        context,
        nonBlocking.length == 1
            ? nonBlocking.first.title
            : 'Peringatan Data Recording',
        '$messages\n\nApakah Anda yakin data ini sudah benar?',
        confirmText: 'Tetap Simpan',
        cancelText: 'Periksa Kembali',
        isDestructive: true,
      );

      if (isConfirmed != true) {
        setState(() => _isLoading = false);
        return;
      }
    }

    await widget.onSave(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextFormField(
            controller: _ctrlDay,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            labelText: 'Umur Ayam (Hari)',
            prefixIcon: Icons.calendar_month_outlined,
            validator: RecordingValidator.validateDay,
          ),
          const SizedBox(height: 16),

          AppTextFormField(
            controller: _ctrlFeed,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            labelText: 'Pakan Terpakai ($_feedUnit)',
            prefixIcon: Icons.inventory_2_outlined,
            suffixIcon: _buildUnitToggle(
              currentUnit: _feedUnit,
              units: const ['Sak', 'Kg'],
              onChanged: _onFeedUnitChanged,
            ),
            validator:
                (v) => RecordingValidator.validateFeedInput(v, _feedUnit),
          ),
          const SizedBox(height: 16),

          AppTextFormField(
            controller: _ctrlWeight,
            keyboardType:
                _weightUnit == 'Gram'
                    ? TextInputType.number
                    : const TextInputType.numberWithOptions(decimal: true),
            labelText: 'Berat Rata-Rata ($_weightUnit)',
            prefixIcon: Icons.scale_outlined,
            suffixIcon: _buildUnitToggle(
              currentUnit: _weightUnit,
              units: const ['Gram', 'Kg'],
              onChanged: _onWeightUnitChanged,
            ),
            validator:
                (v) => RecordingValidator.validateWeightInput(v, _weightUnit),
          ),
          const SizedBox(height: 16),

          AppTextFormField(
            controller: _ctrlMortality,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            labelText: 'Jumlah Kematian (Ekor)',
            prefixIcon: Icons.heart_broken_outlined,
            validator: RecordingValidator.validateMortality,
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
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
                            cs.onPrimary,
                          ),
                        ),
                      )
                      : Text(
                        'Simpan Perubahan',
                        style: tt.labelLarge?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle({
    required String currentUnit,
    required List<String> units,
    required ValueChanged<String> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            units.map((unit) {
              final isSelected = currentUnit == unit;
              return GestureDetector(
                onTap: () => onChanged(unit),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? cs.primary
                            : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Text(
                    unit,
                    style: tt.labelSmall?.copyWith(
                      color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
