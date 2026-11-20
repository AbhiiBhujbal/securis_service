
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.role,
    required this.onSwitchRole,
    required this.onLogout,
  });

  final String role;
  final VoidCallback onSwitchRole;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18233B),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFFE6EDFF),
                  child: Icon(
                    isAdmin
                        ? Icons.admin_panel_settings_rounded
                        : Icons.engineering_rounded,
                    size: 42,
                    color: const Color(0xFF2457C5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAdmin ? 'Administrator' : 'Technician',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF18233B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin ? 'Admin Panel' : 'Technician Panel',
                  style: const TextStyle(color: Colors.blueGrey),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EDFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAdmin ? 'ADMIN' : 'TECHNICIAN',
                    style: const TextStyle(
                      color: Color(0xFF2457C5),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _profileOption(
                  icon: Icons.person_outline_rounded,
                  title: 'Account Type',
                  subtitle: role,
                ),
                const Divider(height: 28),
                _profileOption(
                  icon: Icons.security_outlined,
                  title: 'Access Level',
                  subtitle: isAdmin
                      ? 'Manage requests and technicians'
                      : 'View and update assigned jobs',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileOption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2457C5)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
