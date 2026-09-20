import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/period/data/models/harvest_record.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/period/presentation/controllers/period_controller.dart';

/// Screen mandiri untuk menampilkan riwayat histori panen parsial (penjarangan)
/// lengkap dengan ringkasan metrik total, kartu riwayat per kejadian,
/// dan aksi pembatalan/hapus data panen parsial.
class PartialHarvestHistoryScreen extends StatelessWidget {
  final PeriodData period;
  final int? currentLiveChicks;

  const PartialHarvestHistoryScreen({
    super.key,
    required this.period,
    this.currentLiveChicks,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final numFmt = NumberFormat.decimalPattern('id_ID');
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Ambil data periode terbaru dari controller secara reaktif
    final periodController = context.watch<PeriodController>();
    final activePeriod =
        periodController.periods
            .where((p) => p.id == period.id)
            .firstOrNull ??
        period;

    final partialHarvests = activePeriod.summary?.partialHarvests ?? [];
    // Urutkan riwayat dari yang terbaru (descending)
    final sortedHarvests = List<HarvestRecord>.from(partialHarvests)
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalChicks = activePeriod.summary?.totalPartialHarvestChicks ?? 0;
    final totalWeight = activePeriod.summary?.totalPartialHarvestWeightKg ?? 0.0;
    final avgWeight =
        totalChicks > 0 ? (totalWeight / totalChicks) : 0.0;
    final totalRevenue = partialHarvests.fold<double>(
      0.0,
      (sum, h) => sum + (h.totalRevenue ?? 0.0),
    );

    return Scaffold(
      appBar: const AppHeader(title: 'Riwayat Panen Parsial'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: partialHarvests.isEmpty
                ? _buildEmptyState(context, cs, activePeriod)
                : RefreshIndicator(
                    onRefresh: () async {
                      // Trigger controller reload jika diperlukan
                    },
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      children: [
                        // ── 1. Hero Summary Card ─────────────────────────────────
                        _buildHeroSummaryCard(
                          context,
                          cs,
                          tt,
                          numFmt,
                          currencyFmt,
                          totalChicks: totalChicks,
                          totalWeight: totalWeight,
                          avgWeight: avgWeight,
                          totalRevenue: totalRevenue,
                          harvestCount: partialHarvests.length,
                          isPeriodActive: activePeriod.isActive,
                        ),
                        const SizedBox(height: 20),

                        // ── 2. Section Header ─────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 10),
                          child: Row(
                            children: [
                              Text(
                                'DAFTAR PENJARANGAN (${partialHarvests.length})',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const Spacer(),
                              if (!activePeriod.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.pillRadius,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_outline_rounded,
                                        size: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Terkunci (Selesai)',
                                        style: tt.labelSmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // ── 3. Daftar Kartu Riwayat Panen Parsial ─────────────────
                        ...sortedHarvests.asMap().entries.map((entry) {
                          final index = entry.key;
                          final harvest = entry.value;
                          final itemNumber = sortedHarvests.length - index;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildHarvestItemCard(
                              context,
                              cs,
                              tt,
                              numFmt,
                              currencyFmt,
                              harvest: harvest,
                              itemNumber: itemNumber,
                              periodId: activePeriod.id,
                              isPeriodActive: activePeriod.isActive,
                            ),
                          );
                        }),
                        const SizedBox(height: 80), // Space untuk FAB / bottom button
                      ],
                    ),
                  ),
          ),
        ),
      ),
      bottomNavigationBar: activePeriod.isActive
          ? Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: FilledButton.icon(
                    onPressed: () => _openAddHarvest(context, activePeriod),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Catat Panen Parsial Baru',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme cs,
    PeriodData activePeriod,
  ) {
    return AppEmptyState(
      icon: Icons.scale_outlined,
      message: 'Belum Ada Panen Parsial',
      subtitle:
          'Penjarangan biasanya dilakukan saat kepadatan kandang mencapai batas (hari ke 28–32) untuk mengurangi risiko penumpukan atau menjual ayam bertahap.',
      actionLabel:
          activePeriod.isActive ? 'Catat Panen Parsial' : null,
      onAction:
          activePeriod.isActive ? () => _openAddHarvest(context, activePeriod) : null,
    );
  }

  Widget _buildHeroSummaryCard(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    NumberFormat numFmt,
    NumberFormat currencyFmt, {
    required int totalChicks,
    required double totalWeight,
    required double avgWeight,
    required double totalRevenue,
    required int harvestCount,
    required bool isPeriodActive,
  }) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.scale_rounded,
                    size: 22,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Panen Parsial',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$harvestCount kali penjarangan dilakukan',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPeriodActive
                        ? AppColors.success.withValues(alpha: 0.12)
                        : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Text(
                    isPeriodActive ? 'Siklus Berjalan' : 'Siklus Selesai',
                    style: tt.labelSmall?.copyWith(
                      color: isPeriodActive
                          ? AppColors.success
                          : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),

            // 4 Grid Metrik Ringkas
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetricTile(
                    context,
                    cs,
                    tt,
                    label: 'Total Ayam Keluar',
                    value: '${numFmt.format(totalChicks)} ekor',
                    icon: Icons.pets_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMetricTile(
                    context,
                    cs,
                    tt,
                    label: 'Total Bobot Timbang',
                    value: '${numFmt.format(totalWeight)} kg',
                    icon: Icons.scale_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetricTile(
                    context,
                    cs,
                    tt,
                    label: 'Rata-rata Bobot',
                    value: '${avgWeight.toStringAsFixed(2)} kg/ekor',
                    icon: Icons.insights_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMetricTile(
                    context,
                    cs,
                    tt,
                    label: 'Total Kas Masuk',
                    value: totalRevenue > 0
                        ? currencyFmt.format(totalRevenue)
                        : '-',
                    icon: Icons.account_balance_wallet_outlined,
                    valueColor: totalRevenue > 0 ? cs.primary : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetricTile(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: cs.primary),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestItemCard(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    NumberFormat numFmt,
    NumberFormat currencyFmt, {
    required HarvestRecord harvest,
    required int itemNumber,
    required String periodId,
    required bool isPeriodActive,
  }) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Kartu: Badge Hari, Info Panen & Tombol Aksi ───────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Badge Hari
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  ),
                  child: Text(
                    'Hari ${harvest.day}',
                    style: tt.titleSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Info Umur & Tanggal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Umur ${harvest.day} Hari',
                            style: tt.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(
                                AppTheme.pillRadius,
                              ),
                            ),
                            child: Text(
                              '#$itemNumber',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        dateFormat.format(harvest.date),
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol Hapus (Outlined pill button style matching detail_recording)
                if (isPeriodActive)
                  OutlinedButton.icon(
                    onPressed: () => _confirmDeleteHarvest(
                      context,
                      periodId: periodId,
                      harvest: harvest,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),

            // ── 3 Metrik Fisik Utama (Centered Metric Tiles) ─────────────────
            Row(
              children: [
                // 1. Ayam Dipanen
                Expanded(
                  child: _buildItemMetricTile(
                    context: context,
                    icon: Icons.pets_rounded,
                    iconBgColor: cs.secondaryContainer,
                    iconColor: cs.primary,
                    label: 'Ayam Dipanen',
                    value: '${numFmt.format(harvest.chicks)} ekor',
                    subtitle: 'Penjarangan',
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Total Bobot
                Expanded(
                  child: _buildItemMetricTile(
                    context: context,
                    icon: Icons.scale_rounded,
                    iconBgColor: cs.secondaryContainer,
                    iconColor: cs.primary,
                    label: 'Total Bobot',
                    value: '${numFmt.format(harvest.weightKg)} kg',
                    subtitle: 'Timbangan',
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Rata-rata Bobot
                Expanded(
                  child: _buildItemMetricTile(
                    context: context,
                    icon: Icons.insights_rounded,
                    iconBgColor: cs.secondaryContainer,
                    iconColor: cs.primary,
                    label: 'Rata-rata',
                    value: '${harvest.avgWeightKg.toStringAsFixed(2)} kg',
                    valueColor: cs.primary,
                    subtitle:
                        '${numFmt.format((harvest.avgWeightKg * 1000).round())} g/ekor',
                  ),
                ),
              ],
            ),

            // ── Info Keuangan (jika ada) ───────────────────────────────────
            if (harvest.totalRevenue != null && harvest.totalRevenue! > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kas Masuk',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (harvest.pricePerKg != null &&
                              harvest.pricePerKg! > 0)
                            Text(
                              '@${currencyFmt.format(harvest.pricePerKg)}/kg',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFmt.format(harvest.totalRevenue),
                      style: tt.titleSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Catatan / Bakul (jika ada) ─────────────────────────────────
            if (harvest.notes != null && harvest.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        harvest.notes!.trim(),
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemMetricTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    String? subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Icon (Tengah)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),

          // 2. Teks label (Tengah)
          Text(
            label,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // 3. Nilai Metrik (Tengah)
          Text(
            value,
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openAddHarvest(
    BuildContext context,
    PeriodData currentPeriod,
  ) async {
    // Estimasi sisa ayam hidup
    final existingPartial =
        currentPeriod.summary?.totalPartialHarvestChicks ?? 0;
    final estimatedLive = currentLiveChicks ??
        (currentPeriod.initialCapacity - existingPartial);

    final result = await DialogHelper.showPartialHarvest(
      context,
      period: currentPeriod,
      currentLiveChicks: estimatedLive,
    );

    if (result == null || !context.mounted) return;

    try {
      await context.read<PeriodController>().addPartialHarvest(
        currentPeriod.id,
        result.harvest,
        createIncomeTransaction: result.createIncomeTransaction,
      );
      if (context.mounted) {
        AppSnackbar.showSuccess(
          context,
          'Panen parsial ${result.harvest.chicks} ekor berhasil ditambahkan',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _confirmDeleteHarvest(
    BuildContext context, {
    required String periodId,
    required HarvestRecord harvest,
  }) async {
    final confirmed = await DialogHelper.showConfirm(
      context,
      'Hapus Panen Parsial',
      'Apakah Anda yakin ingin menghapus catatan panen parsial umur ${harvest.day} hari (${harvest.chicks} ekor, ${harvest.weightKg} kg)?\n\nSisa ayam hidup di kandang akan dipulihkan dan transaksi kas masuk terkait akan ikut dibatalkan.',
      confirmText: 'Hapus Catatan',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<PeriodController>().deletePartialHarvest(
        periodId,
        harvest.id,
      );
      if (context.mounted) {
        AppSnackbar.showSuccess(
          context,
          'Catatan panen parsial berhasil dihapus & sisa populasi dipulihkan.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}
