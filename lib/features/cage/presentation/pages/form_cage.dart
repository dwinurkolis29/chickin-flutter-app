import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';

/// Form Pengisian & Pengeditan Data Kandang yang konsisten dengan desain Form Recording.
class FormCage extends StatefulWidget {
  final CageData? cageData;

  const FormCage({super.key, this.cageData});

  @override
  State<FormCage> createState() => _FormCageState();
}

class _FormCageState extends State<FormCage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  bool _isLoading = false;

  final FocusNode _focusNodeName = FocusNode();
  final FocusNode _focusNodeType = FocusNode();
  final FocusNode _focusNodeCapacity = FocusNode();
  final FocusNode _focusNodeLocation = FocusNode();

  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerType = TextEditingController();
  final TextEditingController _controllerCapacity = TextEditingController();
  final TextEditingController _controllerLocation = TextEditingController();

  bool get isEditing =>
      widget.cageData != null &&
      (widget.cageData!.capacity > 0 || widget.cageData!.type.isNotEmpty);

  @override
  void initState() {
    super.initState();
    if (widget.cageData != null) {
      _controllerName.text = widget.cageData!.name;
      _controllerType.text = widget.cageData!.type;
      _controllerCapacity.text = widget.cageData!.capacity > 0
          ? widget.cageData!.capacity.toString()
          : '';
      _controllerLocation.text = widget.cageData!.location;
    } else {
      _controllerName.text = 'Kandang Utama';
    }
  }

  @override
  void dispose() {
    _focusNodeName.dispose();
    _focusNodeType.dispose();
    _focusNodeCapacity.dispose();
    _focusNodeLocation.dispose();
    _controllerName.dispose();
    _controllerType.dispose();
    _controllerCapacity.dispose();
    _controllerLocation.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cage = CageData(
        name: _controllerName.text.trim().isNotEmpty
            ? _controllerName.text.trim()
            : 'Kandang Utama',
        type: _controllerType.text.trim(),
        capacity: int.tryParse(_controllerCapacity.text.trim()) ?? 0,
        location: _controllerLocation.text.trim(),
      );

      await context.read<CageController>().saveCageData(cage);

      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          isEditing
              ? 'Data spesifikasi kandang berhasil diperbarui'
              : 'Data kandang baru berhasil disimpan',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Gagal menyimpan data kandang: $e');
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppHeader(
        title: isEditing ? 'Edit Spesifikasi Kandang' : 'Tambah Data Kandang',
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. Hero Guidance Card ────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius,
                        ),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warehouse_rounded,
                              size: 24,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Spesifikasi Fisik Kandang',
                                  style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tentukan tipe konstruksi ventilasi dan daya tampung maksimal bibit DOC untuk akurasi monitoring kepadatan ayam.',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 2. Section Spesifikasi & Kapasitas ────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'SPESIFIKASI & KAPASITAS',
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    AppTextFormField(
                      controller: _controllerName,
                      focusNode: _focusNodeName,
                      labelText: 'Nama Kandang / Peternakan',
                      hintText: 'Contoh: Kandang Sumber Rejeki',
                      prefixIcon: Icons.business_outlined,
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama kandang wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AppTextFormField(
                      controller: _controllerType,
                      focusNode: _focusNodeType,
                      readOnly: true,
                      labelText: 'Model / Tipe Konstruksi Kandang',
                      hintText: 'Pilih tipe konstruksi',
                      prefixIcon: Icons.roofing_rounded,
                      suffixIcon: const Icon(Icons.expand_more_rounded),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Tipe konstruksi kandang wajib dipilih.';
                        }
                        return null;
                      },
                      onTap: () {
                        DialogHelper.showStringPicker(
                          context,
                          title: 'Pilih Tipe Konstruksi Kandang',
                          options: const [
                            'Closed House (Kandang Tertutup Modern)',
                            'Open House (Kandang Terbuka Standar)',
                            'Semi Closed House',
                          ],
                          selectedOption: _controllerType.text.isNotEmpty
                              ? _controllerType.text
                              : null,
                          onSelected: (selected) {
                            setState(() {
                              _controllerType.text = selected;
                            });
                            _focusNodeCapacity.requestFocus();
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    AppTextFormField(
                      controller: _controllerCapacity,
                      focusNode: _focusNodeCapacity,
                      keyboardType: TextInputType.number,
                      labelText: 'Kapasitas Maksimal (Ekor DOC)',
                      hintText: 'Contoh: 10000',
                      prefixIcon: Icons.groups_rounded,
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Kapasitas kandang wajib diisi.';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Masukkan angka kapasitas yang valid (misal: 10000).';
                        }
                        return null;
                      },
                      onEditingComplete: () => _focusNodeLocation.requestFocus(),
                    ),
                    const SizedBox(height: 20),

                    // ── 3. Section Lokasi Kandang ────────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'LOKASI KANDANG',
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    AppTextFormField(
                      controller: _controllerLocation,
                      focusNode: _focusNodeLocation,
                      maxLines: 3,
                      labelText: 'Alamat & Lokasi Kandang',
                      hintText: 'Contoh: Dusun Krajan RT 02/05, Desa Sukamaju, Kec. Ciawi',
                      prefixIcon: Icons.location_on_outlined,
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Alamat lokasi kandang wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── 4. Tombol Simpan ─────────────────────────────
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submitData,
                      child: _isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  cs.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              isEditing
                                  ? 'Simpan Perubahan'
                                  : 'Tambah Kandang Baru',
                              style: tt.labelLarge?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(height: 40),
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
