import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/components/dialogs/app_form_bottom_sheet.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/period/data/models/harvest_record.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

/// Hasil dari modal input panen parsial
class PartialHarvestResult {
  final HarvestRecord harvest;
  final bool createIncomeTransaction;

  const PartialHarvestResult({
    required this.harvest,
    this.createIncomeTransaction = false,
  });
}

/// Bottom sheet interaktif pencatatan Panen Parsial (Penjarangan)
/// dilengkapi SOP Biosekuriti & Penyekatan, input data panen, serta opsi kas masuk.
class PartialHarvestDialog extends StatefulWidget {
  final PeriodData period;
  final int currentLiveChicks;

  const PartialHarvestDialog({
    super.key,
    required this.period,
    required this.currentLiveChicks,
  });

  static Future<PartialHarvestResult?> show({
    required BuildContext context,
    required PeriodData period,
    required int currentLiveChicks,
  }) {
    return AppFormBottomSheet.show<PartialHarvestResult>(
      context: context,
      title: 'Panen Parsial (Penjarangan)',
      subtitle:
          'Kurangi kepadatan kandang atau lakukan penjualan bertahap pada periode "${period.name}".',
      icon: Icons.scale_rounded,
      builder: (sheetContext, setModalState) {
        return PartialHarvestDialog(
          period: period,
          currentLiveChicks: currentLiveChicks,
        );
      },
    );
  }

  @override
  State<PartialHarvestDialog> createState() => _PartialHarvestDialogState();
}

class _PartialHarvestDialogState extends State<PartialHarvestDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late final TextEditingController _dayController;
  final _chicksController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  double? _calculatedAvgWeight;
  bool _recordIncome = false;
  double? _calculatedRevenue;

  // SOP Biosekuriti Checklist States
  bool _sopVehicleCleaned = false;
  bool _sopPersonnelBoot = false;
  bool _sopHousePartitioned = false;
  bool _sopFeedWithdrawal = false;
  bool _sopExpanded = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    final defaultDay = _selectedDate
        .difference(widget.period.startDate)
        .inDays
        .clamp(1, 999);
    _dayController = TextEditingController(text: defaultDay.toString());

    _chicksController.addListener(_recalculateAvg);
    _weightController.addListener(_recalculateAvg);
    _priceController.addListener(_recalculateRevenue);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _chicksController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateAvg() {
    final chicks = int.tryParse(
      _chicksController.text.replaceAll('.', '').replaceAll(',', '').trim(),
    );
    final weight = double.tryParse(
      _weightController.text.replaceAll(',', '.').trim(),
    );

    if (chicks != null && chicks > 0 && weight != null && weight > 0) {
      setState(() {
        _calculatedAvgWeight = weight / chicks;
      });
    } else {
      if (_calculatedAvgWeight != null) {
        setState(() {
          _calculatedAvgWeight = null;
        });
      }
    }
    _recalculateRevenue();
  }

  void _recalculateRevenue() {
    final weight = double.tryParse(
      _weightController.text.replaceAll(',', '.').trim(),
    );
    final price = double.tryParse(
      _priceController.text.replaceAll('.', '').replaceAll(',', '').trim(),
    );

    if (weight != null && weight > 0 && price != null && price > 0) {
      setState(() {
        _calculatedRevenue = weight * price;
      });
    } else {
      if (_calculatedRevenue != null) {
        setState(() {
          _calculatedRevenue = null;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.period.startDate,
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        final ageDay = picked
            .difference(widget.period.startDate)
            .inDays
            .clamp(1, 999);
        _dayController.text = ageDay.toString();
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final chicks = int.parse(
      _chicksController.text.replaceAll('.', '').replaceAll(',', '').trim(),
    );
    final weight = double.parse(
      _weightController.text.replaceAll(',', '.').trim(),
    );
    final day = int.tryParse(_dayController.text.trim()) ?? 1;
    final pricePerKg = double.tryParse(
      _priceController.text.replaceAll('.', '').replaceAll(',', '').trim(),
    );

    final harvest = HarvestRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: HarvestType.partial,
      date: _selectedDate,
      day: day,
      chicks: chicks,
      weightKg: weight,
      avgWeightKg: weight / chicks,
      pricePerKg: pricePerKg,
      totalRevenue: _calculatedRevenue,
      notes:
          _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(
      PartialHarvestResult(
        harvest: harvest,
        createIncomeTransaction: _recordIncome,
      ),
    );
  }

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

    final allSopChecked =
        _sopVehicleCleaned &&
        _sopPersonnelBoot &&
        _sopHousePartitioned &&
        _sopFeedWithdrawal;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. SOP Biosekuriti & Penyekatan (Mitigasi Risiko) ───────────────
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(
                color:
                    allSopChecked
                        ? cs.primary.withValues(alpha: 0.3)
                        : cs.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _sopExpanded = !_sopExpanded),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                allSopChecked
                                    ? cs.primary.withValues(alpha: 0.15)
                                    : cs.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            allSopChecked
                                ? Icons.verified_user_rounded
                                : Icons.health_and_safety_outlined,
                            size: 18,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checklist SOP Biosekuriti & Penyekatan',
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                allSopChecked
                                    ? 'Semua prosedur mitigasi risiko terpenuhi'
                                    : 'Wajib dipastikan sebelum armada/tim tangkap masuk',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _sopExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_sopExpanded) ...[
                  const Divider(height: 1),
                  CheckboxListTile(
                    dense: true,
                    value: _sopVehicleCleaned,
                    onChanged:
                        (v) => setState(() => _sopVehicleCleaned = v ?? false),
                    title: Text(
                      'Desinfeksi roda armada truk & keranjang ayam luar',
                      style: tt.bodySmall,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    dense: true,
                    value: _sopPersonnelBoot,
                    onChanged:
                        (v) => setState(() => _sopPersonnelBoot = v ?? false),
                    title: Text(
                      'Tim tangkap cuci tangan & gunakan sepatu boot bersih',
                      style: tt.bodySmall,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    dense: true,
                    value: _sopHousePartitioned,
                    onChanged:
                        (v) =>
                            setState(() => _sopHousePartitioned = v ?? false),
                    title: Text(
                      'Kandang disekat agar ayam sisa tidak panik/menumpuk',
                      style: tt.bodySmall,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    dense: true,
                    value: _sopFeedWithdrawal,
                    onChanged:
                        (v) => setState(() => _sopFeedWithdrawal = v ?? false),
                    title: Text(
                      'Puasakan pakan 6–8 jam sebelum tangkap (air tetap jalan)',
                      style: tt.bodySmall,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. Informasi Populasi Saat Ini ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppTheme.rowRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sisa Ayam Hidup Saat Ini:',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${numFmt.format(widget.currentLiveChicks)} ekor',
                  style: tt.titleSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 3. Tanggal & Umur Panen ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal Panen',
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                      filled: true,
                      fillColor: cs.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate),
                      style: tt.bodyMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: AppTextFormField(
                  controller: _dayController,
                  labelText: 'Umur (Hari)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Wajib';
                    final v = int.tryParse(val.trim());
                    if (v == null || v <= 0) return 'Tidak valid';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 4. Ekor & Bobot Panen ───────────────────────────────────────────
          AppTextFormField(
            controller: _chicksController,
            labelText: 'Jumlah Ayam Dipanen (ekor)',
            hintText: 'Contoh: 2500',
            prefixIcon: Icons.pets_rounded,
            suffixText: 'ekor',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Jumlah ayam wajib diisi';
              }
              final parsed = int.tryParse(
                val.replaceAll('.', '').replaceAll(',', '').trim(),
              );
              if (parsed == null || parsed <= 0) {
                return 'Jumlah ayam harus lebih dari 0';
              }
              if (parsed > widget.currentLiveChicks) {
                return 'Melebihi sisa ayam (${numFmt.format(widget.currentLiveChicks)} ekor)';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          AppTextFormField(
            controller: _weightController,
            labelText: 'Total Bobot Timbangan (kg)',
            hintText: 'Contoh: 3625.5',
            prefixIcon: Icons.scale_outlined,
            suffixText: 'kg',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}')),
            ],
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Total bobot wajib diisi';
              }
              final parsed = double.tryParse(val.replaceAll(',', '.').trim());
              if (parsed == null || parsed <= 0) {
                return 'Total bobot harus lebih dari 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Live Bobot Rata-rata Badge
          if (_calculatedAvgWeight != null && _calculatedAvgWeight! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Rata-rata Bobot Panen:',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    '${_calculatedAvgWeight!.toStringAsFixed(2)} kg / ekor',
                    style: tt.titleSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // ── 5. Integrasi Keuangan (Opsional) ────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _recordIncome,
                  onChanged: (val) => setState(() => _recordIncome = val),
                  title: Text(
                    'Catat Pemasukan ke Buku Kas',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Otomatis membuat transaksi pemasukan panen di periode ini',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                if (_recordIncome) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        AppTextFormField(
                          controller: _priceController,
                          labelText: 'Harga Jual per Kg (Rp)',
                          hintText: 'Contoh: 21000',
                          prefixIcon: Icons.monetization_on_outlined,
                          suffixText: 'Rp/kg',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (val) {
                            if (!_recordIncome) return null;
                            if (val == null || val.trim().isEmpty) {
                              return 'Harga per kg wajib diisi jika catat kas aktif';
                            }
                            final parsed = int.tryParse(
                              val
                                  .replaceAll('.', '')
                                  .replaceAll(',', '')
                                  .trim(),
                            );
                            if (parsed == null || parsed <= 0) {
                              return 'Harga harus lebih besar dari 0';
                            }
                            return null;
                          },
                        ),
                        if (_calculatedRevenue != null &&
                            _calculatedRevenue! > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer.withValues(
                                alpha: 0.4,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.rowRadius,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Penerimaan Kas:',
                                  style: tt.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  currencyFmt.format(_calculatedRevenue),
                                  style: tt.titleSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        AppTextFormField(
                          controller: _notesController,
                          labelText: 'Catatan / Nama Bakul (Opsional)',
                          hintText: 'Contoh: PT Sumber Pangan / Bakul Pak Joko',
                          prefixIcon: Icons.edit_note_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 6. Action Button ────────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
              child: const Text(
                'Simpan Panen Parsial',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
