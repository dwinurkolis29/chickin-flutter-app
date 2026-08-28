import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/components/dialogs/app_form_bottom_sheet.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
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

/// Bottom Sheet interaktif penutupan periode panen untuk menanyakan data ayam dipanen dan total bobot.
class ClosePeriodHarvestDialog extends StatefulWidget {
  final PeriodData period;

  const ClosePeriodHarvestDialog({
    super.key,
    required this.period,
  });

  /// Helper untuk memunculkan bottom sheet tutup panen
  static Future<ClosePeriodHarvestResult?> show({
    required BuildContext context,
    required PeriodData period,
  }) {
    return AppFormBottomSheet.show<ClosePeriodHarvestResult>(
      context: context,
      title: 'Tutup Periode Panen',
      subtitle:
          'Apakah periode "${period.name}" sudah selesai dipanen? Masukkan data hasil panen akhir jika tersedia:',
      icon: Icons.inventory_2_outlined,
      builder: (sheetContext, setModalState) {
        return ClosePeriodHarvestDialog(period: period);
      },
    );
  }

  @override
  State<ClosePeriodHarvestDialog> createState() =>
      _ClosePeriodHarvestDialogState();
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
  }

  void _submit() {
    final chicksText =
        _chicksController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final weightText = _weightController.text.replaceAll(',', '.').trim();

    final int? chicks =
        chicksText.isNotEmpty ? int.tryParse(chicksText) : null;
    final double? weight =
        weightText.isNotEmpty ? double.tryParse(weightText) : null;

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

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Field 1: Ayam Dipanen
          AppTextFormField(
            controller: _chicksController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            labelText: 'Ayam Dipanen (Ekor)',
            hintText:
                'Contoh: ${numFmt.format(widget.period.initialCapacity > 0 ? (widget.period.initialCapacity * 0.97).round() : 9700)}',
            prefixIcon: Icons.groups_rounded,
          ),
          const SizedBox(height: 14),

          // Field 2: Total Bobot Panen
          AppTextFormField(
            controller: _weightController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            labelText: 'Total Bobot Panen (Kg)',
            hintText: 'Contoh: 17460',
            prefixIcon: Icons.scale_rounded,
          ),

          // Live Preview Rata-rata Bobot
          if (_calculatedAvgWeight != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.scale_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rata-rata Bobot Panen: ${_calculatedAvgWeight!.toStringAsFixed(2)} kg/ekor (${(_calculatedAvgWeight! * 1000).toStringAsFixed(0)} g)',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Opsional: Jika belum ada timbang panen, kosongkan form dan laporan akan memakai estimasi recording.',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Aksi Simpan
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
            ),
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text(
              'Tutup & Simpan Panen',
              style: tt.labelLarge?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
              minimumSize: const Size.fromHeight(40),
            ),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}
