import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/components/dialogs/base_dialog.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

class PeriodPickerDialog extends StatelessWidget {
  final List<PeriodData> periods;
  final String? selectedPeriodId;
  final void Function(String) onSelected;

  const PeriodPickerDialog({
    Key? key,
    required this.periods,
    required this.selectedPeriodId,
    required this.onSelected,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required List<PeriodData> periods,
    required String? selectedPeriodId,
    required void Function(String) onSelected,
  }) {
    return BaseDialog.show<void>(
      context: context,
      title: 'Pilih Periode',
      content: PeriodPickerDialog(
        periods: periods,
        selectedPeriodId: selectedPeriodId,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy');

    return SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: periods.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final period = periods[index];
            final isSelected = period.id == selectedPeriodId;

            final startStr = dateFmt.format(period.startDate);
            final endStr = period.endDate != null ? dateFmt.format(period.endDate!) : 'Aktif';

            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? cs.primary : cs.outline,
              ),
              title: Text(
                period.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? cs.primary : cs.onSurface,
                ),
              ),
              subtitle: Text('$startStr - $endStr'),
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
