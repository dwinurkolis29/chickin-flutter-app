import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(isEditing ? 'Edit Kandang' : 'Tambah Kandang'),
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
                FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Text(
                    isEditing ? "Edit Data Kandang" : "Tambah Data Kandang",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isEditing
                      ? "Memperbarui data kandang ayam broiler."
                      : "Menambahkan data kandang ayam broiler.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 35),
                DropdownButtonFormField<String>(
                  value:
                      _controllerType.text.isNotEmpty
                          ? (_controllerType.text.toLowerCase() == 'close house'
                              ? 'Close House'
                              : (_controllerType.text.toLowerCase() ==
                                      'open house'
                                  ? 'Open House'
                                  : null))
                          : null,
                  focusNode: _focusNodeType,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  dropdownColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  decoration: InputDecoration(
                    labelText: "Jenis Kandang",
                    labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.bloodtype,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: "Close House",
                      child: Text(
                        "Close House",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: "Open House",
                      child: Text(
                        "Open House",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _controllerType.text = newValue;
                      });
                    }
                  },
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Jenis kandang tidak boleh kosong.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _controllerCapacity,
                  focusNode: _focusNodeCapacity,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Kapasitas Kandang",
                    prefixIcon: const Icon(Icons.reduce_capacity),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
                TextFormField(
                  controller: _controllerLocation,
                  focusNode: _focusNodeLocation,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Lokasi Kandang",
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitData,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            isEditing ? "Simpan Perubahan" : "Tambah Kandang",
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
