import 'package:flutter/material.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import '../../data/models/period_data.dart';
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
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            child: AppEmptyState(
              icon: Icons.layers_outlined,
              message: _getEmptyMessage(),
              compact: true,
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

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case PeriodFilterType.all:
        return 'Belum ada data periode';
      case PeriodFilterType.active:
        return 'Tidak ada periode yang sedang aktif';
      case PeriodFilterType.closed:
        return 'Belum ada riwayat periode yang selesai';
      case PeriodFilterType.draft:
        return 'Tidak ada periode berstatus draft';
    }
  }
}
