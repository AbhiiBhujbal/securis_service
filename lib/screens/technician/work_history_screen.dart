
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

  static const Color navy = Color(0xFF172B4D);
  static const Color teal = Color(0xFF16B8A6);
  static const Color background = Color(0xFFF4F7FB);

  @override
  Widget build(BuildContext context) {
    // Existing resolved ticket filter - unchanged.
    final resolvedTickets = tickets
        .where((ticket) => ticket.status == 'Resolved')
        .toList();

    return Scaffold(
      backgroundColor: background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        children: [
          const Text(
            'Work History',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: navy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Review your completed service requests.',
            style: TextStyle(
              color: Colors.blueGrey.shade500,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 23),

          // Completed jobs summary
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(19),
              boxShadow: [
                BoxShadow(
                  color: navy.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    size: 29,
                    color: Color(0xFF55D8C6),
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
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Completed Jobs',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF55D8C6),
                  size: 28,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Completed Requests',
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
                  '${resolvedTickets.length} Jobs',
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

          if (resolvedTickets.isEmpty)
            const _EmptyHistory()
          else
            ...resolvedTickets.asMap().entries.map((entry) {
              final index = entry.key;
              final ticket = entry.value;

              return _HistoryTicketCard(
                ticket: ticket,
                index: index,
                onTap: () => onOpenTicket(ticket),
              );
            }),
        ],
      ),
    );
  }
}

class _HistoryTicketCard extends StatelessWidget {
  const _HistoryTicketCard({
    required this.ticket,
    required this.index,
    required this.onTap,
  });

  final RepairTicket ticket;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 60)),
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticket ID and resolved status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF4779D8),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F7F4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF239B72),
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Resolved',
                              style: TextStyle(
                                color: Color(0xFF239B72),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(
                    ticket.issue,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172B4D),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Divider(
                    height: 1,
                    color: Color(0xFFEDF1F6),
                  ),

                  const SizedBox(height: 14),

                  _HistoryInfo(
                    icon: Icons.person_outline_rounded,
                    text: ticket.customer,
                  ),
                  const SizedBox(height: 10),

                  _HistoryInfo(
                    icon: Icons.location_on_outlined,
                    text: ticket.property,
                  ),
                  const SizedBox(height: 10),

                  _HistoryInfo(
                    icon: Icons.calendar_today_outlined,
                    text: ticket.created,
                  ),

                  // Existing notes condition - unchanged.
                  if (ticket.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7FB),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: const Color(0xFFE8EDF4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 15,
                                color: Color(0xFF16A99B),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'WORK NOTES',
                                style: TextStyle(
                                  color: Color(0xFF119889),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            ticket.notes,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF526079),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: Color(0xFF16A99B),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF16A99B),
                          size: 16,
                        ),
                      ],
                    ),
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

class _HistoryInfo extends StatelessWidget {
  const _HistoryInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF8492A6),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF526079),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EDF4),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 46,
            color: Color(0xFF16A99B),
          ),
          SizedBox(height: 14),
          Text(
            'No Completed Jobs Yet',
            style: TextStyle(
              color: Color(0xFF172B4D),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Resolved jobs will appear here.',
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
