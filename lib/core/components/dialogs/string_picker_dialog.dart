import 'package:flutter/material.dart';
import 'package:recording_app/core/components/dialogs/base_dialog.dart';

class StringPickerDialog extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final void Function(String) onSelected;

  const StringPickerDialog({
    Key? key,
    required this.title,
    required this.options,
    this.selectedOption,
    required this.onSelected,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<String> options,
    String? selectedOption,
    required void Function(String) onSelected,
  }) {
    return BaseDialog.show<void>(
      context: context,
      title: title,
      content: StringPickerDialog(
        title: title,
        options: options,
        selectedOption: selectedOption,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: options.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = option == selectedOption;

            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? cs.primary : cs.outline,
              ),
              title: Text(
                option,
                style: TextStyle(
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
