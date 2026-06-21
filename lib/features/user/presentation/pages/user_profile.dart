import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/features/user/presentation/pages/form_user.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/features/user/presentation/controllers/user_controller.dart';
import 'package:image_picker/image_picker.dart';

class User extends StatefulWidget {
  const User({super.key});

  @override
  State<User> createState() => _UserState();
}

class _UserState extends State<User> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserController>().loadUserData();
    });
  }

  void _showImageSourceBottomSheet(
    BuildContext context,
    UserController controller,
  ) {
    DialogHelper.showBottomSheet(
      context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text('Galeri', style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  Navigator.pop(context);
                  controller.handleProfileImageUpload(ImageSource.gallery);
                },
              ),
              Divider(
                height: 0,
                thickness: 0.5,
                indent: 16,
                endIndent: 16,
                color: AppColors.secondary.withOpacity(0.3),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text('Kamera', style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  Navigator.pop(context);
                  controller.handleProfileImageUpload(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    final authService = context.read<AuthService>();
    final email = authService.currentUser?.email;
    if (email == null) return;
    try {
      await authService.sendPasswordResetEmail(email);
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          'Link reset password telah dikirim ke email Anda.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Gagal mengirim email reset: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authService = context.watch<AuthService>();
    final controller = context.watch<UserController>();
    final _isLoading = controller.isLoading;
    final _errorMessage = controller.errorMessage ?? '';
    final _userProfile = controller.userProfile;

    return Scaffold(
      // surface = AppColors.background (light) / M3 dark default (dark)
      backgroundColor: colorScheme.surface,
      appBar: const AppHeader(title: 'Profil Saya'),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
              : _errorMessage.isNotEmpty
              ? AppErrorState(
                  message: 'Gagal memuat profil',
                  subtitle: _errorMessage,
                  onRetry: () => controller.loadUserData(),
                )
              : SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── Profile Header ──
                      _Card(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FormUser(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 42,
                                  backgroundColor: colorScheme.primary
                                      .withOpacity(0.12),
                                  backgroundImage:
                                      _userProfile?.avatarUrl != null
                                          ? NetworkImage(
                                            _userProfile!.avatarUrl!,
                                          )
                                          : null,
                                  child:
                                      _userProfile?.avatarUrl == null
                                          ? Icon(
                                            Icons.person,
                                            size: 48,
                                            color: colorScheme.primary,
                                          )
                                          : null,
                                ),
                                if (controller.isUploadingAvatar)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black38,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap:
                                        controller.isUploadingAvatar
                                            ? null
                                            : () => _showImageSourceBottomSheet(
                                              context,
                                              controller,
                                            ),
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: colorScheme.primary,
                                      child: Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userProfile?.name ?? 'Tidak ada data',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Peternak',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Contact Info ──
                      _Card(
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              value: _userProfile?.phone ?? 'Tidak ada data',
                            ),
                            Divider(
                              height: 20,
                              color: colorScheme.outlineVariant,
                            ),
                            _InfoRow(
                              icon: Icons.mail_outline,
                              value:
                                  authService.currentUser?.email ?? 'Tidak ada data',
                            ),
                            Divider(
                              height: 20,
                              color: colorScheme.outlineVariant,
                            ),
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              value: _userProfile?.address ?? 'Tidak ada data',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Reset Password ──
                      _Card(
                        onTap: _resetPassword,
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.lock_reset_outlined,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Reset Password',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

// ── Shared card wrapper ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Card({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isInteractive = onTap != null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child:
          isInteractive
              ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: SizedBox(width: double.infinity, child: child),
                ),
              )
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: SizedBox(width: double.infinity, child: child),
              ),
    );
  }
}

// ── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
