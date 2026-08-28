import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';

/// Screen Registrasi Akun Peternak baru berdesain bersih, terstruktur, dan mudah digunakan.
class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode _focusNodeUsername = FocusNode();
  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePhone = FocusNode();
  final FocusNode _focusNodeAddress = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();
  final FocusNode _focusNodeConfirmPassword = FocusNode();

  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPhone = TextEditingController();
  final TextEditingController _controllerAddress = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerConfirmPassword = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // ─── Proses Registrasi Akun ────────────────────────────────────────────────
  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final profile = UserProfile(
        name: _controllerUsername.text.trim(),
        phone: _controllerPhone.text.trim(),
        address: _controllerAddress.text.trim(),
      );

      final result = await context.read<AuthService>().signUp(
            email: _controllerEmail.text.trim(),
            password: _controllerPassword.text,
            profile: profile,
          );

      if (!mounted) return;

      if (result.success) {
        AppSnackbar.showSuccess(context, 'Akun peternak berhasil didaftarkan.');
        _formKey.currentState?.reset();
        if (Navigator.canPop(context)) {
          Navigator.pop(context, {'email': _controllerEmail.text.trim()});
        }
      } else {
        DialogHelper.showError(
          context,
          'Pendaftaran Gagal',
          result.errorMessage ?? 'Gagal membuat akun. Silakan periksa kembali data Anda.',
        );
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(context, 'Terjadi Kesalahan', 'Gagal memproses pendaftaran: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bool busy = _isLoading;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: busy ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Daftar Akun Peternak',
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Logo Kecil & Headline ──
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/logos/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.flutter_dash,
                        size: 32,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Mulai Bersama Chickin',
                    style: tt.headlineSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Isi formulir di bawah untuk membuat akun peternak baru',
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Form Card ──
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_add_outlined, color: cs.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'DATA DIRI & KANDANG',
                                style: tt.labelMedium?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 1. Nama Lengkap
                          AppTextFormField(
                            controller: _controllerUsername,
                            focusNode: _focusNodeUsername,
                            labelText: 'Nama Lengkap Peternak',
                            hintText: 'Contoh: Budi Santoso',
                            prefixIcon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                            enabled: !busy,
                            onEditingComplete: () => _focusNodeEmail.requestFocus(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama lengkap wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // 2. Email
                          AppTextFormField(
                            controller: _controllerEmail,
                            focusNode: _focusNodeEmail,
                            labelText: 'Alamat Email',
                            hintText: 'nama@peternak.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !busy,
                            onEditingComplete: () => _focusNodePhone.requestFocus(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email wajib diisi';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Format email tidak valid (contoh: budi@gmail.com)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // 3. Nomor WhatsApp / Telepon
                          AppTextFormField(
                            controller: _controllerPhone,
                            focusNode: _focusNodePhone,
                            labelText: 'Nomor WhatsApp / HP (Opsional)',
                            hintText: 'Contoh: 081234567890',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            enabled: !busy,
                            onEditingComplete: () => _focusNodeAddress.requestFocus(),
                          ),
                          const SizedBox(height: 14),

                          // 4. Alamat Kandang
                          AppTextFormField(
                            controller: _controllerAddress,
                            focusNode: _focusNodeAddress,
                            labelText: 'Alamat / Lokasi Kandang (Opsional)',
                            hintText: 'Contoh: Desa Sukamaju, Subang',
                            prefixIcon: Icons.location_on_outlined,
                            keyboardType: TextInputType.streetAddress,
                            enabled: !busy,
                            onEditingComplete: () => _focusNodePassword.requestFocus(),
                          ),
                          const SizedBox(height: 14),

                          // 5. Kata Sandi
                          AppTextFormField(
                            controller: _controllerPassword,
                            focusNode: _focusNodePassword,
                            labelText: 'Kata Sandi',
                            hintText: 'Minimal 8 karakter',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            enabled: !busy,
                            onEditingComplete: () => _focusNodeConfirmPassword.requestFocus(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kata sandi wajib diisi';
                              }
                              if (value.length < 8) {
                                return 'Kata sandi minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // 6. Konfirmasi Kata Sandi
                          AppTextFormField(
                            controller: _controllerConfirmPassword,
                            focusNode: _focusNodeConfirmPassword,
                            labelText: 'Konfirmasi Kata Sandi',
                            hintText: 'Ulangi kata sandi Anda',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirmPassword,
                            enabled: !busy,
                            onEditingComplete: _handleSignup,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi kata sandi wajib diisi';
                              }
                              if (value != _controllerPassword.text) {
                                return 'Konfirmasi kata sandi tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Tombol Daftar Sekarang
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                ),
                                elevation: 0,
                              ),
                              onPressed: busy ? null : _handleSignup,
                              child: _isLoading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                                      ),
                                    )
                                  : Text(
                                      'Daftar Sekarang',
                                      style: tt.titleSmall?.copyWith(
                                        color: cs.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Navigasi Sudah Punya Akun ──
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun peternak? ',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: busy ? null : () => Navigator.pop(context),
                        child: Text(
                          'Masuk di Sini',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNodeUsername.dispose();
    _focusNodeEmail.dispose();
    _focusNodePhone.dispose();
    _focusNodeAddress.dispose();
    _focusNodePassword.dispose();
    _focusNodeConfirmPassword.dispose();

    _controllerUsername.dispose();
    _controllerEmail.dispose();
    _controllerPhone.dispose();
    _controllerAddress.dispose();
    _controllerPassword.dispose();
    _controllerConfirmPassword.dispose();

    super.dispose();
  }
}
