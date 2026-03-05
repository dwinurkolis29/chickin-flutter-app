import 'package:flutter/material.dart';

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

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const CircleIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: cs.onSurface),
      ),
    );
  }
}
