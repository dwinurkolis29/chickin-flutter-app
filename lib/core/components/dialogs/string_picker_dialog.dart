import 'package:flutter/material.dart';
import 'package:recording_app/core/components/dialogs/base_dialog.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Dialog pemilihan string/opsi umum dengan styling konsisten.
class StringPickerDialog extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final void Function(String) onSelected;

  const StringPickerDialog({
    super.key,
    required this.title,
    required this.options,
    this.selectedOption,
    required this.onSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<String> options,
    String? selectedOption,
    required void Function(String) onSelected,
  }) {
    final cs = Theme.of(context).colorScheme;

    return BaseDialog.show<void>(
      context: context,
      title: title,
      icon: Icons.list_alt_rounded,
      iconColor: cs.primary,
      iconBackgroundColor: cs.secondaryContainer,
      content: StringPickerDialog(
        title: title,
        options: options,
        selectedOption: selectedOption,
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

    return SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: options.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = option == selectedOption;

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
                option,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? cs.primary : cs.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onSelected(option);
              },
            );
          },
        ),
      ),
    );
  }
}
