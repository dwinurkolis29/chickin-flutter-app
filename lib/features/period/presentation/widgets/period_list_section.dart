import 'package:flutter/material.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import '../../data/models/period_data.dart';
import '../screens/form_period.dart';
import 'period_card.dart';

enum PeriodFilterType { all, active, closed, draft }

/// Bagian daftar riwayat periode dengan filter chip status yang mudah digunakan peternak
class PeriodListSection extends StatefulWidget {
  final List<PeriodData> periods;
  final VoidCallback? onSeeAllTap;
  final void Function(PeriodData)? onPeriodTap;

  const PeriodListSection({
    super.key,
    required this.periods,
    this.onSeeAllTap,
    this.onPeriodTap,
  });

  @override
  State<PeriodListSection> createState() => _PeriodListSectionState();
}

class _PeriodListSectionState extends State<PeriodListSection> {
  PeriodFilterType _selectedFilter = PeriodFilterType.all;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final activeCount = widget.periods.where((p) => p.isActive).length;
    final closedCount = widget.periods.where((p) => !p.isActive && p.endDate != null).length;
    final draftCount = widget.periods.where((p) => !p.isActive && p.endDate == null).length;

    // Filtered list
    final filteredPeriods = widget.periods.where((p) {
      switch (_selectedFilter) {
        case PeriodFilterType.all:
          return true;
        case PeriodFilterType.active:
          return p.isActive;
        case PeriodFilterType.closed:
          return !p.isActive && p.endDate != null;
        case PeriodFilterType.draft:
          return !p.isActive && p.endDate == null;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Judul
        Text(
          'RIWAYAT SEMUA PERIODE',
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        // Filter Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Semua (${widget.periods.length})',
                type: PeriodFilterType.all,
                cs: cs,
                tt: tt,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Aktif ($activeCount)',
                type: PeriodFilterType.active,
                cs: cs,
                tt: tt,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Selesai Panen ($closedCount)',
                type: PeriodFilterType.closed,
                cs: cs,
                tt: tt,
              ),
              if (draftCount > 0) ...[
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Draft ($draftCount)',
                  type: PeriodFilterType.draft,
                  cs: cs,
                  tt: tt,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // List / Empty State
        if (filteredPeriods.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            child: AppEmptyState(
              icon: _getEmptyIcon(),
              message: _getEmptyTitle(),
              subtitle: _getEmptySubtitle(),
              compact: true,
              actionLabel: (_selectedFilter == PeriodFilterType.all ||
                      _selectedFilter == PeriodFilterType.active)
                  ? 'Mulai Siklus Baru'
                  : null,
              onAction: (_selectedFilter == PeriodFilterType.all ||
                      _selectedFilter == PeriodFilterType.active)
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FormPeriod()),
                      )
                  : null,
            ),
          )
        else
          ...filteredPeriods.map(
            (p) => PeriodCard(period: p, onTap: widget.onPeriodTap),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required PeriodFilterType type,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    final isSelected = _selectedFilter == type;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = type),
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: tt.labelMedium?.copyWith(
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  IconData _getEmptyIcon() {
    switch (_selectedFilter) {
      case PeriodFilterType.all:
      case PeriodFilterType.active:
        return Icons.calendar_today_outlined;
      case PeriodFilterType.closed:
        return Icons.task_alt_outlined;
      case PeriodFilterType.draft:
        return Icons.edit_note_outlined;
    }
  }

  String _getEmptyTitle() {
    switch (_selectedFilter) {
      case PeriodFilterType.all:
        return 'Belum Ada Data Periode';
      case PeriodFilterType.active:
        return 'Tidak Ada Periode Aktif';
      case PeriodFilterType.closed:
        return 'Belum Ada Periode Selesai';
      case PeriodFilterType.draft:
        return 'Tidak Ada Draft Periode';
    }
  }

  String _getEmptySubtitle() {
    switch (_selectedFilter) {
      case PeriodFilterType.all:
        return 'Mulai siklus pemeliharaan baru untuk mencatat populasi DOC, pakan harian, dan monitoring bobot ayam.';
      case PeriodFilterType.active:
        return 'Saat ini tidak ada siklus ayam yang sedang berlangsung. Buat periode baru untuk memulai pencatatan.';
      case PeriodFilterType.closed:
        return 'Riwayat siklus yang telah selesai dipanen beserta ringkasan performa FCR & IP akan tersimpan di sini.';
      case PeriodFilterType.draft:
        return 'Rencana siklus pemeliharaan yang belum dimulai akan tersimpan di sini sebagai draft.';
    }
  }
}
