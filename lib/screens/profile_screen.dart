
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

  static const Color navyColor = Color(0xFF172B4D);
  static const Color tealColor = Color(0xFF16B8A6);
  static const Color backgroundColor = Color(0xFFF4F7FB);
  static const Color textColor = Color(0xFF18233B);

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'Admin';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          // Page heading
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your account information',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey.shade500,
            ),
          ),

          const SizedBox(height: 24),

          // Profile header card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  navyColor,
                  Color(0xFF263F69),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: navyColor.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isAdmin
                        ? Icons.admin_panel_settings_rounded
                        : Icons.engineering_rounded,
                    size: 43,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 17),

                Text(
                  isAdmin ? 'Administrator' : 'Technician',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  isAdmin ? 'Admin Panel' : 'Technician Panel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: tealColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        isAdmin ? 'ADMIN' : 'TECHNICIAN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Account information heading
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),

          const SizedBox(height: 14),

          // Account information card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blueGrey.shade50,
              ),
            ),
            child: Column(
              children: [
                _profileOption(
                  icon: Icons.person_outline_rounded,
                  title: 'Account Type',
                  subtitle: role,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Divider(
                    height: 1,
                    color: Colors.blueGrey.shade100,
                  ),
                ),

                _profileOption(
                  icon: Icons.security_rounded,
                  title: 'Access Level',
                  subtitle: isAdmin
                      ? 'Manage requests and technicians'
                      : 'View and update assigned jobs',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Logout button
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(
                Icons.logout_rounded,
                size: 20,
              ),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.red.shade100,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'SECURIS  •  SERVICE & REPAIR',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.blueGrey.shade300,
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
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: tealColor,
            size: 23,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
