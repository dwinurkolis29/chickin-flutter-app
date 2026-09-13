import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Tombol pill interaktif terpusat dengan icon, teks label tebal,
/// chevron kanan animasi hover, dan border halus.
class ActionPillButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData trailingIcon;

  const ActionPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.trailingIcon = Icons.chevron_right_rounded,
  });

  @override
  State<ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<ActionPillButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color:
            _isHovered
                ? cs.primary.withValues(alpha: 0.12)
                : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          hoverColor: AppColors.transparent,
          splashColor: cs.primary.withValues(alpha: 0.15),
          highlightColor: cs.primary.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              border: Border.all(
                color:
                    _isHovered
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.6),
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow:
                  _isHovered
                      ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 18,
                    color:
                        _isHovered
                            ? cs.primary
                            : cs.primary.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        _isHovered
                            ? cs.primary
                            : cs.primary.withValues(alpha: 0.9),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedSlide(
                  offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    widget.trailingIcon,
                    size: 18,
                    color:
                        _isHovered
                            ? cs.primary
                            : cs.primary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
