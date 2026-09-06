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
import '../../data/models/finance_transaction.dart';
import '../controllers/finance_controller.dart';
import '../widgets/form_finance_bottom_sheet.dart';

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

  void _openAddTransaction(BuildContext context) {
    FormFinanceBottomSheet.show(
      context: context,
      periodId: widget.period.id,
      onSave: (tx) async {
        try {
          await context.read<FinanceController>().addTransaction(tx);
          if (context.mounted) {
            AppSnackbar.showSuccess(context, 'Transaksi keuangan berhasil dicatat');
          }
        } catch (e) {
          if (context.mounted) {
            AppSnackbar.showError(context, 'Gagal mencatat transaksi: $e');
          }
        }
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FinanceTransaction tx,
  ) async {
    final confirmed = await DialogHelper.showConfirm(
      context,
      'Hapus Transaksi',
      'Apakah Anda yakin ingin menghapus transaksi "${tx.categoryEnum.label}" sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(tx.amount)}?',
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final summary = controller.summary;
    final filteredTx = controller.transactions.where((tx) {
      if (_filter == 'expense') return tx.isExpense;
      if (_filter == 'income') return tx.isIncome;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppHeader(
        title: 'Keuangan ${widget.period.name}',
      ),
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
        child: controller.isLoading
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: ReportSkeleton(),
              )
            : CustomScrollView(
                slivers: [
                  // 1. Hero Summary Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primary,
                              cs.primary.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LABA BERSIH PERIODE',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onPrimary.withValues(alpha: 0.75),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFmt.format(summary.netProfit),
                              style: tt.headlineMedium?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pendapatan',
                                        style: tt.labelSmall?.copyWith(
                                          color: cs.onPrimary.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currencyFmt.format(summary.totalRevenue),
                                        style: tt.titleSmall?.copyWith(
                                          color: cs.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: Colors.white24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pengeluaran',
                                        style: tt.labelSmall?.copyWith(
                                          color: cs.onPrimary.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currencyFmt.format(summary.totalExpense),
                                        style: tt.titleSmall?.copyWith(
                                          color: cs.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Filter Pills
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Semua (${controller.transactions.length})',
                            isSelected: _filter == 'all',
                            onTap: () => setState(() => _filter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Pengeluaran',
                            isSelected: _filter == 'expense',
                            onTap: () => setState(() => _filter = 'expense'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Pemasukan',
                            isSelected: _filter == 'income',
                            onTap: () => setState(() => _filter = 'income'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // 3. Transactions List / Empty State
                  if (filteredTx.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: 'Belum Ada Transaksi',
                        subtitle:
                            'Catat biaya pakan, bibit DOC, OVK, dan hasil penjualan ayam untuk kalkulasi laba bersih & HPP otomatis.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final tx = filteredTx[index];
                            final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(tx.date);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppCard(
                                margin: EdgeInsets.zero,
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // Icon Badge
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: tx.isIncome
                                            ? AppColors.success.withValues(alpha: 0.12)
                                            : AppColors.error.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        tx.isIncome
                                            ? Icons.arrow_downward_rounded
                                            : Icons.arrow_upward_rounded,
                                        color: tx.isIncome ? AppColors.success : AppColors.error,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Label & Subtitle
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.categoryEnum.label,
                                            style: tt.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              dateStr,
                                              if (tx.birdCount != null && tx.birdCount! > 0)
                                                '${tx.birdCount} ekor',
                                              if (tx.weightKg != null && tx.weightKg! > 0)
                                                '${tx.weightKg!.toStringAsFixed(1)} kg',
                                              if (tx.notes.isNotEmpty) tx.notes,
                                            ].join(' • '),
                                            style: tt.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Nominal & Action
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${tx.isIncome ? '+' : '-'}${currencyFmt.format(tx.amount)}',
                                          style: tt.labelLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: tx.isIncome ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                          ),
                                          tooltip: 'Hapus Transaksi',
                                          onPressed: () => _confirmDelete(context, tx),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: filteredTx.length,
                        ),
                      ),
                    ),
                ],
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
              color: isSelected
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
