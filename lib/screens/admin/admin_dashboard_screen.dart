import 'package:flutter/material.dart';

import '../../models/repair_ticket.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.tickets,
    required this.onOpenTicket,
    required this.onViewRequests,
    required this.onViewTechnicians,
    required this.onViewSchedule,
    this.dashboardData,
  });
  final List<RepairTicket> tickets;
  final ValueChanged<RepairTicket> onOpenTicket;
  final VoidCallback onViewRequests;
  final VoidCallback onViewTechnicians;
  final VoidCallback onViewSchedule;
  final Map<String, dynamic>? dashboardData;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2457C5);
    final counts =
        dashboardData?['ticket_counts'] as Map<String, dynamic>? ?? {};
    final totalRequests =
        dashboardData?['total_tickets'] ?? tickets.length;
    final resolvedCount =
        counts['Resolved'] ?? 0;
    final activeJobsCount =
        (counts['Assigned'] ?? 0) +
            (counts['Scheduled'] ?? 0) +
            (counts['In Progress'] ?? 0);

    final technicianCount =
        dashboardData?['active_technicians'] ?? 0;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF18233B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(
              Icons.home_repair_service_rounded,
              color: primaryColor,
            ),
            SizedBox(width: 10),
            Text(
              'Securis Admin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications will be connected later.'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18233B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage all service operations in one place.',
            style: TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AdminStatCard(
                title: 'Total Requests',
                value: '$totalRequests',
                icon: Icons.confirmation_number_outlined,
                color: const Color(0xFF2457C5),
              ),
              _AdminStatCard(
                title: 'Resolved',
                value: '$resolvedCount',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF239B72),
              ),
              _AdminStatCard(
                title: 'Active Jobs',
                value: '$activeJobsCount',
                icon: Icons.sync_rounded,
                color: const Color(0xFFE79A26),
              ),
              _AdminStatCard(
                title: 'Technicians',
                value: '$technicianCount',
                icon: Icons.groups_rounded,
                color: const Color(0xFF8064D8),
              ),
            ],
          ),

          const SizedBox(height: 26),

          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF18233B),
            ),
          ),
          const SizedBox(height: 12),

          _AdminActionTile(
            icon: Icons.groups_rounded,
            title: 'Technician Management',
            subtitle: 'View technicians and their workload',
            onTap: onViewTechnicians,
          ),

          _AdminActionTile(
            icon: Icons.calendar_month_rounded,
            title: 'Schedule & Assignments',
            subtitle: 'Manage visits and assigned jobs',
            onTap: onViewSchedule,
          ),


          const SizedBox(height: 26),

          const Text(
            'Recent Requests',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF18233B),
            ),
          ),
          const SizedBox(height: 12),

          if (tickets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No service requests available.'),
              ),
            )
          else
            ...tickets.take(3).map(
                  (ticket) => Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EEFF),
                    child: Icon(
                      Icons.build_circle_outlined,
                      color: Color(0xFF2457C5),
                    ),
                  ),
                  title: Text(
                    ticket.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${ticket.customer}\n'
                        '${ticket.issue}\n'
                        'Assigned to: ${ticket.assignedTo}',
                  ),
                  isThreeLine: true,
                  trailing: _StatusBadge(status: ticket.status),
                  onTap: () => onOpenTicket(ticket),
                ),
              ),
            ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: onViewRequests,
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text('View All Requests'),
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 44) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18233B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8EEFF),
          child: Icon(
            icon,
            color: const Color(0xFF2457C5),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;

    switch (status) {
      case 'Resolved':
        statusColor = const Color(0xFF239B72);
        break;
      case 'In Progress':
        statusColor = const Color(0xFFE79A26);
        break;
      case 'Assigned':
        statusColor = const Color(0xFF2457C5);
        break;
      default:
        statusColor = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
} 