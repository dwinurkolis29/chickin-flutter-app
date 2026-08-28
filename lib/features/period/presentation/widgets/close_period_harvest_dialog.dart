import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/components/dialogs/base_dialog.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

/// Data hasil input panen dari peternak saat penutupan periode.
class ClosePeriodHarvestResult {
  final int? harvestedChicks;
  final double? harvestedWeightKg;

  const ClosePeriodHarvestResult({
    this.harvestedChicks,
    this.harvestedWeightKg,
  });
}

/// Dialog interaktif penutupan periode panen untuk menanyakan data ayam dipanen dan total bobot.
class ClosePeriodHarvestDialog extends StatefulWidget {
  final PeriodData period;

  const ClosePeriodHarvestDialog({
    super.key,
    required this.period,
  });

  /// Helper untuk memunculkan dialog tutup panen
  static Future<ClosePeriodHarvestResult?> show({
    required BuildContext context,
    required PeriodData period,
  }) {
    return showDialog<ClosePeriodHarvestResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ClosePeriodHarvestDialog(period: period),
    );
  }

  @override
  State<ClosePeriodHarvestDialog> createState() => _ClosePeriodHarvestDialogState();
}

class _ClosePeriodHarvestDialogState extends State<ClosePeriodHarvestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _chicksController = TextEditingController();
  final _weightController = TextEditingController();

  double? _calculatedAvgWeight;

  @override
  void initState() {
    super.initState();
    _chicksController.addListener(_recalculateAvg);
    _weightController.addListener(_recalculateAvg);
  }

  @override
  void dispose() {
    _chicksController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _recalculateAvg() {
    final chicks = int.tryParse(_chicksController.text.replaceAll('.', '').replaceAll(',', '').trim());
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.').trim());

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
  }

  void _submit() {
    final chicksText = _chicksController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final weightText = _weightController.text.replaceAll(',', '.').trim();

    final int? chicks = chicksText.isNotEmpty ? int.tryParse(chicksText) : null;
    final double? weight = weightText.isNotEmpty ? double.tryParse(weightText) : null;

    Navigator.of(context).pop(
      ClosePeriodHarvestResult(
        harvestedChicks: chicks,
        harvestedWeightKg: weight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final numFmt = NumberFormat.decimalPattern('id_ID');

    return BaseDialog(
      title: 'Tutup Periode Panen',
      icon: Icons.inventory_2_outlined,
      iconColor: cs.primary,
      iconBackgroundColor: cs.secondaryContainer,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah periode "${widget.period.name}" sudah selesai dipanen? Masukkan data hasil panen akhir jika tersedia:',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Field 1: Ayam Dipanen
              Text(
                'Ayam Dipanen (Ekor)',
                style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _chicksController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Contoh: ${numFmt.format(widget.period.initialCapacity > 0 ? (widget.period.initialCapacity * 0.97).round() : 9700)}',
                  suffixText: 'Ekor',
                  filled: true,
                  fillColor: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Field 2: Total Bobot Panen
              Text(
                'Total Bobot Panen (Kg)',
                style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Contoh: 17460',
                  suffixText: 'Kg',
                  filled: true,
                  fillColor: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                ),
              ),

              // Live Preview Rata-rata Bobot
              if (_calculatedAvgWeight != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.scale_rounded, size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rata-rata Bobot Panen: ${_calculatedAvgWeight!.toStringAsFixed(2)} kg/ekor (${(_calculatedAvgWeight! * 1000).toStringAsFixed(0)} g)',
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),
              // Info Note
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Opsional: Jika belum ada timbang panen, kosongkan form dan laporan akan memakai estimasi recording.',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: cs.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Tutup & Simpan Panen'),
        ),
      ],
    );
  }
}
