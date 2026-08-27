import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import '../../data/models/period_data.dart';

/// Kartu item riwayat periode / siklus peternakan
class PeriodCard extends StatelessWidget {
  final PeriodData period;
  final void Function(PeriodData)? onTap;

  const PeriodCard({
    super.key,
    required this.period,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');
    final numFmt = NumberFormat.decimalPattern('id_ID');

    final isActive = period.isActive;
    final isClosed = !isActive && period.endDate != null;

    // Status Styling
    final String statusLabel = isActive ? 'Aktif' : (isClosed ? 'Selesai Panen' : 'Draft');
    final Color statusColor = isActive
        ? AppColors.success
        : (isClosed ? cs.primary : cs.onSurfaceVariant);
    final Color statusBg = isActive
        ? AppColors.success.withValues(alpha: 0.12)
        : (isClosed ? cs.primary.withValues(alpha: 0.1) : cs.surfaceContainerHighest);

    // Tanggal
    String dateRangeText;
    if (isActive) {
      dateRangeText = 'Mulai ${dateFmt.format(period.startDate)} (Berjalan)';
    } else if (isClosed) {
      final days = period.endDate!.difference(period.startDate).inDays;
      dateRangeText = '${dateFmt.format(period.startDate)} - ${dateFmt.format(period.endDate!)} ($days hari)';
    } else {
      dateRangeText = 'Dibuat ${dateFmt.format(period.createdAt)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => onTap?.call(period),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon status
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive
                        ? Icons.play_circle_outline_rounded
                        : (isClosed ? Icons.task_alt_rounded : Icons.edit_note_rounded),
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Info Periode
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              period.name.isNotEmpty ? period.name : 'Periode Tanpa Nama',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            ),
                            child: Text(
                              statusLabel,
                              style: tt.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateRangeText,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.groups_outlined, size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${numFmt.format(period.initialCapacity)} ekor DOC',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (period.summary != null) ...[
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: cs.outlineVariant)),
                            const SizedBox(width: 8),
                            Text(
                              'FCR: ${period.summary!.finalFCR.toStringAsFixed(2)}',
                              style: tt.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
