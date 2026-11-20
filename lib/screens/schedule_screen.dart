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

  @override
  Widget build(BuildContext context) {
    final pending =
    tickets.where((ticket) => ticket.status != 'Resolved').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeading(
          title: 'Service schedule',
          subtitle: 'Visits that need attention',
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF2457D6),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending service visits',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pending.length} ticket(s) need follow-up',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (pending.isEmpty)
          const EmptyState(message: 'No pending service visits.')
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
        const SizedBox(height: 8),
        const Text(
          'Visit date and time scheduling will be connected later.',
          style: TextStyle(color: Colors.blueGrey, fontSize: 12),
        ),
      ],
    );
  }
}