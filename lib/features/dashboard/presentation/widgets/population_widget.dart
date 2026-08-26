import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';

class PopulationSection extends StatefulWidget {
  final int populationRemain;
  final int capacity;

  const PopulationSection({
    super.key,
    required this.populationRemain,
    required this.capacity,
  });

  @override
  State<PopulationSection> createState() => _PopulationSectionState();
}

class _PopulationSectionState extends State<PopulationSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<int> _counterAnimation;

  final NumberFormat _numberFormat = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final targetProgress = widget.capacity > 0
        ? (widget.populationRemain / widget.capacity).clamp(0.0, 1.0)
        : 0.0;

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: targetProgress,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _counterAnimation = IntTween(
      begin: 0,
      end: widget.populationRemain,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant PopulationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.populationRemain != widget.populationRemain ||
        oldWidget.capacity != widget.capacity) {
      final targetProgress = widget.capacity > 0
          ? (widget.populationRemain / widget.capacity).clamp(0.0, 1.0)
          : 0.0;

      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: targetProgress,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );

      _counterAnimation = IntTween(
        begin: _counterAnimation.value,
        end: widget.populationRemain,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );

      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(double survivalPercent) {
    if (survivalPercent >= 95.0) return AppColors.success;
    if (survivalPercent >= 90.0) return AppColors.warning;
    return AppColors.error;
  }

  String _getStatusLabel(double survivalPercent) {
    if (survivalPercent >= 95.0) return 'Sangat Baik';
    if (survivalPercent >= 90.0) return 'Perhatian';
    return 'Tinggi';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final survivalPercent = widget.capacity > 0
        ? (widget.populationRemain / widget.capacity * 100).clamp(0.0, 100.0)
        : 0.0;

    final statusColor = _getStatusColor(survivalPercent);
    final statusLabel = _getStatusLabel(survivalPercent);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Icon + Judul + Status Badge ───────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pets_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Populasi Ayam',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Monitoring jumlah & kelangsungan hidup',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Livability Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: tt.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Baris Metrik Utama + Progress Donut ───────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sisi Kiri: Angka Populasi Hidup
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ayam Hidup',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            AnimatedBuilder(
                              animation: _counterAnimation,
                              builder: (context, child) {
                                return Text(
                                  _numberFormat.format(_counterAnimation.value),
                                  style: tt.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                    fontSize: 32,
                                    height: 1.1,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.pillRadius,
                                ),
                              ),
                              child: Text(
                                'Ekor',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sisi Kanan: Circular Progress Donut Livability
                  SizedBox(
                    width: 86,
                    height: 86,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        final animatedPct = (_progressAnimation.value * 100)
                            .toStringAsFixed(1);

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: _progressAnimation.value,
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                              backgroundColor: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                statusColor,
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$animatedPct%',
                                    style: tt.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                      fontSize: 15,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    'Survival',
                                    style: tt.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
