import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/user/presentation/controllers/user_controller.dart';
import 'package:recording_app/features/user/presentation/pages/form_user.dart';

/// Halaman Profil Saya (Peternak) yang berfokus pada identitas pribadi,
/// kontak yang mudah dibaca, dan keamanan akun.
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
      if (mounted) {
        context.read<UserController>().loadUserData();
      }
    });
  }

  Future<void> _showImageSourceBottomSheet(
    BuildContext context,
    UserController controller,
  ) async {
    final source = await DialogHelper.showImageSourcePicker(
      context,
      title: 'Pilih Foto Profil',
      subtitle: 'Pilih gambar dari galeri atau ambil foto baru dengan kamera:',
    );
    if (source != null) {
      controller.handleProfileImageUpload(source);
    }
  }


  String _initials(String? displayName) {
    final name = (displayName ?? '').trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final chars = name.characters;
    if (chars.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final authService = context.watch<AuthService>();
    final controller = context.watch<UserController>();
    final isLoading = controller.isLoading;
    final errorMessage = controller.errorMessage ?? '';
    final userProfile = controller.userProfile;
    final userEmail = authService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppHeader(title: 'Profil Saya'),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: cs.primary),
            )
          : errorMessage.isNotEmpty
              ? AppErrorState(
                  message: 'Gagal memuat profil peternak',
                  subtitle: errorMessage,
                  onRetry: () => controller.loadUserData(),
                )
              : SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── 1. Hero Avatar & Identity Card ────────────────
                            AppCard(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 24,
                                ),
                                child: Column(
                                  children: [
                                    // Avatar besar dengan tombol ganti foto
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: cs.secondaryContainer,
                                          ),
                                          child: CircleAvatar(
                                            radius: 46,
                                            backgroundColor: cs.surface,
                                            backgroundImage: userProfile?.avatarUrl != null
                                                ? NetworkImage(userProfile!.avatarUrl!)
                                                : null,
                                            child: userProfile?.avatarUrl == null
                                                ? Text(
                                                    _initials(userProfile?.name ?? authService.currentUser?.displayName),
                                                    style: tt.headlineMedium?.copyWith(
                                                      color: cs.primary,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                        if (controller.isUploadingAvatar)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black45,
                                              ),
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Material(
                                          color: cs.primary,
                                          shape: const CircleBorder(),
                                          elevation: 2,
                                          child: InkWell(
                                            customBorder: const CircleBorder(),
                                            onTap: controller.isUploadingAvatar
                                                ? null
                                                : () => _showImageSourceBottomSheet(
                                                      context,
                                                      controller,
                                                    ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.camera_alt_rounded,
                                                size: 18,
                                                color: cs.onPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Nama Peternak
                                    Text(
                                      userProfile?.name.isNotEmpty == true
                                          ? userProfile!.name
                                          : (authService.currentUser?.displayName ?? 'Peternak Broiler'),
                                      style: tt.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: cs.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),

                                    // Badge Status Akun
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.pillRadius,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 14,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Peternak Terdaftar Aktif',
                                            style: tt.labelMedium?.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── 2. Informasi Kontak Peternak ──────────────────
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 18,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Informasi Kontak & Domisili',
                                    style: tt.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _ContactTile(
                                      icon: Icons.phone_outlined,
                                      label: 'Nomor Kontak / WhatsApp',
                                      value: userProfile?.phone.isNotEmpty == true
                                          ? userProfile!.phone
                                          : 'Belum diisi',
                                    ),
                                    const Divider(height: 20),
                                    _ContactTile(
                                      icon: Icons.mail_outline_rounded,
                                      label: 'Email Akun',
                                      value: userEmail.isNotEmpty ? userEmail : 'Belum diisi',
                                    ),
                                    const Divider(height: 20),
                                    _ContactTile(
                                      icon: Icons.location_on_outlined,
                                      label: 'Alamat Domisili',
                                      value: userProfile?.address.isNotEmpty == true
                                          ? userProfile!.address
                                          : 'Belum diisi',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── 4. Tombol Utama (Ubah Data Profil) ────────────
                            FilledButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FormUser(),
                                  ),
                                );
                                if (result == true && mounted) {
                                  context.read<UserController>().loadUserData();
                                }
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.pillRadius,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(
                                'Ubah Data Profil',
                                style: tt.labelLarge?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: cs.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
