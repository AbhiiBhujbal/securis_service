
import 'package:flutter/material.dart';

import '../../models/repair_ticket.dart';

class WorkHistoryScreen extends StatelessWidget {
  const WorkHistoryScreen({
    super.key,
    required this.tickets,
    required this.onOpenTicket,
  });

  final List<RepairTicket> tickets;
  final ValueChanged<RepairTicket> onOpenTicket;

  static const Color primaryColor = Color(0xFF2457C5);

  @override
  Widget build(BuildContext context) {
    final resolvedTickets = tickets
        .where((ticket) => ticket.status == 'Resolved')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          const Text(
            'Work History',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18233B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Review your completed service requests.',
            style: TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F7EC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    size: 30,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${resolvedTickets.length}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF18233B),
                        ),
                      ),
                      const Text(
                        'Completed Jobs',
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Completed Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18233B),
            ),
          ),
          const SizedBox(height: 12),
          if (resolvedTickets.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 44,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No completed jobs yet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Resolved jobs will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
            )
          else
            ...resolvedTickets.map((ticket) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onOpenTicket(ticket),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ticket.id,
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Resolved',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ticket.issue,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18233B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _info(Icons.person_outline, ticket.customer),
                        const SizedBox(height: 6),
                        _info(Icons.location_on_outlined, ticket.property),
                        const SizedBox(height: 6),
                        _info(Icons.calendar_today_outlined, ticket.created),
                        if (ticket.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Work Notes: ${ticket.notes}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF526079),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'View Details  →',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF526079),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
