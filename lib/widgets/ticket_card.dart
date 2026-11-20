import 'package:flutter/material.dart';
import '../models/repair_ticket.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  final RepairTicket ticket;
  final VoidCallback onTap;

  Color get statusColor {
    switch (ticket.status) {
      case 'Open':
        return const Color(0xFFE59A24);
      case 'Assigned':
        return const Color(0xFF7960D6);
      case 'In Progress':
        return const Color(0xFF2457D6);
      case 'Resolved':
        return const Color(0xFF209B70);
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    ticket.id,
                    style: const TextStyle(
                      color: Color(0xFF2457D6),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.issue,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF18233B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${ticket.customer} · ${ticket.property}',
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.flag_rounded,
                    size: 16,
                    color: ticket.priority == 'High'
                        ? Colors.redAccent
                        : Colors.blueGrey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${ticket.priority} priority',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      ticket.assignedTo,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.blueGrey,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}