import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../dashboard/data/models/recording_data.dart';
import '../../../dashboard/domain/usecases/calculate_fcr_usecase.dart';
import '../../data/models/period_data.dart';

class ActivePeriodCard extends StatelessWidget {
  final PeriodData? period;
  const ActivePeriodCard({Key? key, this.period}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: period == null
          ? const _NoActivePeriod()
          : _ActivePeriodContent(period: period!),
    );
  }
}

class _NoActivePeriod extends StatelessWidget {
  const _NoActivePeriod();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Icon(Icons.inbox_outlined, size: 40, color: Colors.white.withOpacity(0.6)),
        const SizedBox(height: 8),
        Text(
          'Tidak ada periode aktif',
          style: tt.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }
}

class _ActivePeriodContent extends StatelessWidget {
  final PeriodData period;
  const _ActivePeriodContent({required this.period});

  @override
  Widget build(BuildContext context) {
    final tt     = Theme.of(context).textTheme;
    final fmt    = DateFormat('dd MMM yyyy');
    final dayAge = DateTime.now().difference(period.startDate).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Periode Aktif',
              style: tt.bodySmall?.copyWith(color: Colors.white.withOpacity(0.75)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success.withOpacity(0.5)),
              ),
              child: Text(
                '● Aktif',
                style: tt.labelMedium?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Period name
        Text(
          period.name.isNotEmpty ? period.name : 'Periode Tanpa Nama',
          style: tt.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mulai ${fmt.format(period.startDate)}',
          style: tt.bodySmall?.copyWith(color: Colors.white.withOpacity(0.75)),
        ),
        const SizedBox(height: 20),
        Divider(color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 12),
        StreamBuilder<List<RecordingData>>(
          stream: FirebaseService().getRecordingsStream(period.id),
          builder: (context, snapshot) {
            int liveUsia = dayAge;
            int livePopulasi = period.initialCapacity;
            double liveFcr = 0.0;
            double liveTotalPakan = 0.0;

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final recordings = snapshot.data!;
              final sorted = List<RecordingData>.from(recordings)..sort((a, b) => a.day.compareTo(b.day));
              final lastRec = sorted.last;

              final fcrUseCase = CalculateFCRUseCase();
              final weeklyFCRs = fcrUseCase.execute(recordings, period.initialCapacity);

              if (weeklyFCRs.isNotEmpty) {
                final lastWeekFcr = weeklyFCRs.last;
                livePopulasi = lastWeekFcr.sisaAyam;
                liveTotalPakan = lastWeekFcr.totalPakan;
                liveFcr = lastWeekFcr.fcr;
              } else {
                livePopulasi = period.initialCapacity;
                liveTotalPakan = 0.0;
                liveFcr = 0.0;
              }
              liveUsia = lastRec.day;
            } else if (period.summary != null) {
              livePopulasi = period.summary!.finalPopulation;
              liveFcr = period.summary!.finalFCR;
              liveTotalPakan = period.summary!.totalFeedKg;
            }

            return Column(
              children: [
                // Stats row 1
                Row(
                  children: [
                    _StatItem(label: 'Usia', value: '$liveUsia hari'),
                    const _CardDivider(),
                    _StatItem(label: 'Populasi', value: '${_fmt(livePopulasi)} ekor'),
                    const _CardDivider(),
                    _StatItem(label: 'FCR', value: liveFcr.toStringAsFixed(2)),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 12),
                // Stats row 2
                Row(
                  children: [
                    _StatItem(label: 'Bobot Awal', value: '${period.initialWeight} kg'),
                    const _CardDivider(),
                    _StatItem(label: 'Kapasitas Awal', value: '${_fmt(period.initialCapacity)} ekor'),
                    const _CardDivider(),
                    _StatItem(label: 'Total Pakan', value: '${liveTotalPakan.toStringAsFixed(0)} kg'),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _fmt(int n) => NumberFormat('#,###').format(n);
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: tt.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: Colors.white.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 32,
    color: Colors.white.withOpacity(0.2),
  );
}
