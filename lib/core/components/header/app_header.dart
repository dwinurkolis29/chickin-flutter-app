import 'package:flutter/material.dart';
import 'package:recording_app/core/components/buttons/circle_icon_button.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isHome;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.isHome = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      leading: !isHome && Navigator.canPop(context)
          ? Center(
              child: CircleIconButton(
                icon: Icons.chevron_left,
                onTap: () => Navigator.maybePop(context),
              ),
            )
          : null,
      title: Text(
        title,
        style: tt.titleMedium?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
