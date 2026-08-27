import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/loading/shimmer_loading.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';
import 'package:recording_app/features/reporting/presentation/pages/period_report_page.dart';
import '../data/models/period_data.dart';
import 'controllers/period_controller.dart';
import 'screens/form_period.dart';
import 'widgets/active_period_card.dart';
import 'widgets/create_period_button.dart';
import 'widgets/period_list_section.dart';

/// Screen daftar periode pemeliharaan ayam & manajemen siklus ternak
class PeriodListScreen extends StatefulWidget {
  final bool isTab;
  final String farmName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSeeAllTap;
  final void Function(PeriodData)? onPeriodTap;

  const PeriodListScreen({
    super.key,
    this.isTab = false,
    this.farmName = 'Kandang Utama',
    this.onNotificationTap,
    this.onSeeAllTap,
    this.onPeriodTap,
  });

  @override
  State<PeriodListScreen> createState() => _PeriodListScreenState();
}

class _PeriodListScreenState extends State<PeriodListScreen> {
  PeriodData? _getActivePeriod(List<PeriodData> periods) {
    final activeList = periods.where((p) => p.isActive);
    return activeList.isNotEmpty ? activeList.first : null;
  }

  void _handlePeriodTap(BuildContext context, PeriodData period) {
    if (widget.onPeriodTap != null) {
      widget.onPeriodTap!(period);
      return;
    }

    final isClosed = !period.isActive && period.endDate != null;
    if (isClosed) {
      context.read<ReportingController>().selectPeriod(period.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PeriodReportPage(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormPeriod(period: period),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Consumer<PeriodController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: List.generate(3, (_) => const PeriodCardSkeleton()),
              ),
            );
          }

          if (controller.errorMessage != null) {
            return AppErrorState(
              message: 'Gagal memuat data periode',
              subtitle: controller.errorMessage,
              onRetry: () => controller.reload(),
            );
          }

          final periods = controller.periods;
          final activePeriod = _getActivePeriod(periods);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: RefreshIndicator(
                onRefresh: () async => controller.reload(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. Kartu Periode Aktif ───────────────────────────
                      ActivePeriodCard(
                        period: activePeriod,
                        onManageTap: activePeriod != null
                            ? () => _handlePeriodTap(context, activePeriod)
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // ── 2. Daftar Riwayat Periode dengan Filter ──────────
                      PeriodListSection(
                        periods: periods,
                        onSeeAllTap: widget.onSeeAllTap,
                        onPeriodTap: (p) => _handlePeriodTap(context, p),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (widget.isTab) return body;

    return Scaffold(
      appBar: const AppHeader(title: 'Periode Pemeliharaan'),
      floatingActionButton: const CreatePeriodButton(),
      body: body,
    );
  }
}
