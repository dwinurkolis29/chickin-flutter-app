import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:provider/provider.dart';
import '../data/models/period_data.dart';
import 'controllers/period_controller.dart';
import 'widgets/period_card.dart';
import 'widgets/active_period_card.dart';
import 'screens/form_period.dart';

class PeriodListScreen extends StatelessWidget {
  final String farmName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSeeAllTap;
  final void Function(PeriodData)? onPeriodTap;

  const PeriodListScreen({
    super.key,
    this.farmName = 'Kandang Utama',
    this.onNotificationTap,
    this.onSeeAllTap,
    this.onPeriodTap,
  });

  PeriodData? _getActivePeriod(List<PeriodData> periods) =>
      periods.where((p) => p.isActive).isNotEmpty
          ? periods.where((p) => p.isActive).first
          : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const _createPeriodButton(),
      body: SafeArea(
        child: Consumer<PeriodController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage != null) {
              return Center(child: Text('Error: ${controller.errorMessage}'));
            }

            final periods = controller.periods;
            final activePeriod = _getActivePeriod(periods);

            void handlePeriodTap(PeriodData period) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormPeriod(period: period),
                ),
              );
            }

            return Column(
              children: [
                _TopBar(onNotificationTap: onNotificationTap),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: activePeriod != null ? () => handlePeriodTap(activePeriod) : null,
                          child: ActivePeriodCard(period: activePeriod),
                        ),
                        const SizedBox(height: 24),
                        _PeriodListSection(
                          periods: periods,
                          onSeeAllTap: onSeeAllTap,
                          onPeriodTap: handlePeriodTap,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _createPeriodButton extends StatelessWidget {
  const _createPeriodButton();

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

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  const _TopBar({this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _CircleIconButton(
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleIconButton({required this.icon, this.onTap});

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



// ── Period List Section ───────────────────────────────────────────────────────

class _PeriodListSection extends StatelessWidget {
  final List<PeriodData> periods;
  final VoidCallback? onSeeAllTap;
  final void Function(PeriodData)? onPeriodTap;

  const _PeriodListSection({
    required this.periods,
    this.onSeeAllTap,
    this.onPeriodTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Semua Periode',
              style: tt.titleSmall?.copyWith(color: cs.onBackground),
            ),
            GestureDetector(
              onTap: onSeeAllTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'lihat semua',
                  style: tt.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (periods.isEmpty)
          _EmptyState()
        else
          ...periods.map((p) => PeriodCard(period: p, onTap: onPeriodTap)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_outlined, size: 36, color: cs.outlineVariant),
          const SizedBox(height: 8),
          Text(
            'Belum ada periode',
            style: tt.bodyMedium?.copyWith(color: cs.outlineVariant),
          ),
        ],
      ),
    );
  }
}
