import 'package:flutter/material.dart';

class AppDropdownFormField<T> extends StatelessWidget {
  const AppDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelText,
    this.focusNode,
    this.prefixIcon,
    this.validator,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String labelText;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<T>(
      value: value,
      focusNode: focusNode,
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: colorScheme.surfaceContainerHighest,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
      ),
    );
  }
}
