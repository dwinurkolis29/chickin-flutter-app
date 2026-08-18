import 'package:flutter/material.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';

class FormCage extends StatefulWidget {
  final CageData? cageData;

  const FormCage({super.key, this.cageData});

  @override
  State<FormCage> createState() => _FormCageState();
}

class _FormCageState extends State<FormCage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  bool _isLoading = false;

  final FocusNode _focusNodeType = FocusNode();
  final FocusNode _focusNodeCapacity = FocusNode();
  final FocusNode _focusNodeLocation = FocusNode();

  final TextEditingController _controllerType = TextEditingController();
  final TextEditingController _controllerCapacity = TextEditingController();
  final TextEditingController _controllerLocation = TextEditingController();

  bool get isEditing => widget.cageData != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _controllerType.text = widget.cageData!.type;
      _controllerCapacity.text = widget.cageData!.capacity.toString();
      _controllerLocation.text = widget.cageData!.location;
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cage = CageData(
        type: _controllerType.text.trim(),
        capacity: int.tryParse(_controllerCapacity.text) ?? 0,
        location: _controllerLocation.text.trim(),
      );

      await context.read<CageController>().saveCageData(cage);

      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          isEditing
              ? 'Data kandang berhasil diperbarui'
              : 'Data kandang berhasil disimpan',
        );
        // Return true to indicate a refresh might be needed by the caller
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Gagal menyimpan data');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppHeader(
        title: isEditing ? 'Edit Kandang' : 'Tambah Kandang',
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                AppTextFormField(
                  controller: _controllerType,
                  focusNode: _focusNodeType,
                  readOnly: true,
                  labelText: "Jenis Kandang",
                  prefixIcon: Icons.bloodtype,
                  suffixIcon: const Icon(Icons.expand_more),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Jenis kandang tidak boleh kosong.";
                    }
                    return null;
                  },
                  onTap: () {
                    DialogHelper.showStringPicker(
                      context,
                      title: 'Pilih Jenis Kandang',
                      options: const ['Close House', 'Open House'],
                      selectedOption: _controllerType.text.isNotEmpty ? _controllerType.text : null,
                      onSelected: (selected) {
                        setState(() {
                          _controllerType.text = selected;
                        });
                        // Otomatis pindah fokus ke kapasitas setelah memilih
                        _focusNodeCapacity.requestFocus();
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                AppTextFormField(
                  controller: _controllerCapacity,
                  focusNode: _focusNodeCapacity,
                  keyboardType: TextInputType.number,
                  labelText: "Kapasitas Kandang",
                  prefixIcon: Icons.reduce_capacity,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Kapasitas kandang tidak boleh kosong.";
                    }
                    if (int.tryParse(value) == null) {
                      return "Kapasitas harus berupa angka.";
                    }
                    return null;
                  },
                  onEditingComplete: () => _focusNodeLocation.requestFocus(),
                ),
                const SizedBox(height: 10),
                AppTextFormField(
                  controller: _controllerLocation,
                  focusNode: _focusNodeLocation,
                  maxLines: 3,
                  labelText: "Lokasi Kandang",
                  prefixIcon: Icons.location_on_outlined,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Lokasi kandang tidak boleh kosong.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitData,
                  child:
                      _isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                          : Text(
                            isEditing ? "Simpan Perubahan" : "Tambah Kandang",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNodeType.dispose();
    _focusNodeCapacity.dispose();
    _focusNodeLocation.dispose();
    _controllerType.dispose();
    _controllerCapacity.dispose();
    _controllerLocation.dispose();
    super.dispose();
  }
}
