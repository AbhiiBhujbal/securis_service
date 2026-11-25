
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

  static const Color navy = Color(0xFF172B4D);
  static const Color teal = Color(0xFF16B8A6);
  static const Color background = Color(0xFFF4F7FB);

  // Existing count logic - unchanged.
  int _count(String status) {
    return tickets.where((ticket) => ticket.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final open = _count('Open');
    final active = _count('Assigned') + _count('In Progress');
    final resolved = _count('Resolved');

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        // Dashboard welcome card
        _WelcomeCard(
          role: role,
        ),

        const SizedBox(height: 25),

        // Existing section heading
        const SectionHeading(
          title: 'Service overview',
          subtitle: 'Current ticket status',
        ),

        const SizedBox(height: 14),

        // Existing StatCard widgets and callbacks - unchanged.
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.48,
          children: [
            StatCard(
              title: 'Open tickets',
              count: open,
              icon: Icons.inbox_rounded,
              color: const Color(0xFFE69A35),
              onTap: onViewRequests,
            ),
            StatCard(
              title: 'In progress',
              count: active,
              icon: Icons.sync_rounded,
              color: const Color(0xFF4779D8),
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

        const SizedBox(height: 27),

        // Existing heading and View All callback - unchanged.
        SectionHeading(
          title: role == 'Admin' ? 'Recent requests' : 'Your assigned jobs',
          subtitle: 'Tap a ticket to view details',
          trailing: TextButton(
            onPressed: onViewRequests,
            style: TextButton.styleFrom(
              foregroundColor: teal,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            child: const Text('View all'),
          ),
        ),

        const SizedBox(height: 13),

        // Existing empty state and first 3 tickets - unchanged.
        if (tickets.isEmpty)
          const EmptyState(
            message: 'No repair tickets available.',
          )
        else
          ...tickets.take(3).map(
                (ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.role,
  });

  final String role;

  static const Color navy = Color(0xFF172B4D);
  static const Color teal = Color(0xFF16B8A6);

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'Admin';
    final now = DateTime.now();

    final date =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF172B4D),
            Color(0xFF254B70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -30,
            child: Container(
              height: 135,
              width: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
          ),
          Positioned(
            right: 22,
            bottom: -58,
            child: Container(
              height: 115,
              width: 115,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: teal.withValues(alpha: 0.09),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 7,
                          color: Color(0xFF55D8C6),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          isAdmin
                              ? 'SERVICE CONTROL CENTRE'
                              : 'TECHNICIAN WORKSPACE',
                          style: const TextStyle(
                            color: Color(0xFF8FE6DA),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.shield_outlined,
                    color: Colors.white54,
                    size: 23,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Text(
                isAdmin ? 'Good day, Admin' : 'Ready for your jobs?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                isAdmin
                    ? 'Manage service requests and keep every visit on track.'
                    : 'Review your assigned work and update repair progress.',
                style: const TextStyle(
                  color: Color(0xFFD4E0EC),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 23),

              Container(
                padding: const EdgeInsets.only(top: 13),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color(0x33FFFFFF),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFF8FE6DA),
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today: $date',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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
