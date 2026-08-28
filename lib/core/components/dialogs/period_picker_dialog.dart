import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/components/dialogs/base_dialog.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

/// Dialog pemilihan periode pemeliharaan dengan styling konsisten.
class PeriodPickerDialog extends StatelessWidget {
  final List<PeriodData> periods;
  final String? selectedPeriodId;
  final void Function(String) onSelected;

  const PeriodPickerDialog({
    super.key,
    required this.periods,
    required this.selectedPeriodId,
    required this.onSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required List<PeriodData> periods,
    required String? selectedPeriodId,
    required void Function(String) onSelected,
  }) {
    final cs = Theme.of(context).colorScheme;

    return BaseDialog.show<void>(
      context: context,
      title: 'Pilih Periode',
      icon: Icons.calendar_month_outlined,
      iconColor: cs.primary,
      iconBackgroundColor: cs.secondaryContainer,
      content: PeriodPickerDialog(
        periods: periods,
        selectedPeriodId: selectedPeriodId,
        onSelected: onSelected,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: cs.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
          ),
          child: const Text('Batal'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('dd MMM yyyy');

    return SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: periods.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
          itemBuilder: (context, index) {
            final period = periods[index];
            final isSelected = period.id == selectedPeriodId;

            final startStr = dateFmt.format(period.startDate);
            final endStr = period.endDate != null ? dateFmt.format(period.endDate!) : 'Aktif';

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              selected: isSelected,
              selectedTileColor: cs.secondaryContainer.withValues(alpha: 0.5),
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? cs.primary : cs.outline,
              ),
              title: Text(
                period.name,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? cs.primary : cs.onSurface,
                ),
              ),
              subtitle: Text(
                '$startStr - $endStr',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onSelected(period.id);
              },
            );
          },
        ),
      ),
    );
  }
}
