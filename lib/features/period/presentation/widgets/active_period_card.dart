import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/period/presentation/controllers/period_controller.dart';
import 'package:recording_app/features/finance/presentation/pages/finance_list_screen.dart';
import 'package:recording_app/features/period/presentation/screens/form_period.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_fcr.dart';

/// Kartu sorotan untuk periode pemeliharaan aktif.
/// Menyajikan ringkasan siklus berjalan dan akses cepat pengelolaan panen.
class ActivePeriodCard extends StatelessWidget {
  final PeriodData? period;
  final VoidCallback? onManageTap;
  final Stream<List<RecordingData>>? recordingsStream;

  const ActivePeriodCard({
    super.key,
    required this.period,
    this.onManageTap,
    this.recordingsStream,
  });

  @override
  Widget build(BuildContext context) {
    if (period == null) {
      return const _NoActivePeriodCard();
    }
    return _ActivePeriodContentCard(
      period: period!,
      onManageTap: onManageTap,
      recordingsStream: recordingsStream,
    );
  }
}

/// Tampilan jika tidak ada periode yang sedang aktif
class _NoActivePeriodCard extends StatelessWidget {
  const _NoActivePeriodCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 32,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum Ada Siklus Aktif',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mulai siklus pemeliharaan baru untuk mencatat pakan, mortalitas & bobot ayam harian.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormPeriod()),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Mulai Siklus Baru'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Konten kartu periode aktif
class _ActivePeriodContentCard extends StatelessWidget {
  final PeriodData period;
  final VoidCallback? onManageTap;
  final Stream<List<RecordingData>>? recordingsStream;

  const _ActivePeriodContentCard({
    required this.period,
    this.onManageTap,
    this.recordingsStream,
  });

  Stream<List<RecordingData>>? _resolveStream() {
    if (recordingsStream != null) return recordingsStream;
    try {
      return FirebaseService().getRecordingsStream(period.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');
    final numFmt = NumberFormat.decimalPattern('id_ID');

    final dayAge = DateTime.now().difference(period.startDate).inDays;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Label Periode Aktif & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'PERIODE SEDANG AKTIF',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Berjalan',
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Baris 2: Nama Periode & Tanggal Masuk
            Text(
              period.name.isNotEmpty ? period.name : 'Periode Tanpa Nama',
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              'Umur $dayAge Hari • DOC Masuk: ${dateFmt.format(period.startDate)}',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            // Baris 3: Live Stats Stream (Sisa Ayam, FCR, Pakan)
            StreamBuilder<List<RecordingData>>(
              stream: _resolveStream(),
              builder: (context, snapshot) {
                int livePopulasi = period.initialCapacity;
                double liveFcr = 0.0;
                double liveTotalPakan = 0.0;

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final recordings = snapshot.data!;

                  final fcrUseCase = CalculateFCR();
                  final weeklyFCRs = fcrUseCase.execute(recordings, period.initialCapacity);
                  if (weeklyFCRs.isNotEmpty) {
                    final lastWeek = weeklyFCRs.last;
                    livePopulasi = lastWeek.sisaAyam;
                    liveTotalPakan = lastWeek.totalPakan;
                    liveFcr = lastWeek.fcr;
                  }
                } else if (period.summary != null) {
                  livePopulasi = period.summary!.finalPopulation;
                  liveFcr = period.summary!.finalFCR;
                  liveTotalPakan = period.summary!.totalFeedKg;
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatMiniTile(
                          label: 'Sisa Ayam',
                          value: '${numFmt.format(livePopulasi)} ekor',
                          sub: 'DOC: ${numFmt.format(period.initialCapacity)}',
                        ),
                      ),
                      Container(width: 1, height: 36, color: cs.outlineVariant),
                      Expanded(
                        child: _StatMiniTile(
                          label: 'FCR Terkini',
                          value: liveFcr > 0 ? numFmt.format(liveFcr) : '-',
                          sub: liveFcr <= 1.80 ? 'Efisien' : (liveFcr <= 2.20 ? 'Cukup' : 'Perhatian'),
                        ),
                      ),
                      Container(width: 1, height: 36, color: cs.outlineVariant),
                      Expanded(
                        child: _StatMiniTile(
                          label: 'Total Pakan',
                          value: '${numFmt.format(liveTotalPakan)} kg',
                          sub: '${(liveTotalPakan / 50).toStringAsFixed(1)} sak',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Baris 4: Quick Action Buttons
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FinanceListScreen(period: period),
                  ),
                );
              },
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              label: const Text('Catat & Kelola Keuangan'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (onManageTap != null) {
                        onManageTap!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FormPeriod(period: period)),
                        );
                      }
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Kelola Siklus'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmClosePeriod(context),
                    icon: Icon(Icons.check_box_outlined, size: 18, color: cs.error),
                    label: Text(
                      'Tutup Panen',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.error.withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClosePeriod(BuildContext context) async {
    final result = await DialogHelper.showClosePeriodHarvest(context, period);
    if (result == null) return;

    if (!context.mounted) return;
    try {
      await context.read<PeriodController>().closePeriod(
        period.id,
        harvestedChicks: result.harvestedChicks,
        harvestedWeightKg: result.harvestedWeightKg,
      );
      if (context.mounted) {
        AppSnackbar.showSuccess(context, 'Periode berhasil ditutup & laporan panen siap');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }
}

class _StatMiniTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _StatMiniTile({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 10.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
              fontSize: 12.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.75),
              fontSize: 9.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
