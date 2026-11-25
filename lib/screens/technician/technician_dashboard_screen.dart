
import 'package:flutter/material.dart';

import '../../models/repair_ticket.dart';

class TechnicianDashboardScreen extends StatelessWidget {
  const TechnicianDashboardScreen({
    super.key,
    required this.tickets,
    required this.onOpenTicket,
  });

  final List<RepairTicket> tickets;
  final ValueChanged<RepairTicket> onOpenTicket;

  static const Color navy = Color(0xFF172B4D);
  static const Color teal = Color(0xFF16B8A6);
  static const Color background = Color(0xFFF4F7FB);

  @override
  Widget build(BuildContext context) {
    // Existing ticket count logic - unchanged.
    final inProgress = tickets
        .where((ticket) => ticket.status == 'In Progress')
        .length;

    final assigned = tickets
        .where((ticket) => ticket.status == 'Assigned')
        .length;

    final completed = tickets
        .where((ticket) => ticket.status == 'Resolved')
        .length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Technician Dashboard',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        children: [
          const Text(
            'My Work',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: navy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'View your assigned service jobs and progress.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blueGrey.shade500,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Work summary
          Row(
            children: [
              _WorkStat(
                title: 'Assigned',
                count: assigned,
                color: const Color(0xFF4779D8),
                icon: Icons.assignment_outlined,
              ),
              const SizedBox(width: 10),
              _WorkStat(
                title: 'In Progress',
                count: inProgress,
                color: const Color(0xFFE69A35),
                icon: Icons.engineering_outlined,
              ),
              const SizedBox(width: 10),
              _WorkStat(
                title: 'Completed',
                count: completed,
                color: const Color(0xFF239B72),
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Jobs heading
          Row(
            children: [
              const Expanded(
                child: Text(
                  'My Assigned Jobs',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F7F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${tickets.length} Jobs',
                  style: const TextStyle(
                    color: Color(0xFF119889),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (tickets.isEmpty)
            const _EmptyJobs()
          else
            ...tickets.asMap().entries.map(
                  (entry) {
                final index = entry.key;
                final ticket = entry.value;

                return _JobCard(
                  ticket: ticket,
                  index: index,
                  onTap: () => onOpenTicket(ticket),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WorkStat extends StatelessWidget {
  const _WorkStat({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 125),
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: const Color(0xFFE9EEF5),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 21,
            ),
            const SizedBox(height: 9),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: count),
              duration: const Duration(milliseconds: 650),
              builder: (context, value, child) {
                return Text(
                  '$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.ticket,
    required this.index,
    required this.onTap,
  });

  final RepairTicket ticket;
  final int index;
  final VoidCallback onTap;

  Color get statusColor {
    switch (ticket.status) {
      case 'Assigned':
        return const Color(0xFF4779D8);
      case 'In Progress':
        return const Color(0xFFE69A35);
      case 'Resolved':
        return const Color(0xFF239B72);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        margin: const EdgeInsets.only(bottom: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F7F5),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.build_rounded,
                          color: Color(0xFF16A99B),
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF172B4D),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ticket.customer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      _StatusBadge(
                        status: ticket.status,
                        color: statusColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEDF1F6),
                  ),
                  const SizedBox(height: 13),

                  const Text(
                    'ISSUE DESCRIPTION',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ticket.issue,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 13),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.blueGrey.shade400,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          ticket.property,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.color,
  });

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 105),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EDF4),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 30,
              color: Color(0xFF16A99B),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'No Jobs Assigned',
            style: TextStyle(
              color: Color(0xFF172B4D),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Your assigned service jobs will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF718096),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
