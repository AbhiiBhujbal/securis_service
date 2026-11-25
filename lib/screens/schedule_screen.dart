
import 'package:flutter/material.dart';

import '../models/repair_ticket.dart';
import '../widgets/section_heading.dart';
import '../widgets/ticket_card.dart';
import '../widgets/empty_state.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({
    super.key,
    required this.tickets,
    required this.onOpenTicket,
  });

  final List<RepairTicket> tickets;
  final ValueChanged<RepairTicket> onOpenTicket;

  static const Color navyColor = Color(0xFF172B4D);
  static const Color tealColor = Color(0xFF16B8A6);
  static const Color backgroundColor = Color(0xFFF4F7FB);
  static const Color textColor = Color(0xFF18233B);

  @override
  Widget build(BuildContext context) {
    final pending =
    tickets.where((ticket) => ticket.status != 'Resolved').toList();

    return Container(
      color: backgroundColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const SectionHeading(
            title: 'Service schedule',
            subtitle: 'Visits that need attention',
          ),

          const SizedBox(height: 20),

          // Pending visits summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  navyColor,
                  Color(0xFF263F69),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: navyColor.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending service visits',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${pending.length} ticket(s) need follow-up',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tealColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    '${pending.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // Section heading
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Upcoming attention',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                '${pending.length} items',
                style: const TextStyle(
                  color: tealColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Pending ticket list
          if (pending.isEmpty)
            const EmptyState(
              message: 'No pending service visits.',
            )
          else
            ...pending.map(
                  (ticket) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TicketCard(
                  ticket: ticket,
                  onTap: () => onOpenTicket(ticket),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Scheduling information
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: tealColor.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: tealColor,
                  size: 21,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Visit date and time scheduling will be connected later.',
                    style: TextStyle(
                      color: navyColor.withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
