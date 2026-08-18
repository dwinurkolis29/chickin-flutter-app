import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/features/user/presentation/controllers/user_controller.dart';
import 'package:recording_app/features/user/presentation/pages/user_profile.dart';
import 'package:recording_app/features/period/presentation/list_period.dart';
import 'package:recording_app/features/reminder/presentation/reminder.dart';
import 'package:recording_app/features/cage/presentation/pages/cage_profile.dart';
import 'package:recording_app/features/recording/presentation/pages/detail_recording.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/theme/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserController>().loadUserData();
    });
  }

  // ── Avatar initials logic per spec ──────────────────────────────────────────
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

  // ── Logout dialog per spec ───────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    DialogHelper.showConfirm(
      context,
      'Keluar dari akun?',
      'Kamu akan keluar dari sesi ini.',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      isDestructive: true,
      onConfirm: () async {
        await context.read<AuthService>().signOut();
        // AuthWrapper reaktif — no manual nav needed.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = context.watch<UserController>();
    final firebaseUser = context.watch<AuthService>().currentUser;
    final themeController = context.watch<ThemeController>();

    final displayName = controller.userProfile?.name ?? firebaseUser?.displayName ?? '';
    final email = firebaseUser?.email ?? '';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── 4.1 Profile Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const User()),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: colorScheme.secondaryContainer,
                      backgroundImage: controller.userProfile?.avatarUrl != null
                          ? NetworkImage(controller.userProfile!.avatarUrl!)
                          : null,
                      child: controller.userProfile?.avatarUrl == null
                          ? Text(
                              _initials(displayName),
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.isNotEmpty ? displayName : 'Pengguna',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),

          // ── 4.2 Group 1 — AKUN ────────────────────────────────────────────
          _MenuGroup(
            label: 'Akun',
            items: [
              _MenuItem(
                icon: Icons.person_outline,
                label: 'Edit profil',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const User()),
                ),
              ),
              _MenuItem(
                icon: Icons.calendar_today_outlined,
                label: 'Periode',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PeriodListScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Reminder',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Reminder()),
                ),
              ),
            ],
          ),

          _MenuGroup(
            label: 'Tampilan', 
            items: [
              _MenuItem(
                icon: Icons.color_lens_outlined, 
                label: 'Tema', 
                trailingText: themeController.themeModeName,
                onTap: () {
                  DialogHelper.showStringPicker(
                    context,
                    title: 'Pilih Tema',
                    options: const ['Terang', 'Gelap', 'Mengikuti Sistem'],
                    selectedOption: themeController.themeModeName,
                    onSelected: (selected) {
                      themeController.setThemeMode(selected);
                    },
                  );
                },
              )
            ]
          ),

          // ── 4.2 Group 2 — KONFIGURASI ─────────────────────────────────────
          _MenuGroup(
            label: 'Konfigurasi',
            items: [
              _MenuItem(
                icon: Icons.warehouse_outlined,
                label: 'Detail kandang',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CageProfile()),
                ),
              ),
              _MenuItem(
                icon: Icons.assignment_outlined,
                label: 'Detail recording',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DetailRecording()),
                ),
              ),
            ],
          ),

          // ── 4.2 Group 3 — BANTUAN ─────────────────────────────────────────
          _MenuGroup(
            label: 'Bantuan',
            items: [
              _MenuItem(
                icon: Icons.headset_mic_outlined,
                label: 'Hubungi support',
                onTap: () {
                  AppSnackbar.showInfo(
                    context,
                    'Fitur ini masih dalam tahap pengembangan',
                  );
                },
              ),
            ],
          ),

          // ── 4.3 Logout button ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                minVerticalPadding: 0,
                leading: Icon(
                  Icons.logout_rounded,
                  size: 22,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Keluar',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable group widget ─────────────────────────────────────────────────────

class _MenuGroup extends StatelessWidget {
  final String label;
  final List<_MenuItem> items;

  const _MenuGroup({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  items[i].buildTile(context),
                  if (i < items.length - 1)
                    Divider(
                      color: colorScheme.outlineVariant,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingText;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
  });

  Widget buildTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      minVerticalPadding: 0,
      leading: Icon(icon, size: 22, color: colorScheme.primary),
      title: Text(
        label,
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}
