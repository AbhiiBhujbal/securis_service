
import 'package:flutter/material.dart';

import '../../models/repair_ticket.dart';

class TechnicianManagementScreen extends StatelessWidget {
  const TechnicianManagementScreen({
    super.key,
    required this.tickets,
  });

  final List<RepairTicket> tickets;

  static const Color navy = Color(0xFF172B4D);
  static const Color teal = Color(0xFF16B8A6);
  static const Color background = Color(0xFFF4F7FB);

  @override
  Widget build(BuildContext context) {
    // Existing technician extraction logic - unchanged.
    final technicianNames = tickets
        .where(
          (ticket) =>
      ticket.assignedTo.trim().isNotEmpty &&
          ticket.assignedTo != 'Unassigned',
    )
        .map((ticket) => ticket.assignedTo)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Technician Management',
          style: TextStyle(
            color: navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
      ),
      body: technicianNames.isEmpty
          ? const _EmptyTechnicians()
          : ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        children: [
          const Text(
            'Your Technicians',
            style: TextStyle(
              color: navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Monitor technician assignments and work progress.',
            style: TextStyle(
              color: Colors.blueGrey.shade500,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Technician count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Container(
                  height: 43,
                  width: 43,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Technicians',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Assigned to service jobs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${technicianNames.length}',
                  style: const TextStyle(
                    color: Color(0xFF55D8C6),
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Technician List',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${technicianNames.length} Members',
                style: const TextStyle(
                  color: Color(0xFF16A99B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...technicianNames.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;

            // Existing technician job calculations - unchanged.
            final technicianJobs = tickets
                .where((ticket) => ticket.assignedTo == name)
                .toList();

            final activeJobs = technicianJobs
                .where(
                  (ticket) =>
              ticket.status == 'Assigned' ||
                  ticket.status == 'In Progress',
            )
                .length;

            final completedJobs = technicianJobs
                .where((ticket) => ticket.status == 'Resolved')
                .length;

            return _TechnicianCard(
              name: name,
              totalJobs: technicianJobs.length,
              activeJobs: activeJobs,
              completedJobs: completedJobs,
              index: index,
            );
          }),
        ],
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({
    required this.name,
    required this.totalJobs,
    required this.activeJobs,
    required this.completedJobs,
    required this.index,
  });

  final String name;
  final int totalJobs;
  final int activeJobs;
  final int completedJobs;
  final int index;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 70)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE8EDF4),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF172B4D).withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 49,
                  width: 49,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F7F4),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF119889),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF172B4D),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Row(
                        children: [
                          Icon(
                            Icons.engineering_outlined,
                            size: 14,
                            color: Color(0xFF16A99B),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Service Technician',
                            style: TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: activeJobs > 0
                        ? const Color(0xFFFFF3E2)
                        : const Color(0xFFE5F7F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activeJobs > 0 ? 'Active' : 'Available',
                    style: TextStyle(
                      color: activeJobs > 0
                          ? const Color(0xFFCE8523)
                          : const Color(0xFF119889),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 17),
            const Divider(
              height: 1,
              color: Color(0xFFEDF1F6),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _JobCount(
                    label: 'Total Assigned',
                    count: totalJobs,
                    color: const Color(0xFF4779D8),
                    icon: Icons.assignment_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _JobCount(
                    label: 'Active Jobs',
                    count: activeJobs,
                    color: const Color(0xFFE69A35),
                    icon: Icons.pending_actions_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _JobCount(
                    label: 'Completed',
                    count: completedJobs,
                    color: const Color(0xFF239B72),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCount extends StatelessWidget {
  const _JobCount({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 83),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTechnicians extends StatelessWidget {
  const _EmptyTechnicians();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 75,
              width: 75,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7F4),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.groups_outlined,
                color: Color(0xFF16A99B),
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Technicians Yet',
              style: TextStyle(
                color: Color(0xFF172B4D),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Technicians will appear here once they are assigned to service jobs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
