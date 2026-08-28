import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Halaman Kelola Akun untuk pengaturan kredensial login, verifikasi email,
/// pemulihan kata sandi, dan penghapusan akun.
class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  bool _isSendingReset = false;
  bool _isSendingVerification = false;

  Future<void> _handleSendPasswordReset(String email) async {
    setState(() => _isSendingReset = true);
    try {
      await context.read<AuthService>().sendPasswordResetEmail(email);
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          'Tautan reset kata sandi telah dikirim ke $email.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'Gagal mengirim email reset kata sandi: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingReset = false);
      }
    }
  }

  Future<void> _handleSendEmailVerification() async {
    setState(() => _isSendingVerification = true);
    try {
      await context.read<AuthService>().sendEmailVerification();
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          'Tautan verifikasi email telah dikirim. Silakan periksa kotak masuk/spam email Anda.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'Gagal mengirim email verifikasi: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingVerification = false);
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    DialogHelper.showBottomSheet(
      context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.cardRadius),
        ),
      ),
      builder: StatefulBuilder(
        builder: (dialogContext, setModalState) {
          final cs = Theme.of(dialogContext).colorScheme;
          final tt = Theme.of(dialogContext).textTheme;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_reset_rounded,
                            color: cs.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Ubah Kata Sandi Langsung',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      labelText: 'Kata Sandi Saat Ini',
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Kata sandi saat ini wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AppTextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      labelText: 'Kata Sandi Baru (Min. 6 Karakter)',
                      prefixIcon: Icons.key_rounded,
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Kata sandi baru minimal 6 karakter.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AppTextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      labelText: 'Ulangi Kata Sandi Baru',
                      prefixIcon: Icons.check_rounded,
                      validator: (v) {
                        if (v != newPasswordController.text) {
                          return 'Konfirmasi kata sandi tidak cocok.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSaving = true);
                              final res = await context
                                  .read<AuthService>()
                                  .changePassword(
                                    currentPassword:
                                        currentPasswordController.text.trim(),
                                    newPassword:
                                        newPasswordController.text.trim(),
                                  );
                              setModalState(() => isSaving = false);
                              if (context.mounted) {
                                Navigator.pop(dialogContext);
                                if (res.success) {
                                  AppSnackbar.showSuccess(
                                    context,
                                    'Kata sandi berhasil diperbarui.',
                                  );
                                } else {
                                  AppSnackbar.showError(
                                    context,
                                    res.errorMessage ??
                                        'Gagal mengubah kata sandi.',
                                  );
                                }
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        isSaving ? 'Menyimpan...' : 'Simpan Kata Sandi Baru',
                        style: tt.labelLarge?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();

    DialogHelper.showConfirm(
      context,
      'Hapus Akun Peternak?',
      'Seluruh data siklus pemeliharaan, kandang, dan catatan harian yang terkait dengan akun ini akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.',
      confirmText: 'Ya, Hapus Akun',
      isDestructive: true,
      onConfirm: () {
        // Form password confirmation dialog
        _showPasswordConfirmationForDeletion(context, passwordController);
      },
    );
  }

  void _showPasswordConfirmationForDeletion(
    BuildContext context,
    TextEditingController passwordController,
  ) {
    final formKey = GlobalKey<FormState>();
    bool isDeleting = false;

    DialogHelper.showBottomSheet(
      context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.cardRadius),
        ),
      ),
      builder: StatefulBuilder(
        builder: (dialogContext, setModalState) {
          final cs = Theme.of(dialogContext).colorScheme;
          final tt = Theme.of(dialogContext).textTheme;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_forever_rounded,
                            color: AppColors.error,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Konfirmasi Kata Sandi',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan kata sandi akun Anda untuk mengonfirmasi penghapusan permanen.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextFormField(
                      controller: passwordController,
                      obscureText: true,
                      labelText: 'Kata Sandi Akun',
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Kata sandi wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                      ),
                      onPressed: isDeleting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isDeleting = true);
                              final res = await context
                                  .read<AuthService>()
                                  .deleteAccount(
                                    password: passwordController.text.trim(),
                                  );
                              setModalState(() => isDeleting = false);
                              if (context.mounted) {
                                Navigator.pop(dialogContext);
                                if (!res.success) {
                                  AppSnackbar.showError(
                                    context,
                                    res.errorMessage ??
                                        'Gagal menghapus akun.',
                                  );
                                }
                              }
                            },
                      icon: isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.delete_forever_rounded),
                      label: Text(
                        isDeleting ? 'Menghapus Akun...' : 'Hapus Akun Permanen',
                        style: tt.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = context.watch<AuthService>().currentUser;
    final email = user?.email ?? 'Tidak ada data email';
    final isVerified = user?.emailVerified ?? false;
    final uid = user?.uid ?? '-';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppHeader(title: 'Kelola Akun'),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. Hero Guidance Card ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
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
                            Icons.security_rounded,
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
                                'Keamanan & Akses Akun',
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kelola kredensial login, verifikasi email, pemulihan kata sandi, dan status akun peternak Anda.',
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

                  // ── 2. Section Informasi Akun ──────────────────────
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'INFORMASI LOGIN & AKUN',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.mail_outline_rounded,
                                  color: cs.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email Akun Terdaftar',
                                      style: tt.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: tt.bodyMedium?.copyWith(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isVerified
                                      ? AppColors.success.withValues(alpha: 0.12)
                                      : AppColors.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.pillRadius,
                                  ),
                                ),
                                child: Text(
                                  isVerified
                                      ? 'Terverifikasi'
                                      : 'Belum Verifikasi',
                                  style: tt.labelSmall?.copyWith(
                                    color: isVerified
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isVerified) ...[
                            const Divider(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isSendingVerification
                                    ? null
                                    : _handleSendEmailVerification,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.pillRadius,
                                    ),
                                  ),
                                ),
                                icon: _isSendingVerification
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.mark_email_read_outlined,
                                        size: 16,
                                      ),
                                label: Text(
                                  _isSendingVerification
                                      ? 'Mengirim Tautan...'
                                      : 'Kirim Tautan Verifikasi Email',
                                  style: tt.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const Divider(height: 20),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fingerprint_rounded,
                                  color: cs.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID Pengguna (UID)',
                                      style: tt.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      uid,
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurface,
                                        fontFamily: 'monospace',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 3. Section Keamanan Kata Sandi ────────────────
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'KEAMANAN KATA SANDI',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  AppCard(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.email_outlined,
                              color: cs.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Kirim Link Reset Password ke Email',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'Kirim email resmi Firebase untuk atur ulang kata sandi',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          trailing: _isSendingReset
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.chevron_right_rounded,
                                  color: cs.onSurfaceVariant,
                                ),
                          onTap: _isSendingReset
                              ? null
                              : () => _handleSendPasswordReset(email),
                        ),
                        Divider(
                          height: 0,
                          thickness: 0.5,
                          indent: 16,
                          endIndent: 16,
                          color: cs.outlineVariant,
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.password_rounded,
                              color: cs.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Ubah Kata Sandi Langsung',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'Ganti password baru dengan memasukkan kata sandi lama',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: cs.onSurfaceVariant,
                          ),
                          onTap: () => _showChangePasswordDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── 4. Section Zona Bahaya (Hapus Akun) ────────────
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'PENGATURAN KRITIS AKUN',
                      style: tt.labelSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Hapus Akun Peternak Permanen',
                              style: tt.titleSmall?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Menghapus akun Anda secara permanen beserta data kandang dan catatan harian. Sesuai kebijakan keamanan data Google Play.',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.pillRadius,
                              ),
                            ),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: () => _showDeleteAccountDialog(context),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'Hapus Akun Saya',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
