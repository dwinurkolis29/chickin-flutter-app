import 'package:flutter/material.dart';
import 'package:recording_app/features/reminder/presentation/reminder.dart';

class Setting extends StatelessWidget {
  const Setting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings & Support',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Settings Hub'),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Account',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.home_max_outlined,
            title: 'Kandang',
            onTap: () {},
          ),
          _buildMenuItem(
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
          _buildSectionHeader('Support & FAQs'),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.headset_mic_outlined,
            title: 'Contact Support',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? badge}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          icon,
          color: Colors.grey.shade700,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}