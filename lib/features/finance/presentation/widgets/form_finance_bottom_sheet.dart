import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/components/dialogs/app_form_bottom_sheet.dart';
import '../../../../core/components/forms/app_text_form_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/finance_transaction.dart';

/// Form Bottom Sheet interaktif untuk mencatat transaksi keuangan (Pemasukan / Pengeluaran)
/// Mendukung pemilihan kategori standar, kategori cepat, maupun input kategori manual kustom.
class FormFinanceBottomSheet extends StatefulWidget {
  final String periodId;
  final Function(FinanceTransaction) onSave;

  const FormFinanceBottomSheet({
    super.key,
    required this.periodId,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String periodId,
    required Function(FinanceTransaction) onSave,
  }) {
    return AppFormBottomSheet.show(
      context: context,
      title: 'Catat Transaksi Keuangan',
      subtitle:
          'Catat pengeluaran operasional (Pakan, DOC, OVK) atau pemasukan panen secara rapi dan akurat.',
      icon: Icons.account_balance_wallet_outlined,
      builder: (sheetContext, setModalState) {
        return FormFinanceBottomSheet(
          periodId: periodId,
          onSave: onSave,
        );
      },
    );
  }

  @override
  State<FormFinanceBottomSheet> createState() => _FormFinanceBottomSheetState();
}

class _FormFinanceBottomSheetState extends State<FormFinanceBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'expense'; // 'expense' | 'income'
  String _category = 'feed'; // code standar atau nama kategori manual
  bool _isCustomInputActive = false;

  final _customCategoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _birdCountController = TextEditingController();
  final _weightController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  double? _calculatedPricePerKg;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updatePricePreview);
    _weightController.addListener(_updatePricePreview);
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

  void _updatePricePreview() {
    final rawAmountStr = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    final amount = double.tryParse(rawAmountStr) ?? 0.0;
    final weight = double.tryParse(
      _weightController.text.replaceAll(',', '.').trim(),
    );

    if (amount > 0 && weight != null && weight > 0) {
      setState(() {
        _calculatedPricePerKg = amount / weight;
      });
    } else {
      if (_calculatedPricePerKg != null) {
        setState(() {
          _calculatedPricePerKg = null;
        });
      }
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
    _updatePricePreview();
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
    final rawAmountStr = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final rawAmountStr = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
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

    // Resolusi final kategori (jika kustom manual, ambil teks dari controller)
    final finalCategory = _isCustomInputActive
        ? _customCategoryController.text.trim()
        : _category;

    final tx = FinanceTransaction(
      periodId: widget.periodId,
      type: _type,
      category: finalCategory,
      amount: amount,
      date: _selectedDate,
      notes: _notesController.text.trim(),
      birdCount: birdCount,
      weightKg: weightKg,
      createdAt: DateTime.now(),
    );

    setState(() => _isSubmitting = true);
    widget.onSave(tx);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final isIncome = _type == 'income';

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Hero Guidance Card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.success.withValues(alpha: 0.1)
                  : cs.secondaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppTheme.rowRadius),
              border: Border.all(
                color: isIncome
                    ? AppColors.success.withValues(alpha: 0.25)
                    : cs.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? AppColors.success.withValues(alpha: 0.15)
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isIncome
                        ? 'Catat penerimaan kas dari penjualan ayam panen, afkir, atau sampingan.'
                        : 'Catat pengeluaran operasional secara terperinci untuk kalkulasi HPP yang akurat.',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. Toggle Jenis: Pengeluaran vs Pemasukan ───────────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
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
          const SizedBox(height: 18),

          // ── 3. Pilihan Kategori + Kategori Manual ───────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KATEGORI TRANSAKSI',
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                if (_isCustomInputActive)
                  Text(
                    'Kategori Manual',
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Kategori Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isIncome) ...[
                _CategoryChip(
                  label: 'Penjualan Utama',
                  icon: Icons.scale_rounded,
                  isSelected: !_isCustomInputActive && _category == 'main_harvest',
                  onTap: () => _selectCategory('main_harvest'),
                ),
                _CategoryChip(
                  label: 'Afkir / Reject',
                  icon: Icons.warning_amber_rounded,
                  isSelected: !_isCustomInputActive && _category == 'reject',
                  onTap: () => _selectCategory('reject'),
                ),
                _CategoryChip(
                  label: 'Pupuk / Kohe',
                  icon: Icons.eco_outlined,
                  isSelected: !_isCustomInputActive && _category == 'Pupuk / Kohe',
                  onTap: () => _selectCategory('Pupuk / Kohe'),
                ),
                _CategoryChip(
                  label: 'Karung Bekas',
                  icon: Icons.inventory_2_outlined,
                  isSelected: !_isCustomInputActive && _category == 'Karung Bekas',
                  onTap: () => _selectCategory('Karung Bekas'),
                ),
              ] else ...[
                _CategoryChip(
                  label: 'Pakan',
                  icon: Icons.restaurant_rounded,
                  isSelected: !_isCustomInputActive && _category == 'feed',
                  onTap: () => _selectCategory('feed'),
                ),
                _CategoryChip(
                  label: 'DOC (Bibit)',
                  icon: Icons.pets_rounded,
                  isSelected: !_isCustomInputActive && _category == 'doc',
                  onTap: () => _selectCategory('doc'),
                ),
                _CategoryChip(
                  label: 'OVK (Obat/Vaksin)',
                  icon: Icons.medication_liquid_rounded,
                  isSelected: !_isCustomInputActive && _category == 'ovk',
                  onTap: () => _selectCategory('ovk'),
                ),
                _CategoryChip(
                  label: 'Sekam',
                  icon: Icons.layers_outlined,
                  isSelected: !_isCustomInputActive && _category == 'Sekam',
                  onTap: () => _selectCategory('Sekam'),
                ),
                _CategoryChip(
                  label: 'Gaji ABK',
                  icon: Icons.badge_outlined,
                  isSelected: !_isCustomInputActive && _category == 'Gaji ABK',
                  onTap: () => _selectCategory('Gaji ABK'),
                ),
                _CategoryChip(
                  label: 'Listrik & Air',
                  icon: Icons.bolt_rounded,
                  isSelected: !_isCustomInputActive && _category == 'Listrik & Air',
                  onTap: () => _selectCategory('Listrik & Air'),
                ),
                _CategoryChip(
                  label: 'Operasional',
                  icon: Icons.engineering_rounded,
                  isSelected: !_isCustomInputActive && _category == 'operational',
                  onTap: () => _selectCategory('operational'),
                ),
              ],

              // Tombol Kategori Manual / Lainnya
              _CategoryChip(
                label: '+ Kategori Lain',
                icon: Icons.add_circle_outline_rounded,
                isSelected: _isCustomInputActive,
                onTap: () => _selectCategory('', isCustom: true),
              ),
            ],
          ),

          // Input Text Khusus Kategori Manual
          if (_isCustomInputActive) ...[
            const SizedBox(height: 12),
            AppTextFormField(
              controller: _customCategoryController,
              labelText: 'Nama Kategori Manual',
              hintText: isIncome
                  ? 'Contoh: Bonus Kemitraan / Jual Peralatan Bekas'
                  : 'Contoh: Disinfektan / Gas Pemanas / Sewa Genset',
              prefixIcon: Icons.edit_note_rounded,
              validator: (val) {
                if (_isCustomInputActive && (val == null || val.trim().isEmpty)) {
                  return 'Ketik nama kategori manual Anda';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),

          // ── 4. Nominal (Rp) & Quick Amount Helpers ─────────────────────────
          AppTextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            labelText: 'Nominal Transaksi (Rp)',
            hintText: 'Contoh: 15000000',
            prefixIcon: Icons.payments_outlined,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Nominal wajib diisi.';
              }
              final numVal = double.tryParse(
                val.replaceAll('.', '').replaceAll(',', '').trim(),
              );
              if (numVal == null || numVal <= 0) {
                return 'Masukkan nominal yang lebih dari Rp 0.';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Tombol Cepat Nominal (+100rb, +500rb, +1jt, +5jt)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickAmountPill(
                  label: '+100 Ribu',
                  onTap: () => _addQuickAmount(100000),
                ),
                const SizedBox(width: 6),
                _QuickAmountPill(
                  label: '+500 Ribu',
                  onTap: () => _addQuickAmount(500000),
                ),
                const SizedBox(width: 6),
                _QuickAmountPill(
                  label: '+1 Juta',
                  onTap: () => _addQuickAmount(1000000),
                ),
                const SizedBox(width: 6),
                _QuickAmountPill(
                  label: '+5 Juta',
                  onTap: () => _addQuickAmount(5000000),
                ),
                const SizedBox(width: 6),
                _QuickAmountPill(
                  label: '+10 Juta',
                  onTap: () => _addQuickAmount(10000000),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 5. Input Tambahan (Khusus Penjualan: Ekor & Bobot) ───────────────
          if (isIncome) ...[
            Row(
              children: [
                Expanded(
                  child: AppTextFormField(
                    controller: _birdCountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    labelText: 'Ayam Dijual (Ekor)',
                    hintText: 'Opsional: 4800',
                    prefixIcon: Icons.groups_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    labelText: 'Total Bobot (Kg)',
                    hintText: 'Opsional: 8900',
                    prefixIcon: Icons.scale_rounded,
                  ),
                ),
              ],
            ),
            if (_calculatedPricePerKg != null && _calculatedPricePerKg! > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Harga Jual Rata-rata:',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${currencyFmt.format(_calculatedPricePerKg)} / kg',
                      style: tt.titleSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
          ],

          // ── 6. Tanggal Transaksi ───────────────────────────────────────────
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Tanggal Transaksi',
                prefixIcon: const Icon(Icons.calendar_today_rounded),
                suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                filled: true,
                fillColor: cs.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
              child: Text(
                dateFmt.format(_selectedDate),
                style: tt.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── 7. Catatan / Keterangan ─────────────────────────────────────────
          AppTextFormField(
            controller: _notesController,
            labelText: 'Catatan / Keterangan (Opsional)',
            hintText: isIncome
                ? 'Contoh: Pembeli Bakul Pak Slamet / PT Sumber Unggas'
                : 'Contoh: Pakan Starter 50 sak dari Toko Tani Makmur',
            prefixIcon: Icons.notes_rounded,
          ),
          const SizedBox(height: 24),

          // ── 8. Tombol Aksi ──────────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isIncome ? AppColors.success : cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
              onPressed: _isSubmitting ? null : _submit,
              child: Text(
                _isSubmitting
                    ? 'Menyimpan...'
                    : (isIncome
                        ? 'Simpan Pemasukan'
                        : 'Simpan Pengeluaran'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
      color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
                    color: isSelected ? activeColor : cs.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FilterChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? cs.onPrimary : cs.primary,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: tt.labelSmall?.copyWith(
        color: isSelected ? cs.onPrimary : cs.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        side: BorderSide(
          color: isSelected ? cs.primary : cs.outlineVariant,
        ),
      ),
      showCheckmark: false,
    );
  }
}

class _QuickAmountPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountPill({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      labelStyle: tt.labelSmall?.copyWith(
        color: cs.primary,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: cs.surfaceContainer,
      side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
    );
  }
}
