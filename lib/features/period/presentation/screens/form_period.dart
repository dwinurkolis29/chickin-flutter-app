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

  bool get _isEditing => widget.period != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.period?.name ?? '');
    _capacityController = TextEditingController(
      text: widget.period?.initialCapacity.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.period?.initialWeight.toString() ?? '0.4', // Default to 0.4kg
    );
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
        isActive: widget.period?.isActive ?? false, // Defaults to draft
        isDeleted: widget.period?.isDeleted ?? false,
      );

      if (_isEditing) {
        // Here you would implement update functionality in the controller if needed
        // For now, if the requirement is only create/delete, we can add update later.
        // Assuming PeriodController has an update method or we can just show a message:
        AppSnackbar.showInfo(context, 'Fitur update belum tersedia di controller.');
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
            Navigator.pop(context, true); // Pop back after delete
          }
        } catch (e) {
          if (mounted) {
            AppSnackbar.showError(context, e.toString());
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEditing ? 'Simpan Perubahan' : 'Buat Periode'),
            )
          ],
        ),
      ),
    );
  }
}
