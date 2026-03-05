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
import 'package:recording_app/features/reporting/presentation/pages/period_report.dart';
import 'widgets/create_period_button.dart';
import 'widgets/top_bar.dart';
import 'widgets/period_list_section.dart';

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
      floatingActionButton: const CreatePeriodButton(),
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
              final isClosed = !period.isActive && period.endDate != null;
              if (isClosed) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PeriodReportView(),
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
                TopBar(onNotificationTap: onNotificationTap),
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
                        PeriodListSection(
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


