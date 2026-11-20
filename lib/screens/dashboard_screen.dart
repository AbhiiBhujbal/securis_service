import 'package:flutter/material.dart';
import '../models/repair_ticket.dart';
import '../widgets/section_heading.dart';
import '../widgets/stat_card.dart';
import '../widgets/ticket_card.dart';
import '../widgets/empty_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.tickets,
    required this.role,
    required this.onOpenTicket,
    required this.onViewRequests,
  });

  final List<RepairTicket> tickets;
  final String role;
  final ValueChanged<RepairTicket> onOpenTicket;
  final VoidCallback onViewRequests;

  int _count(String status) {
    return tickets.where((ticket) => ticket.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final open = _count('Open');
    final active = _count('Assigned') + _count('In Progress');
    final resolved = _count('Resolved');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF193A91), Color(0xFF3478ED)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role == 'Admin'
                    ? 'SERVICE CONTROL CENTRE'
                    : 'TECHNICIAN WORKSPACE',
                style: const TextStyle(
                  color: Color(0xFFD9E5FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                role == 'Admin'
                    ? 'Good day, Admin '
                    : 'Ready for your jobs? ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                role == 'Admin'
                    ? 'Manage service requests and keep every visit on track.'
                    : 'Review your assigned work and update repair progress.',
                style: const TextStyle(
                  color: Color(0xFFE1E9FF),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Today: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeading(
          title: 'Service overview',
          subtitle: 'Current ticket status',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          children: [
            StatCard(
              title: 'Open tickets',
              count: open,
              icon: Icons.inbox_rounded,
              color: const Color(0xFFE79A26),
              onTap: onViewRequests,
            ),
            StatCard(
              title: 'In progress',
              count: active,
              icon: Icons.sync_rounded,
              color: const Color(0xFF2457D6),
              onTap: onViewRequests,
            ),
            StatCard(
              title: 'Resolved',
              count: resolved,
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF239B72),
              onTap: onViewRequests,
            ),
            StatCard(
              title: 'Total tickets',
              count: tickets.length,
              icon: Icons.confirmation_number_rounded,
              color: const Color(0xFF8064D8),
              onTap: onViewRequests,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeading(
          title: role == 'Admin' ? 'Recent requests' : 'Your assigned jobs',
          subtitle: 'Tap a ticket to view details',
          trailing: TextButton(
            onPressed: onViewRequests,
            child: const Text('View all'),
          ),
        ),
        const SizedBox(height: 10),
        if (tickets.isEmpty)
          const EmptyState(message: 'No repair tickets available.')
        else
          ...tickets.take(3).map(
                (ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TicketCard(
                ticket: ticket,
                onTap: () => onOpenTicket(ticket),
              ),
            ),
          ),
      ],
    );
  }
}