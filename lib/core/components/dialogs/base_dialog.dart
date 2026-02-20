import 'package:flutter/material.dart';

/// Base dialog widget with consistent styling across the app
class BaseDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final bool barrierDismissible;

  const BaseDialog({
    Key? key,
    this.title,
    required this.content,
    this.actions,
    this.barrierDismissible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: title != null
          ? Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium,
            )
          : null,
      content: content,
      actions: actions,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    );
  }

  /// Show the dialog
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => BaseDialog(
        title: title,
        content: content,
        actions: actions,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}
