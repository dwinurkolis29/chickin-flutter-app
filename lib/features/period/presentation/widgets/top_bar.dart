import 'package:flutter/material.dart';
import '../../../../core/components/buttons/circle_icon_button.dart';

class TopBar extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  const TopBar({super.key, this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CircleIconButton(
              icon: Icons.chevron_left,
              onTap: () => Navigator.maybePop(context),
            ),
          ),
          Center(
            child: Text(
              'Periode',
              textAlign: TextAlign.center,
              style: tt.titleLarge?.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
