import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import '../../data/models/period_data.dart';
import '../controllers/period_controller.dart';

class FormPeriod extends StatefulWidget {
  final PeriodData? period;

  const FormPeriod({Key? key, this.period}) : super(key: key);

  @override
  State<FormPeriod> createState() => _FormPeriodState();
}

class _FormPeriodState extends State<FormPeriod> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TextEditingController _weightController;

  bool _isLoading = false;

  /// Reflects active state for the activate switch (draft/closed periods)
  late bool _isActiveSwitchValue;

  /// Reflects open/close state for the close switch (active periods)
  late bool _closePeriodSwitch;

  bool get _isEditing => widget.period != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.period?.name ?? '');
    _capacityController = TextEditingController(
      text: widget.period?.initialCapacity.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.period?.initialWeight.toString() ?? '0.4',
    );
    _isActiveSwitchValue = widget.period?.isActive ?? false;
    // Close switch ON = period is open/active
    _closePeriodSwitch = widget.period?.isActive ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = context.read<PeriodController>();

      final periodData = PeriodData(
        id: widget.period?.id ?? '',
        name: _nameController.text.trim(),
        initialCapacity: int.tryParse(_capacityController.text.trim()) ?? 0,
        initialWeight: double.tryParse(_weightController.text.trim()) ?? 0.4,
        startDate: widget.period?.startDate ?? DateTime.now(),
        createdAt: widget.period?.createdAt ?? DateTime.now(),
        isActive: widget.period?.isActive ?? false,
        isDeleted: widget.period?.isDeleted ?? false,
      );

      if (_isEditing) {
        await controller.updatePeriodDetails(widget.period!.id, periodData);
        if (mounted) {
          AppSnackbar.showSuccess(context, 'Periode berhasil diperbarui');
          Navigator.pop(context, true);
        }
      } else {
        await controller.createPeriod(periodData);
        if (mounted) {
          AppSnackbar.showSuccess(context, 'Periode berhasil dibuat');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePeriod() async {
    if (widget.period == null) return;

    DialogHelper.showConfirm(
      context,
      'Hapus Periode',
      'Apakah Anda yakin ingin menghapus periode ini? Periode yang sudah memiliki record tidak dapat dihapus.',
      isDestructive: true,
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          await context.read<PeriodController>().deletePeriod(widget.period!.id);
          if (mounted) {
            AppSnackbar.showSuccess(context, 'Periode berhasil dihapus');
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (mounted) {
            AppSnackbar.showError(context, e.toString());
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  /// Activate or reactivate a period (works for both draft and previously closed)
  Future<void> _activatePeriod() async {
    if (widget.period == null) return;

    final bool isReopening = widget.period!.endDate != null;

    DialogHelper.showConfirm(
      context,
      'Aktifkan Periode',
      isReopening
          ? 'Periode ini sebelumnya sudah ditutup. Apakah Anda yakin ingin mengaktifkannya kembali? Hanya satu periode yang bisa aktif dalam satu waktu.'
          : 'Apakah Anda yakin ingin mengaktifkan periode ini? Hanya satu periode yang bisa aktif dalam satu waktu.',
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          await context.read<PeriodController>().activatePeriod(widget.period!.id);
          if (mounted) {
            AppSnackbar.showSuccess(context, 'Periode berhasil diaktifkan');
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (mounted) {
            AppSnackbar.showError(context, e.toString());
            setState(() => _isActiveSwitchValue = false);
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _closePeriod() async {
    if (widget.period == null) return;

    DialogHelper.showConfirm(
      context,
      'Tutup Periode',
      'Apakah Anda yakin ingin menutup periode ini? Periode yang sudah ditutup tidak bisa diaktifkan kembali.',
      isDestructive: true,
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          final summary = PeriodSummary(
            totalFeedKg: 0,
            finalPopulation: 0,
            totalMortality: 0,
            finalBiomass: 0,
            finalFCR: 0,
            avgDailyGain: 0,
          );
          await context.read<PeriodController>().closePeriod(widget.period!.id, summary);
          if (mounted) {
            AppSnackbar.showSuccess(context, 'Periode berhasil ditutup');
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (mounted) {
            AppSnackbar.showError(context, e.toString());
            setState(() => _closePeriodSwitch = true); // revert on failure
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show activate switch for non-active periods (both draft and closed)
    final bool showActivateSwitch = _isEditing && !(widget.period?.isActive ?? false);
    // Show close switch only when currently active
    final bool showCloseSwitch = _isEditing && (widget.period?.isActive ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Periode' : 'Buat Periode Baru'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isLoading ? null : _deletePeriod,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Periode',
                hintText: 'Misal: Batch 1 2024',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Nama wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Kapasitas Awal (Ekor)',
                hintText: 'Misal: 5000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Kapasitas wajib diisi';
                if (int.tryParse(val.trim()) == null) return 'Harus angka';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Bobot Awal (Kg)',
                hintText: 'Misal: 0.4',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Bobot wajib diisi';
                if (double.tryParse(val.trim()) == null) return 'Harus angka';
                return null;
              },
            ),

            // --- Activate Switch (draft or closed periods) ---
            if (showActivateSwitch) ...[
              const SizedBox(height: 16),
              _StatusSwitch(
                label: 'Aktifkan Periode',
                subtitle: widget.period?.endDate != null
                    ? 'Periode ini sebelumnya sudah ditutup'
                    : 'Aktifkan untuk mulai mencatat data periode ini',
                value: _isActiveSwitchValue,
                isActive: _isActiveSwitchValue,
                disabled: _isLoading,
                onChanged: (val) {
                  setState(() => _isActiveSwitchValue = val);
                  if (val) _activatePeriod();
                },
              ),
            ],

            // --- Close Switch (active periods only) ---
            if (showCloseSwitch) ...[
              const SizedBox(height: 16),
              _StatusSwitch(
                label: 'Status Periode',
                subtitle: _closePeriodSwitch
                    ? 'Periode sedang aktif'
                    : 'Periode ditutup',
                value: _closePeriodSwitch,
                isActive: _closePeriodSwitch,
                disabled: _isLoading,
                onChanged: (val) {
                  setState(() => _closePeriodSwitch = val);
                  if (!val) _closePeriod();
                },
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(_isEditing ? 'Simpan Perubahan' : 'Buat Periode'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable status switch dengan visual aktif/nonaktif yang jelas
class _StatusSwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final bool isActive;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  const _StatusSwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.isActive,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primary.withOpacity(0.07)
            : Colors.grey.shade100,
        border: Border.all(
          color: isActive ? colorScheme.primary : Colors.grey.shade400,
          width: isActive ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SwitchListTile(
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? colorScheme.primary : Colors.grey.shade600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isActive
                ? colorScheme.primary.withOpacity(0.75)
                : Colors.grey.shade500,
          ),
        ),
        value: value,
        activeColor: colorScheme.primary,
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade300,
        onChanged: disabled ? null : onChanged,
      ),
    );
  }
}