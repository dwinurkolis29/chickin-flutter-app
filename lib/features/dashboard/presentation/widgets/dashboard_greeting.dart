import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/user/presentation/controllers/user_controller.dart';

class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({super.key});

  String _greetingText(int hour) {
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  IconData _greetingIcon(int hour) {
    if (hour >= 4 && hour < 11) return Icons.wb_sunny_rounded;
    if (hour >= 11 && hour < 15) return Icons.wb_sunny_outlined;
    if (hour >= 15 && hour < 18) return Icons.wb_twilight_rounded;
    return Icons.nights_stay_rounded;
  }

  Color _greetingIconColor(int hour) {
    if (hour >= 4 && hour < 15) return const Color(0xFFE65100);
    if (hour >= 15 && hour < 18) return const Color(0xFFF57C00);
    return const Color(0xFF5C6BC0);
  }

  static const List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String _formatIndonesianDate(DateTime date) {
    final day = _days[date.weekday - 1];
    final month = _months[date.month - 1];
    return '$day, ${date.day} $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserController>().userProfile;
    final firebaseUser = context.watch<AuthService>().currentUser;
    final homeController = context.watch<HomeController>();
    final activePeriodName = homeController.activePeriodName;

    final name = profile?.name.trim().isNotEmpty == true
        ? profile!.name.trim()
        : firebaseUser?.displayName?.trim().isNotEmpty == true
            ? firebaseUser!.displayName!.trim()
            : 'Peternak';

    final avatarUrl = profile?.avatarUrl ?? firebaseUser?.photoURL;

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final dateStr = _formatIndonesianDate(now);
    final greeting = _greetingText(now.hour);
    final greetingIcon = _greetingIcon(now.hour);
    final iconColor = _greetingIconColor(now.hour);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Bar: Tanggal Hari Ini & Badge Periode Aktif ───────────────
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (activePeriodName != null && activePeriodName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
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
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          activePeriodName,
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Baris Utama: Avatar & Salam Hangat ─────────────────────────────
          Row(
            children: [
              // Avatar Profil dengan Lingkaran Secondary
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primary,
                  backgroundImage:
                      avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'P',
                          style: tt.titleMedium?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Teks Salam & Nama Peternak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          greetingIcon,
                          size: 15,
                          color: iconColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          greeting,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                        fontSize: 20,
                        height: 1.2,
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
    );
  }
}
