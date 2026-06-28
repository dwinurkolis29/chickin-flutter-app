import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/period_data.dart';
import 'controllers/period_controller.dart';
import 'widgets/active_period_card.dart';
import 'screens/form_period.dart';
import 'package:recording_app/features/reporting/presentation/pages/period_report_page.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';
import 'widgets/create_period_button.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'widgets/period_list_section.dart';
import 'package:recording_app/core/components/loading/shimmer_loading.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';

class PeriodListScreen extends StatefulWidget {
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

  @override
  State<PeriodListScreen> createState() => _PeriodListScreenState();
}

class _PeriodListScreenState extends State<PeriodListScreen> {


  @override
  void initState() {
    super.initState();
    // Logic tour lama dihapus
  }

  PeriodData? _getActivePeriod(List<PeriodData> periods) =>
      periods.where((p) => p.isActive).isNotEmpty
          ? periods.where((p) => p.isActive).first
          : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Periode'),
      floatingActionButton: const CreatePeriodButton(),
      body: SafeArea(
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

            void handlePeriodTap(PeriodData period) {
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

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => controller.reload(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap:
                              activePeriod != null
                                  ? () => handlePeriodTap(activePeriod)
                                  : null,
                          child: ActivePeriodCard(period: activePeriod),
                        ),
                        const SizedBox(height: 24),
                        PeriodListSection(
                          periods: periods,
                          onSeeAllTap: widget.onSeeAllTap,
                          onPeriodTap: handlePeriodTap,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
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
