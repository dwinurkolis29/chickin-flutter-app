import 'package:flutter/material.dart';
import 'package:recording_app/features/reminder/presentation/reminder.dart';
import 'package:recording_app/features/cage/presentation/pages/cage_profile_page.dart';
import 'package:recording_app/features/user/presentation/user.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/period/presentation/list_period.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

class Setting extends StatelessWidget {
  const Setting({Key? key}) : super(key: key);

  void _showLogoutDialog(BuildContext context) {
    DialogHelper.showConfirm(
      context,
      'Logout',
      'Apakah kamu yakin ingin logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        try {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        } catch (e) {
          debugPrint('Logout error: $e');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tidak pakai Scaffold — widget ini di-embed sebagai body di Home,
    // yang sudah menyediakan Scaffold + AppBar-nya sendiri.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(context, 'Settings Hub'),
        const SizedBox(height: 8),
        _buildMenuItem(
          context,
          icon: Icons.person_outline,
          title: 'Account',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const User()),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.calendar_month,
          title: 'Periode',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PeriodListScreen()),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.home_max_outlined,
          title: 'Kandang',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CageProfilePage()),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.alarm,
          title: 'Reminder Recording',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Reminder()),
            );
          },
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Support & FAQs'),
        const SizedBox(height: 8),
        _buildMenuItem(
          context,
          icon: Icons.headset_mic_outlined,
          title: 'Contact Support',
          onTap: () {},
        ),
        _buildMenuItem(
          context,
          icon: Icons.logout,
          title: 'Logout',
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String? badge}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          title,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        Widget? trailing,
      }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          icon,
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
        title: Text(
          title,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        trailing: trailing ??
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}