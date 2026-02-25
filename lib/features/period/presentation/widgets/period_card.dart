import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/period_data.dart';

class PeriodCard extends StatelessWidget {
  final PeriodData period;
  final void Function(PeriodData)? onTap;
  
  const PeriodCard({Key? key, required this.period, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final tt       = Theme.of(context).textTheme;
    final fmt      = DateFormat('dd MMM yyyy');
    final isActive = period.isActive;

    return GestureDetector(
      onTap: () => onTap?.call(period),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.success.withOpacity(0.1)
                    : cs.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive
                    ? Icons.play_circle_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 20,
                color: isActive ? AppColors.success : cs.outlineVariant,
              ),
            ),
            const SizedBox(width: 12),
            // Period name + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period.name.isNotEmpty ? period.name : 'Periode Tanpa Nama',
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive
                        ? 'Mulai ${fmt.format(period.startDate)}'
                        : period.endDate != null
                        ? 'Selesai ${fmt.format(period.endDate!)}'
                        : fmt.format(period.startDate),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            // Capacity + status label
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${NumberFormat('#,###').format(period.initialCapacity)} ekor',
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive ? 'Aktif' : 'Selesai',
                  style: tt.bodySmall?.copyWith(
                    color: isActive ? AppColors.success : cs.outlineVariant,
                    fontWeight: FontWeight.w500,
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
