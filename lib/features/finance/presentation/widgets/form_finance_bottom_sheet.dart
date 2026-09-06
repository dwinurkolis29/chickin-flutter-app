import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/components/dialogs/app_form_bottom_sheet.dart';
import '../../../../core/components/forms/app_text_form_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/finance_transaction.dart';

/// Form Bottom Sheet untuk input transaksi keuangan (Pemasukan / Pengeluaran)
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
          'Catat pengeluaran operasional (Pakan, DOC, OVK) atau pemasukan hasil penjualan ayam:',
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
  String _category = 'feed'; // feed, doc, ovk, operational, main_harvest, reject

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _birdCountController = TextEditingController();
  final _weightController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _birdCountController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    setState(() {
      _type = newType;
      if (newType == 'expense') {
        _category = 'feed';
      } else {
        _category = 'main_harvest';
      }
    });
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

    final rawAmountStr = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final amount = double.tryParse(rawAmountStr) ?? 0.0;

    int? birdCount;
    if (_birdCountController.text.trim().isNotEmpty) {
      birdCount = int.tryParse(_birdCountController.text.replaceAll('.', '').trim());
    }

    double? weightKg;
    if (_weightController.text.trim().isNotEmpty) {
      weightKg = double.tryParse(_weightController.text.replaceAll(',', '.').trim());
    }

    final tx = FinanceTransaction(
      periodId: widget.periodId,
      type: _type,
      category: _category,
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
    final dateFmt = DateFormat('dd MMMM yyyy', 'id_ID');

    final isIncome = _type == 'income';

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Toggle Jenis: Pengeluaran vs Pemasukan
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TypeToggleButton(
                    label: 'Pengeluaran',
                    icon: Icons.arrow_upward_rounded,
                    isSelected: !isIncome,
                    activeColor: AppColors.error,
                    onTap: () => _onTypeChanged('expense'),
                  ),
                ),
                Expanded(
                  child: _TypeToggleButton(
                    label: 'Pemasukan',
                    icon: Icons.arrow_downward_rounded,
                    isSelected: isIncome,
                    activeColor: AppColors.success,
                    onTap: () => _onTypeChanged('income'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Pilihan Kategori
          Text(
            'KATEGORI',
            style: tt.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: isIncome
                ? [
                    _CategoryChip(
                      label: 'Penjualan Utama',
                      isSelected: _category == 'main_harvest',
                      onTap: () => setState(() => _category = 'main_harvest'),
                    ),
                    _CategoryChip(
                      label: 'Afkir / Reject',
                      isSelected: _category == 'reject',
                      onTap: () => setState(() => _category = 'reject'),
                    ),
                  ]
                : [
                    _CategoryChip(
                      label: 'Pakan',
                      isSelected: _category == 'feed',
                      onTap: () => setState(() => _category = 'feed'),
                    ),
                    _CategoryChip(
                      label: 'DOC',
                      isSelected: _category == 'doc',
                      onTap: () => setState(() => _category = 'doc'),
                    ),
                    _CategoryChip(
                      label: 'OVK (Obat/Vaksin)',
                      isSelected: _category == 'ovk',
                      onTap: () => setState(() => _category = 'ovk'),
                    ),
                    _CategoryChip(
                      label: 'Operasional',
                      isSelected: _category == 'operational',
                      onTap: () => setState(() => _category = 'operational'),
                    ),
                  ],
          ),
          const SizedBox(height: 16),

          // 3. Nominal (Rp)
          AppTextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            labelText: 'Nominal Biaya (Rp)',
            hintText: 'Contoh: 15000000',
            prefixIcon: Icons.payments_outlined,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Nominal wajib diisi.';
              }
              final numVal = double.tryParse(val.replaceAll('.', '').replaceAll(',', '').trim());
              if (numVal == null || numVal <= 0) {
                return 'Masukkan nominal yang lebih dari Rp 0.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // 4. Khusus Penjualan: Input Tambahan Ekor & Bobot (Kg)
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    labelText: 'Total Bobot (Kg)',
                    hintText: 'Opsional: 8900',
                    prefixIcon: Icons.scale_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // 5. Tanggal Transaksi
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            child: IgnorePointer(
              child: AppTextFormField(
                controller: TextEditingController(text: dateFmt.format(_selectedDate)),
                readOnly: true,
                labelText: 'Tanggal Transaksi',
                prefixIcon: Icons.calendar_today_rounded,
                suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 6. Catatan / Keterangan
          AppTextFormField(
            controller: _notesController,
            labelText: 'Catatan / Keterangan (Opsional)',
            hintText: isIncome ? 'Contoh: Penjualan panen ke PT Mitra' : 'Contoh: Pakan Starter 20 sak',
            prefixIcon: Icons.notes_rounded,
          ),
          const SizedBox(height: 20),

          // 7. Tombol Simpan
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
            ),
            onPressed: _isSubmitting ? null : _submit,
            child: Text(
              _isSubmitting ? 'Menyimpan...' : 'Simpan Transaksi',
              style: tt.labelLarge?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
            ),
            child: const Text('Batal'),
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
              Text(
                label,
                style: tt.labelMedium?.copyWith(
                  color: isSelected ? activeColor : cs.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: tt.labelSmall?.copyWith(
        color: isSelected ? cs.onPrimary : cs.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
