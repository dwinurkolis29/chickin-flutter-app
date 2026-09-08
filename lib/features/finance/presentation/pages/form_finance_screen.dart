import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/components/forms/app_text_form_field.dart';
import '../../../../core/components/header/app_header.dart';
import '../../../../core/components/snackbars/app_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/finance_transaction.dart';
import '../controllers/finance_controller.dart';

/// Layar form mandiri untuk mencatat transaksi keuangan broiler (Pemasukan / Pengeluaran).
/// Menggantikan modal bottom sheet agar peternak dapat mengisi data transaksi
/// yang komprehensif (kategori, nominal, rincian panen, nota) dengan nyaman dan leluasa.
class FormFinanceScreen extends StatefulWidget {
  final String periodId;
  final String? periodName;
  final Function(FinanceTransaction)? onSave;
  final FinanceController? controller;
  final FinanceTransaction? existingTransaction;
  final String? initialType;
  final String? initialCategory;
  final int? initialBirdCount;
  final double? initialWeightKg;
  final double? initialAmount;

  const FormFinanceScreen({
    super.key,
    required this.periodId,
    this.periodName,
    this.onSave,
    this.controller,
    this.existingTransaction,
    this.initialType,
    this.initialCategory,
    this.initialBirdCount,
    this.initialWeightKg,
    this.initialAmount,
  });

  @override
  State<FormFinanceScreen> createState() => _FormFinanceScreenState();
}

class _FormFinanceScreenState extends State<FormFinanceScreen> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'expense'; // 'expense' | 'income'
  String _category = 'feed'; // code bawaan atau nama kustom
  bool _isCustomInputActive = false;

  final _customCategoryController = TextEditingController();
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  late final TextEditingController _birdCountController;
  late final TextEditingController _weightController;

  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  double? _calculatedPricePerKg;
  double? _calculatedAvgWeightKg;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;
    if (tx != null) {
      _type = tx.type;
      _selectedDate = tx.date;
      _notesController.text = tx.notes ?? '';

      final standardExpenseCodes = {
        'feed',
        'doc',
        'ovk',
        'labor',
        'electricity',
        'gas_husk',
        'other_expense',
      };
      final standardIncomeCodes = {
        'main_harvest',
        'cull_harvest',
        'manure',
        'feed_sack',
        'other_income',
      };

      if (tx.isExpense) {
        if (standardExpenseCodes.contains(tx.category)) {
          _category = tx.category;
          _isCustomInputActive = false;
        } else {
          _category = 'other_expense';
          _isCustomInputActive = true;
          _customCategoryController.text = tx.category;
        }
      } else {
        if (standardIncomeCodes.contains(tx.category)) {
          _category = tx.category;
          _isCustomInputActive = false;
        } else {
          _category = 'other_income';
          _isCustomInputActive = true;
          _customCategoryController.text = tx.category;
        }
      }

      final initAmountStr =
          tx.amount > 0
              ? NumberFormat.decimalPattern('id_ID').format(tx.amount.round())
              : '';
      _amountController = TextEditingController(text: initAmountStr);

      final initBirdsStr =
          tx.birdCount != null && tx.birdCount! > 0
              ? tx.birdCount.toString()
              : '';
      _birdCountController = TextEditingController(text: initBirdsStr);

      final initWeightStr =
          tx.weightKg != null && tx.weightKg! > 0
              ? (tx.weightKg! % 1 == 0
                  ? tx.weightKg!.toInt().toString()
                  : tx.weightKg!.toStringAsFixed(1))
              : '';
      _weightController = TextEditingController(text: initWeightStr);
    } else {
      if (widget.initialType != null) {
        _type = widget.initialType!;
      }
      if (widget.initialCategory != null) {
        _category = widget.initialCategory!;
      }

      final initAmountStr =
          widget.initialAmount != null && widget.initialAmount! > 0
              ? NumberFormat.decimalPattern(
                'id_ID',
              ).format(widget.initialAmount!.round())
              : '';
      _amountController = TextEditingController(text: initAmountStr);

      final initBirdsStr =
          widget.initialBirdCount != null && widget.initialBirdCount! > 0
              ? widget.initialBirdCount.toString()
              : '';
      _birdCountController = TextEditingController(text: initBirdsStr);

      final initWeightStr =
          widget.initialWeightKg != null && widget.initialWeightKg! > 0
              ? (widget.initialWeightKg! % 1 == 0
                  ? widget.initialWeightKg!.toInt().toString()
                  : widget.initialWeightKg!.toStringAsFixed(1))
              : '';
      _weightController = TextEditingController(text: initWeightStr);
    }

    _amountController.addListener(_updateCalculatedMetrics);
    _weightController.addListener(_updateCalculatedMetrics);
    _birdCountController.addListener(_updateCalculatedMetrics);

    if (_amountController.text.isNotEmpty ||
        _weightController.text.isNotEmpty ||
        _birdCountController.text.isNotEmpty) {
      _updateCalculatedMetrics();
    }
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _birdCountController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _updateCalculatedMetrics() {
    final rawAmountStr =
        _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final amount = double.tryParse(rawAmountStr) ?? 0.0;

    final weight = double.tryParse(
      _weightController.text.replaceAll(',', '.').trim(),
    );

    final birdCount = int.tryParse(
      _birdCountController.text.replaceAll('.', '').trim(),
    );

    double? pricePerKg;
    if (amount > 0 && weight != null && weight > 0) {
      pricePerKg = amount / weight;
    }

    double? avgWeight;
    if (weight != null && weight > 0 && birdCount != null && birdCount > 0) {
      avgWeight = weight / birdCount;
    }

    if (_calculatedPricePerKg != pricePerKg ||
        _calculatedAvgWeightKg != avgWeight) {
      setState(() {
        _calculatedPricePerKg = pricePerKg;
        _calculatedAvgWeightKg = avgWeight;
      });
    }
  }

  void _onTypeChanged(String newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      _isCustomInputActive = false;
      _customCategoryController.clear();
      if (newType == 'expense') {
        _category = 'feed';
      } else {
        _category = 'main_harvest';
      }
    });
    _updateCalculatedMetrics();
  }

  void _selectCategory(String code, {bool isCustom = false}) {
    setState(() {
      _category = code;
      _isCustomInputActive = isCustom;
      if (!isCustom) {
        _customCategoryController.clear();
      }
    });
  }

  void _addQuickAmount(int additional) {
    final rawAmountStr =
        _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final current = int.tryParse(rawAmountStr) ?? 0;
    final updated = current + additional;
    final numFmt = NumberFormat.decimalPattern('id_ID');
    _amountController.text = numFmt.format(updated);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rawAmountStr =
        _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final amount = double.tryParse(rawAmountStr) ?? 0.0;

    int? birdCount;
    if (_birdCountController.text.trim().isNotEmpty) {
      birdCount = int.tryParse(
        _birdCountController.text.replaceAll('.', '').trim(),
      );
    }

    double? weightKg;
    if (_weightController.text.trim().isNotEmpty) {
      weightKg = double.tryParse(
        _weightController.text.replaceAll(',', '.').trim(),
      );
    }

    final finalCategory =
        _isCustomInputActive
            ? _customCategoryController.text.trim()
            : _category;

    final isEdit = widget.existingTransaction != null;
    final tx = FinanceTransaction(
      id: widget.existingTransaction?.id ?? '',
      periodId: widget.periodId,
      type: _type,
      category: finalCategory,
      amount: amount,
      date: _selectedDate,
      notes: _notesController.text.trim(),
      birdCount: birdCount,
      weightKg: weightKg,
      createdAt: widget.existingTransaction?.createdAt ?? DateTime.now(),
    );

    setState(() => _isSubmitting = true);

    try {
      if (widget.onSave != null) {
        await widget.onSave!(tx);
      } else {
        final ctrl = widget.controller ?? context.read<FinanceController>();
        if (isEdit) {
          await ctrl.updateTransaction(tx);
        } else {
          await ctrl.addTransaction(tx);
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppSnackbar.showError(
          context,
          isEdit
              ? 'Gagal mengubah transaksi: $e'
              : 'Gagal menyimpan transaksi: $e',
        );
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: tt.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isIncome = _type == 'income';
    final dateFmt = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final showPoultryDetails =
        isIncome || _category == 'main_harvest' || _category == 'reject';

    final isEdit = widget.existingTransaction != null;
    final headerTitle =
        isEdit
            ? (widget.periodName != null
                ? 'Edit Transaksi (${widget.periodName})'
                : 'Edit Transaksi Keuangan')
            : (widget.periodName != null
                ? 'Catat Transaksi (${widget.periodName})'
                : 'Catat Transaksi Keuangan');

    return Scaffold(
      appBar: AppHeader(title: headerTitle),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. Hero Guidance Card ────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isIncome
                                ? AppColors.success.withValues(alpha: 0.08)
                                : cs.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius,
                        ),
                        border: Border.all(
                          color:
                              isIncome
                                  ? AppColors.success.withValues(alpha: 0.25)
                                  : cs.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  isIncome
                                      ? AppColors.success.withValues(
                                        alpha: 0.15,
                                      )
                                      : cs.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.savings_outlined
                                  : Icons.receipt_long_outlined,
                              color: isIncome ? AppColors.success : cs.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isIncome
                                  ? 'Catat hasil penjualan ayam panen, afkir, atau sampingan secara transparan untuk memantau laba bersih.'
                                  : 'Catat pengeluaran operasional (Pakan, DOC, OVK, dll.) secara akurat untuk kalkulasi HPP riil kandang.',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 2. Segmented Jenis Transaksi ─────────────────────────
                    _buildSectionHeader(context, 'JENIS KAS TRANSAKSI'),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TypeToggleButton(
                              label: 'Pengeluaran (Kas Keluar)',
                              icon: Icons.arrow_upward_rounded,
                              isSelected: !isIncome,
                              activeColor: AppColors.error,
                              onTap: () => _onTypeChanged('expense'),
                            ),
                          ),
                          Expanded(
                            child: _TypeToggleButton(
                              label: 'Pemasukan (Kas Masuk)',
                              icon: Icons.arrow_downward_rounded,
                              isSelected: isIncome,
                              activeColor: AppColors.success,
                              onTap: () => _onTypeChanged('income'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 3. Kategori Transaksi ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader(context, 'KATEGORI TRANSAKSI'),
                        if (_isCustomInputActive)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextButton.icon(
                              onPressed: () {
                                _selectCategory(
                                  isIncome ? 'main_harvest' : 'feed',
                                );
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text(
                                'Pilih Bawaan',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (!isIncome) ...[
                      // Kategori Pengeluaran
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CategorySelectCard(
                            label: 'Pakan',
                            icon: Icons.restaurant_rounded,
                            isSelected:
                                !_isCustomInputActive && _category == 'feed',
                            onTap: () => _selectCategory('feed'),
                          ),
                          _CategorySelectCard(
                            label: 'DOC (Bibit)',
                            icon: Icons.egg_outlined,
                            isSelected:
                                !_isCustomInputActive && _category == 'doc',
                            onTap: () => _selectCategory('doc'),
                          ),
                          _CategorySelectCard(
                            label: 'OVK (Obat/Vaksin)',
                            icon: Icons.medication_liquid_outlined,
                            isSelected:
                                !_isCustomInputActive && _category == 'ovk',
                            onTap: () => _selectCategory('ovk'),
                          ),
                          _CategorySelectCard(
                            label: 'Tenaga Kerja',
                            icon: Icons.badge_outlined,
                            isSelected:
                                !_isCustomInputActive &&
                                _category == 'Gaji / Upah ABK',
                            onTap:
                                () => _selectCategory(
                                  'Gaji / Upah ABK',
                                  isCustom: false,
                                ),
                          ),
                          _CategorySelectCard(
                            label: 'Listrik & Air',
                            icon: Icons.electric_bolt_outlined,
                            isSelected:
                                !_isCustomInputActive &&
                                _category == 'Listrik & Air',
                            onTap:
                                () => _selectCategory(
                                  'Listrik & Air',
                                  isCustom: false,
                                ),
                          ),
                          _CategorySelectCard(
                            label: 'Sekam & Gas',
                            icon: Icons.local_fire_department_outlined,
                            isSelected:
                                !_isCustomInputActive && _category == 'Sekam',
                            onTap:
                                () => _selectCategory('Sekam', isCustom: false),
                          ),
                          _CategorySelectCard(
                            label: 'Operasional Lain',
                            icon: Icons.engineering_outlined,
                            isSelected:
                                !_isCustomInputActive &&
                                _category == 'operational',
                            onTap: () => _selectCategory('operational'),
                          ),
                          _CategorySelectCard(
                            label: '+ Kategori Lain',
                            icon: Icons.add_circle_outline_rounded,
                            isSelected: _isCustomInputActive,
                            onTap: () => _selectCategory('', isCustom: true),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Kategori Pemasukan
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CategorySelectCard(
                            label: 'Penjualan Utama',
                            icon: Icons.scale_rounded,
                            isSelected:
                                !_isCustomInputActive &&
                                _category == 'main_harvest',
                            onTap: () => _selectCategory('main_harvest'),
                          ),
                          _CategorySelectCard(
                            label: 'Afkir / Reject',
                            icon: Icons.warning_amber_rounded,
                            isSelected:
                                !_isCustomInputActive && _category == 'reject',
                            onTap: () => _selectCategory('reject'),
                          ),
                          _CategorySelectCard(
                            label: 'Pupuk / Kohe',
                            icon: Icons.eco_outlined,
                            isSelected:
                                !_isCustomInputActive &&
                                _category == 'Penjualan Pupuk / Kohe',
                            onTap:
                                () => _selectCategory(
                                  'Penjualan Pupuk / Kohe',
                                  isCustom: false,
                                ),
                          ),
                          _CategorySelectCard(
                            label: 'Karung Bekas',
                            icon: Icons.shopping_bag_outlined,
                            isSelected:
                                !_isCustomInputActive &&
                                _category == 'Penjualan Karung Bekas',
                            onTap:
                                () => _selectCategory(
                                  'Penjualan Karung Bekas',
                                  isCustom: false,
                                ),
                          ),
                          _CategorySelectCard(
                            label: '+ Kategori Lain',
                            icon: Icons.add_circle_outline_rounded,
                            isSelected: _isCustomInputActive,
                            onTap: () => _selectCategory('', isCustom: true),
                          ),
                        ],
                      ),
                    ],

                    if (_isCustomInputActive) ...[
                      const SizedBox(height: 14),
                      AppTextFormField(
                        controller: _customCategoryController,
                        labelText: 'Nama Kategori Manual',
                        hintText:
                            isIncome
                                ? 'Misal: Bonus Mitra, Penjualan Ayam Sakit'
                                : 'Misal: Beli Terpal, Biaya Ekspedisi, Oli Genset',
                        prefixIcon: Icons.edit_note_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama kategori manual wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── 4. Nominal Transaksi ─────────────────────────────────
                    _buildSectionHeader(context, 'NOMINAL TRANSAKSI'),
                    AppTextFormField(
                      controller: _amountController,
                      labelText: 'Nominal Kas (Rp)',
                      hintText: '0',
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ThousandsSeparatorFormatter(),
                      ],
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nominal transaksi wajib diisi';
                        }
                        final numVal = double.tryParse(
                          val.replaceAll('.', '').replaceAll(',', '').trim(),
                        );
                        if (numVal == null || numVal <= 0) {
                          return 'Nominal harus lebih besar dari Rp 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Quick Add Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickAmountChip(
                            label: '+50 rb',
                            onTap: () => _addQuickAmount(50000),
                          ),
                          const SizedBox(width: 8),
                          _QuickAmountChip(
                            label: '+100 rb',
                            onTap: () => _addQuickAmount(100000),
                          ),
                          const SizedBox(width: 8),
                          _QuickAmountChip(
                            label: '+500 rb',
                            onTap: () => _addQuickAmount(500000),
                          ),
                          const SizedBox(width: 8),
                          _QuickAmountChip(
                            label: '+1 jt',
                            onTap: () => _addQuickAmount(1000000),
                          ),
                          const SizedBox(width: 8),
                          _QuickAmountChip(
                            label: '+5 jt',
                            onTap: () => _addQuickAmount(5000000),
                          ),
                          const SizedBox(width: 8),
                          _QuickAmountChip(
                            label: '+10 jt',
                            onTap: () => _addQuickAmount(10000000),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 5. Detail Penjualan Ayam (Opsional) ──────────────────
                    if (showPoultryDetails) ...[
                      _buildSectionHeader(
                        context,
                        'RINCIAN PENJUALAN AYAM (OPSIONAL)',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextFormField(
                              controller: _birdCountController,
                              labelText: 'Jumlah Ekor',
                              hintText: '0',
                              prefixIcon: Icons.numbers_rounded,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextFormField(
                              controller: _weightController,
                              labelText: 'Total Bobot (Kg)',
                              hintText: '0.0',
                              prefixIcon: Icons.scale_rounded,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      // Live Preview Metrik Panen
                      if (_calculatedPricePerKg != null ||
                          _calculatedAvgWeightKg != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainer,
                            borderRadius: BorderRadius.circular(
                              AppTheme.rowRadius,
                            ),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (_calculatedPricePerKg != null) ...[
                                Column(
                                  children: [
                                    Text(
                                      'Harga Realisasi per Kg',
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${currencyFmt.format(_calculatedPricePerKg)}/kg',
                                      style: tt.titleSmall?.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (_calculatedPricePerKg != null &&
                                  _calculatedAvgWeightKg != null)
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: cs.outlineVariant,
                                ),
                              if (_calculatedAvgWeightKg != null) ...[
                                Column(
                                  children: [
                                    Text(
                                      'Bobot Rata-rata Ekor',
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_calculatedAvgWeightKg!.toStringAsFixed(2)} kg/ekor',
                                      style: tt.titleSmall?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],

                    // ── 6. Tanggal & Catatan ─────────────────────────────────
                    _buildSectionHeader(context, 'WAKTU & KETERANGAN'),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          border: Border.all(color: cs.outline),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal Transaksi',
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    dateFmt.format(_selectedDate),
                                    style: tt.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    AppTextFormField(
                      controller: _notesController,
                      labelText: 'Catatan / Nomor Nota (Opsional)',
                      hintText:
                          'Misal: Nota #1023, Pembayaran tunai, Tonase 5.2 ton',
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    // ── 7. Primary CTA Button ────────────────────────────────
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.surface,
                                ),
                              )
                              : Text(
                                isEdit
                                    ? 'Simpan Perubahan'
                                    : 'Simpan Transaksi Keuangan',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol Segmented Toggle Kas Masuk vs Kas Keluar
class _TypeToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color:
          isSelected
              ? activeColor.withValues(alpha: 0.15)
              : AppColors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? activeColor : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? activeColor : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu Pilihan Kategori Cepat
class _CategorySelectCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategorySelectCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: isSelected ? cs.primary : cs.surfaceContainer,
      borderRadius: BorderRadius.circular(AppTheme.rowRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.rowRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.rowRadius),
            border: Border.all(
              color:
                  isSelected
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.7),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? cs.onPrimary : cs.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: tt.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip Cepat Tambah Nominal
class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Formatter Pemisah Ribuan (Titik) Otomatis
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digitsOnly = newValue.text.replaceAll('.', '').replaceAll(',', '');
    final number = int.tryParse(digitsOnly);
    if (number == null) return oldValue;

    final formatter = NumberFormat.decimalPattern('id_ID');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
