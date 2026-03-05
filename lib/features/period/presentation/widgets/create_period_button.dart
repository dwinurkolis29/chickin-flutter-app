import 'package:flutter/material.dart';
import '../screens/form_period.dart';

class CreatePeriodButton extends StatelessWidget {
  const CreatePeriodButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Theme.of(context).colorScheme.primary,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FormPeriod(),
          ),
        );
      },
      child: const Icon(Icons.add),
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }
}
