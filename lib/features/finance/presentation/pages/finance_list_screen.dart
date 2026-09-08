import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/components/cards/app_card.dart';
import '../../../../core/components/dialogs/dialog_helper.dart';
import '../../../../core/components/empty/app_empty_state.dart';
import '../../../../core/components/header/app_header.dart';
import '../../../../core/components/loading/shimmer_loading.dart';
import '../../../../core/components/snackbars/app_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../period/data/models/period_data.dart';
import '../../data/models/finance_summary.dart';
import '../../data/models/finance_transaction.dart';
import '../controllers/finance_controller.dart';
import 'form_finance_screen.dart';

/// Screen manajemen dan visualisasi Keuangan Periode Broiler
/// Dirancang ramah bagi peternak senior dengan hierarki visual Laba/Rugi,
/// struktur biaya operasional, serta timeline transaksi yang jelas.
class FinanceListScreen extends StatefulWidget {
  final PeriodData period;

  const FinanceListScreen({super.key, required this.period});

  @override
  State<FinanceListScreen> createState() => _FinanceListScreenState();
}

class _FinanceListScreenState extends State<FinanceListScreen> {
  String _filter = 'all'; // 'all', 'expense', 'income'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceController>().setPeriod(widget.period);
    });
  }

  Future<void> _openAddTransaction(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (_) => FormFinanceScreen(
              periodId: widget.period.id,
              periodName: widget.period.name,
            ),
      ),
    );

    if (result == true && context.mounted) {
      AppSnackbar.showSuccess(context, 'Transaksi keuangan berhasil dicatat');
    }
  }

  Future<void> _openEditTransaction(
    BuildContext context,
    FinanceTransaction tx,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (_) => FormFinanceScreen(
              periodId: widget.period.id,
              periodName: widget.period.name,
              existingTransaction: tx,
            ),
      ),
    );

    if (result == true && context.mounted) {
      AppSnackbar.showSuccess(
        context,
        'Transaksi keuangan berhasil diperbarui',
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FinanceTransaction tx,
  ) async {
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final confirmed = await DialogHelper.showConfirm(
      context,
      'Hapus Transaksi',
      'Apakah Anda yakin ingin menghapus transaksi "${tx.displayCategory}" sebesar ${currencyFmt.format(tx.amount)}?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<FinanceController>().deleteTransaction(tx.id);
        if (context.mounted) {
          AppSnackbar.showSuccess(context, 'Transaksi berhasil dihapus');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.showError(context, 'Gagal menghapus transaksi: $e');
        }
      }
    }
  }

  /// Mengelompokkan transaksi berdasarkan tanggal (YYYY-MM-DD)
  Map<String, List<FinanceTransaction>> _groupTransactionsByDate(
    List<FinanceTransaction> transactions,
  ) {
    final Map<String, List<FinanceTransaction>> groups = {};
    for (final tx in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(tx);
    }
    return groups;
  }

  String _formatDateHeader(String dateKey) {
    final date = DateTime.tryParse(dateKey) ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Hari Ini • ${DateFormat('dd MMMM yyyy', 'id_ID').format(date)}';
    } else if (checkDate == yesterday) {
      return 'Kemarin • ${DateFormat('dd MMMM yyyy', 'id_ID').format(date)}';
    } else {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceController>();
    final cs = Theme.of(context).colorScheme;
    final summary = controller.summary;

    final allTx = controller.transactions;
    final expenseCount = allTx.where((tx) => tx.isExpense).length;
    final incomeCount = allTx.where((tx) => tx.isIncome).length;

    final filteredTx =
        allTx.where((tx) {
          if (_filter == 'expense') return tx.isExpense;
          if (_filter == 'income') return tx.isIncome;
          return true;
        }).toList();

    final groupedTx = _groupTransactionsByDate(filteredTx);

    return Scaffold(
      appBar: AppHeader(title: 'Keuangan ${widget.period.name}'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransaction(context),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Catat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child:
            controller.isLoading
                ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ReportSkeleton(),
                )
                : CustomScrollView(
                  slivers: [
                    // ── 0. Banner Peringatan: Panen Ditutup Tanpa Transaksi Penjualan ──
                    if (widget.period.isClosed && summary.totalRevenue == 0)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: _UnrecordedHarvestWarningBanner(
                            onAction: () async {
                              final result = await Navigator.of(
                                context,
                              ).push<bool>(
                                MaterialPageRoute(
                                  builder:
                                      (_) => FormFinanceScreen(
                                        periodId: widget.period.id,
                                        periodName: widget.period.name,
                                        initialType: 'income',
                                        initialCategory: 'main_harvest',
                                        initialBirdCount:
                                            widget.period.harvestedChicks,
                                        initialWeightKg:
                                            widget.period.harvestedWeightKg,
                                      ),
                                ),
                              );
                              if (result == true && context.mounted) {
                                AppSnackbar.showSuccess(
                                  context,
                                  'Transaksi penjualan panen berhasil dicatat',
                                );
                              }
                            },
                          ),
                        ),
                      ),

                    // ── 1. Hero Ringkasan Laba / Rugi & Arus Kas ─────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: _HeroCashflowCard(summary: summary),
                      ),
                    ),

                    // ── 2. Struktur Biaya Operasional (Cost Breakdown) ───────
                    if (summary.totalExpense > 0)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: _CostBreakdownCard(summary: summary),
                        ),
                      ),

                    // ── 3. Filter Chips (Semua, Pengeluaran, Pemasukan) ──────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Semua (${allTx.length})',
                              isSelected: _filter == 'all',
                              onTap: () => setState(() => _filter = 'all'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Pengeluaran ($expenseCount)',
                              isSelected: _filter == 'expense',
                              onTap: () => setState(() => _filter = 'expense'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Pemasukan ($incomeCount)',
                              isSelected: _filter == 'income',
                              onTap: () => setState(() => _filter = 'income'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── 4. Daftar Transaksi / Empty State ────────────────────
                    if (filteredTx.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: AppEmptyState(
                          icon: Icons.receipt_long_outlined,
                          message: 'Belum Ada Transaksi',
                          subtitle:
                              _filter == 'all'
                                  ? 'Catat biaya pakan, bibit DOC, OVK, dan hasil penjualan ayam untuk memantau arus kas & laba bersih.'
                                  : (_filter == 'expense'
                                      ? 'Belum ada pengeluaran operasional yang dicatat pada periode ini.'
                                      : 'Belum ada pemasukan penjualan yang dicatat pada periode ini.'),
                          actionLabel: 'Catat Transaksi Sekarang',
                          onAction: () => _openAddTransaction(context),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 84),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final dateKey = groupedTx.keys.elementAt(index);
                            final items = groupedTx[dateKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date Header
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    top: 10,
                                    bottom: 6,
                                  ),
                                  child: Text(
                                    _formatDateHeader(dateKey),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),

                                // Transaction items on this date
                                ...items.map((tx) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _TransactionCard(
                                      transaction: tx,
                                      onEdit:
                                          () =>
                                              _openEditTransaction(context, tx),
                                      onDelete:
                                          () => _confirmDelete(context, tx),
                                    ),
                                  );
                                }),
                              ],
                            );
                          }, childCount: groupedTx.keys.length),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}

/// Hero Card Laba Bersih & Arus Kas Transparan
class _HeroCashflowCard extends StatelessWidget {
  final FinanceSummary summary;

  const _HeroCashflowCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final numFmt = NumberFormat.decimalPattern('id_ID');

    final bool isProfit = summary.netProfit > 0;
    final bool isLoss = summary.netProfit < 0;
    final bool hasData = summary.hasTransactions;

    Color badgeBg;
    Color badgeText;
    String statusLabel;

    if (!hasData) {
      badgeBg = cs.secondaryContainer;
      badgeText = cs.onSurfaceVariant;
      statusLabel = 'BELUM ADA TRANSAKSI';
    } else if (isProfit) {
      badgeBg = AppColors.success.withValues(alpha: 0.15);
      badgeText = AppColors.success;
      statusLabel = 'ESTIMASI UNTUNG';
    } else if (isLoss) {
      badgeBg = AppColors.warning.withValues(alpha: 0.2);
      badgeText = AppColors.warning;
      statusLabel = 'BELUM IMPAS';
    } else {
      badgeBg = cs.secondaryContainer;
      badgeText = cs.primary;
      statusLabel = 'IMPAS (BEP)';
    }

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status Badge & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HASIL KAS BERSIH',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                child: Text(
                  statusLabel,
                  style: tt.labelSmall?.copyWith(
                    color: badgeText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Nilai Laba Bersih
          Text(
            currencyFmt.format(summary.netProfit),
            style: tt.headlineMedium?.copyWith(
              color:
                  isProfit
                      ? AppColors.success
                      : (isLoss ? AppColors.warning : cs.onSurface),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          // Sub-kartu: Pemasukan vs Pengeluaran
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
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
                              color: AppColors.success.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              size: 14,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pemasukan',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFmt.format(summary.totalRevenue),
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
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
                              color: AppColors.error.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              size: 14,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pengeluaran',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFmt.format(summary.totalExpense),
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Business KPI Mini Strip (HPP & Penjualan)
          if (summary.hppPerKg > 0 || summary.totalHarvestWeightKg > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (summary.hppPerKg > 0) ...[
                    Column(
                      children: [
                        Text(
                          'HPP Riil per Kg',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${currencyFmt.format(summary.hppPerKg)}/kg',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (summary.totalHarvestWeightKg > 0) ...[
                    Container(width: 1, height: 24, color: cs.outlineVariant),
                    Column(
                      children: [
                        Text(
                          'Daging Terjual',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${numFmt.format(summary.totalHarvestWeightKg)} kg',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (summary.totalChicksSold > 0) ...[
                    Container(width: 1, height: 24, color: cs.outlineVariant),
                    Column(
                      children: [
                        Text(
                          'Ayam Terjual',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${numFmt.format(summary.totalChicksSold)} ekor',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Visual Progress Struktur Biaya Operasional (Pakan, DOC, OVK, Operasional)
class _CostBreakdownCard extends StatelessWidget {
  final FinanceSummary summary;

  const _CostBreakdownCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STRUKTUR BIAYA OPERASIONAL',
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                currencyFmt.format(summary.totalExpense),
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Multi-color Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (summary.feedExpensePct > 0)
                    Expanded(
                      flex: (summary.feedExpensePct * 10).round().clamp(
                        1,
                        1000,
                      ),
                      child: Container(color: cs.primary),
                    ),
                  if (summary.docExpensePct > 0)
                    Expanded(
                      flex: (summary.docExpensePct * 10).round().clamp(1, 1000),
                      child: Container(color: AppColors.warning),
                    ),
                  if (summary.ovkExpensePct > 0)
                    Expanded(
                      flex: (summary.ovkExpensePct * 10).round().clamp(1, 1000),
                      child: Container(color: AppColors.success),
                    ),
                  if (summary.operationalExpensePct > 0)
                    Expanded(
                      flex: (summary.operationalExpensePct * 10).round().clamp(
                        1,
                        1000,
                      ),
                      child: Container(color: cs.outline),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend Items
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _CostLegendItem(
                color: cs.primary,
                label: 'Pakan: ${summary.feedExpensePct.toStringAsFixed(1)}%',
              ),
              _CostLegendItem(
                color: AppColors.warning,
                label: 'DOC: ${summary.docExpensePct.toStringAsFixed(1)}%',
              ),
              _CostLegendItem(
                color: AppColors.success,
                label: 'OVK: ${summary.ovkExpensePct.toStringAsFixed(1)}%',
              ),
              _CostLegendItem(
                color: cs.outline,
                label:
                    'Lainnya: ${summary.operationalExpensePct.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _CostLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Kartu Item Transaksi yang Informatif & Rapi
class _TransactionCard extends StatelessWidget {
  final FinanceTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final numFmt = NumberFormat.decimalPattern('id_ID');

    final isIncome = transaction.isIncome;
    final txColor = isIncome ? AppColors.success : AppColors.error;

    // Keterangan pendukung (ekor, kg, catatan)
    final metaParts = <String>[];
    if (transaction.birdCount != null && transaction.birdCount! > 0) {
      metaParts.add('${numFmt.format(transaction.birdCount)} ekor');
    }
    if (transaction.weightKg != null && transaction.weightKg! > 0) {
      metaParts.add('${transaction.weightKg!.toStringAsFixed(1)} kg');
    }
    if (transaction.notes.isNotEmpty) {
      metaParts.add(transaction.notes);
    }

    return AppCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icon Kategori Melingkar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      isIncome
                          ? AppColors.success.withValues(alpha: 0.12)
                          : cs.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  transaction.categoryIcon,
                  color: isIncome ? AppColors.success : cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Detail Kategori & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.displayCategory,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    if (metaParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        metaParts.join(' • '),
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Nominal & Tombol Aksi (Edit & Hapus)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${currencyFmt.format(transaction.amount)}',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: txColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Edit',
                                style: tt.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 14,
                                color: cs.error.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Hapus',
                                style: tt.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: cs.error.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: isSelected ? cs.primary : cs.surfaceContainer,
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(
              color:
                  isSelected
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner peringatan ramah saat periode panen selesai tetapi uang penjualan belum dicatat
class _UnrecordedHarvestWarningBanner extends StatelessWidget {
  final VoidCallback onAction;

  const _UnrecordedHarvestWarningBanner({required this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uang Penjualan Panen Belum Dicatat',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Periode ini telah ditutup, namun transaksi penjualan ayam belum dicatat. Nilai laba bersih saat ini belum mencerminkan hasil panen riil.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: cs.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.add_card_rounded, size: 16),
              label: const Text(
                'Catat Uang Panen Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
