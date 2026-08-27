import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import '../screens/form_period.dart';

class CreatePeriodButton extends StatelessWidget {
  const CreatePeriodButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FloatingActionButton.extended(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      icon: const Icon(Icons.add_rounded, size: 22),
      label: Text(
        'Buat Periode Baru',
        style: tt.labelLarge?.copyWith(
          color: cs.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FormPeriod()),
        );
      },
    );
  }
}
