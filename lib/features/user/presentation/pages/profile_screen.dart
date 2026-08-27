import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/cage/presentation/pages/cage_profile.dart';
import 'package:recording_app/features/period/presentation/list_period.dart';
import 'package:recording_app/features/recording/presentation/pages/chicken_weight_screen.dart';
import 'package:recording_app/features/recording/presentation/pages/detail_recording.dart';
import 'package:recording_app/features/reminder/presentation/reminder.dart';
import 'package:recording_app/features/reporting/presentation/pages/fcr_monitoring_screen.dart';
import 'package:recording_app/features/user/presentation/controllers/user_controller.dart';
import 'package:recording_app/features/user/presentation/pages/broiler_encyclopedia_screen.dart';
import 'package:recording_app/features/user/presentation/pages/user_profile.dart';

/// Halaman Profil Pengguna & Pusat Pengaturan Manajemen Peternakan.
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

  void _showLogoutDialog(BuildContext context) {
    DialogHelper.showConfirm(
      context,
      'Keluar dari Akun?',
      'Anda akan keluar dari sesi ini dan perlu login kembali untuk mengakses data peternakan.',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      isDestructive: true,
      onConfirm: () async {
        await context.read<AuthService>().signOut();
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        backgroundColor: cs.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Icon(Icons.egg_outlined, color: cs.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Chickin BroilerKu',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi Manajemen Peternakan Ayam Broiler untuk pencatatan harian, perhitungan FCR otomatis, reminder pakan, dan analisis performa.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_outlined, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Versi 1.0.0 • Production Ready',
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final controller = context.watch<UserController>();
    final firebaseUser = context.watch<AuthService>().currentUser;

    final displayName =
        controller.userProfile?.name ?? firebaseUser?.displayName ?? '';
    final email = firebaseUser?.email ?? '';

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // ── 1. Hero Profile Card ─────────────────────────────────────────
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Avatar dengan outer ring secondary
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.secondaryContainer,
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: cs.surface,
                          backgroundImage: controller.userProfile?.avatarUrl != null
                              ? NetworkImage(controller.userProfile!.avatarUrl!)
                              : null,
                          child: controller.userProfile?.avatarUrl == null
                              ? Text(
                                  _initials(displayName),
                                  style: tt.titleLarge?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName.isNotEmpty
                                  ? displayName
                                  : 'Peternak Broiler',
                              style: tt.titleMedium?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (email.isNotEmpty) ...[
                              Text(
                                email,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Status Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
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
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Akun Peternak Aktif',
                                    style: tt.labelSmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── 2. Group Akun & Profil ──────────────────────────────────────
              _MenuGroup(
                label: 'PENGATURAN AKUN',
                items: [
                  _MenuItemData(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profil',
                    subtitle: 'Ubah nama, foto profil & informasi akun',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const User()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 3. Group Manajemen Peternakan ───────────────────────────────
              _MenuGroup(
                label: 'MANAJEMEN PETERNAKAN',
                items: [
                  _MenuItemData(
                    icon: Icons.show_chart_rounded,
                    title: 'Pertumbuhan Bobot Ayam',
                    subtitle: 'Grafik lengkap penimbangan harian & kurva ADG',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChickenWeightScreen(),
                      ),
                    ),
                  ),
                  _MenuItemData(
                    icon: Icons.calendar_month_outlined,
                    title: 'Periode Pemeliharaan',
                    subtitle: 'Kelola siklus ternak & riwayat panen',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PeriodListScreen(),
                      ),
                    ),
                  ),
                  _MenuItemData(
                    icon: Icons.warehouse_outlined,
                    title: 'Data Kandang',
                    subtitle: 'Kapasitas, tipe & spesifikasi kandang',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CageProfile()),
                    ),
                  ),
                  _MenuItemData(
                    icon: Icons.assignment_outlined,
                    title: 'Semua Recording',
                    subtitle: 'Daftar catatan harian pakan, bobot & kematian',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DetailRecording(),
                      ),
                    ),
                  ),
                  _MenuItemData(
                    icon: Icons.speed_rounded,
                    title: 'Monitoring FCR',
                    subtitle: 'Pantau efisiensi pakan harian & mingguan',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FCRMonitoringScreen(),
                      ),
                    ),
                  ),
                  _MenuItemData(
                    icon: Icons.alarm_outlined,
                    title: 'Pengingat & Alarm',
                    subtitle: 'Jadwal brooding, pakan & perlakuan harian',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Reminder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 4. Group Kamus & Panduan Ternak ─────────────────────────────
              _MenuGroup(
                label: 'KAMUS & PANDUAN TERNAK',
                items: [
                  _MenuItemData(
                    icon: Icons.menu_book_rounded,
                    title: 'Ensiklopedia Broiler',
                    subtitle: 'Kamus istilah, arti angka FCR, IP & rumus praktis ternak',
                    trailingBadge: 'Panduan',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BroilerEncyclopediaScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 5. Group Informasi Sistem ────────────────────────────────────
              _MenuGroup(
                label: 'INFORMASI SISTEM',
                items: [
                  _MenuItemData(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang Aplikasi',
                    subtitle: 'Chickin BroilerKu v1.0.0',
                    trailingBadge: 'v1.0.0',
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 5. Tombol Logout ─────────────────────────────────────────────
              AppCard(
                child: InkWell(
                  onTap: () => _showLogoutDialog(context),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: cs.error,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Keluar dari Akun',
                                style: tt.titleSmall?.copyWith(
                                  color: cs.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Akhiri sesi aktif pada perangkat ini',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: cs.error.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu Group & Item Components
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingBadge;

  const _MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingBadge,
  });
}

class _MenuGroup extends StatelessWidget {
  final String label;
  final List<_MenuItemData> items;

  const _MenuGroup({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        AppCard(
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _buildTile(context, items[i]),
                if (i < items.length - 1)
                  Divider(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, _MenuItemData item) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 20, color: cs.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (item.trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  item.trailingBadge!,
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
