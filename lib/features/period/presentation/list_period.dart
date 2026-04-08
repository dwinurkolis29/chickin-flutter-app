import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/tour/tour_controller.dart';
import 'package:recording_app/core/tour/tour_step.dart';
import 'package:recording_app/core/tour/widgets/tour_aware_wrapper.dart';
import 'package:recording_app/core/tour/widgets/tour_overlay.dart';
import 'package:recording_app/core/tour/widgets/tour_tooltip.dart';
import '../data/models/period_data.dart';
import 'controllers/period_controller.dart';
import 'widgets/active_period_card.dart';
import 'screens/form_period.dart';
import 'package:recording_app/features/reporting/presentation/pages/period_report_page.dart';
import 'widgets/create_period_button.dart';
import 'widgets/top_bar.dart';
import 'widgets/period_list_section.dart';

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
  final GlobalKey _createPeriodFabKey = GlobalKey();

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
    return Stack(
      children: [
        Scaffold(
          floatingActionButton: TourAwareWrapper(
            tourKey: _createPeriodFabKey,
            child: const CreatePeriodButton(),
          ),
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
                TopBar(onNotificationTap: widget.onNotificationTap),
                Expanded(
                  child: SingleChildScrollView(
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
              ],
            );
              },
            ),
          ),
        ),
        _buildTourOverlay(context),
      ],
    );
  }

  Widget _buildTourOverlay(BuildContext context) {
    final tourController = context.watch<TourController>();
    if (!tourController.isTourActive || tourController.currentStep != TourStep.createPeriod) {
      return const SizedBox.shrink();
    }

    final rect = TourAwareWrapper.getRect(_createPeriodFabKey);
    if (rect == null) return const SizedBox.shrink();

    return TourOverlay(
      targetKey: _createPeriodFabKey,
      tooltip: TourTooltip(
        title: 'Buat Periode Baru',
        description: 'Tekan tombol ini untuk mulai membuat periode peternakan baru.',
        stepText: '1 / 3',
        showSkip: true,
        onSkip: () => tourController.skip(),
      ),
      onSkip: () {},
    );
  }
}
