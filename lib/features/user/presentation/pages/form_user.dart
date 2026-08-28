import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';

/// Form Pengisian & Pengeditan Profil Peternak yang ramah bagi peternak senior.
class FormUser extends StatefulWidget {
  final UserProfile? userProfile;
  final FirebaseService? firebaseService;

  const FormUser({super.key, this.userProfile, this.firebaseService});

  @override
  State<FormUser> createState() => _FormUserState();
}

class _FormUserState extends State<FormUser> {
  FirebaseService? _firebaseService;
  FirebaseService get _service =>
      _firebaseService ??= widget.firebaseService ?? FirebaseService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.userProfile != null) {
      _nameController.text = widget.userProfile!.name;
      _phoneController.text = widget.userProfile!.phone;
      _addressController.text = widget.userProfile!.address;
      _isLoading = false;
    } else {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        final userProfile = await _service.getUserProfile();
        if (mounted) {
          setState(() {
            _nameController.text = userProfile.name;
            _phoneController.text = userProfile.phone;
            _addressController.text = userProfile.address;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Pengguna tidak terautentikasi';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = UserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      await _service.updateUserProfile(updatedProfile);

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Data profil berhasil diperbarui');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Gagal memperbarui profil: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final userEmail = context.watch<AuthService>().currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppHeader(title: 'Edit Profil Peternak'),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : _errorMessage.isNotEmpty
                ? AppErrorState(
                    message: 'Gagal memuat data pengguna',
                    subtitle: _errorMessage,
                    onRetry: () => _loadUserData(),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── 1. Guide Card Ramah Lansia ─────────────────
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.cardRadius,
                                  ),
                                  border: Border.all(
                                    color: cs.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: cs.primary.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person_pin_circle_rounded,
                                        size: 24,
                                        color: cs.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Informasi Akun Peternak',
                                            style: tt.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pastikan nama lengkap, nomor telepon, dan domisili Anda diisi dengan benar untuk kemudahan kontak peternakan.',
                                            style: tt.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── 2. Form Input Fields ───────────────────────
                              // Field Nama Lengkap
                              AppTextFormField(
                                controller: _nameController,
                                labelText: 'Nama Lengkap Peternak',
                                hintText: 'Contoh: H. Ahmad Supriyadi',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nama lengkap wajib diisi.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Field Email (Read Only)
                              AppTextFormField(
                                readOnly: true,
                                initialValue: userEmail.isNotEmpty
                                    ? userEmail
                                    : 'Tidak ada email',
                                labelText: 'Email Akun Terdaftar',
                                prefixIcon: Icons.mail_outline_rounded,
                              ),
                              const SizedBox(height: 16),

                              // Field Nomor Telepon
                              AppTextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                labelText: 'Nomor HP / WhatsApp Aktif',
                                hintText: 'Contoh: 081234567890',
                                prefixIcon: Icons.phone_outlined,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nomor telepon wajib diisi.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Field Alamat Domisili
                              AppTextFormField(
                                controller: _addressController,
                                maxLines: 3,
                                labelText: 'Alamat Domisili Peternak',
                                hintText:
                                    'Contoh: Dusun Krajan RT 01/02, Desa Sukamaju, Kec. Ciawi',
                                prefixIcon: Icons.location_on_outlined,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Alamat domisili wajib diisi.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),

                              // ── 3. Tombol Simpan ───────────────────────────
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.pillRadius,
                                    ),
                                  ),
                                ),
                                onPressed: _isSaving ? null : _handleUpdate,
                                icon: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_outline_rounded),
                                label: Text(
                                  _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                                  style: tt.labelLarge?.copyWith(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
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
