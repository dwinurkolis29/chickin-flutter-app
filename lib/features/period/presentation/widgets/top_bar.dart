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
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.chevron_left,
            onTap: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 12),
          Text(
            'Periode',
            style: tt.titleSmall?.copyWith(color: cs.onBackground),
          ),
        ],
      ),
    );
  }
}
