import 'package:flutter/material.dart';
import 'package:recording_app/core/services/reminder_local_service.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/features/reminder/presentation/reminder.dart';

/// Icon lonceng reminder dengan badge jumlah reminder yang aktif.
/// Reusable — bisa dipasang di actions manapun.
/// Badge merah muncul otomatis jika ada reminder tersimpan.
class ReminderBadgeIcon extends StatelessWidget {
  const ReminderBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final service = ReminderLocalService();

    return StreamBuilder<List>(
      stream: service.watchReminders(),
      initialData: service.getAllReminders(),
      builder: (context, snapshot) {
        final count = (snapshot.data ?? []).length;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: 'Pengingat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Reminder()),
            ),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: cs.onSurface,
                  size: 24,
                ),
                if (count > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
