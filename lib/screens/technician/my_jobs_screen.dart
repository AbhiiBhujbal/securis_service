
import 'package:flutter/material.dart';

import '../../models/repair_ticket.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({
    super.key,
    required this.tickets,
    required this.onOpenTicket,
  });

  final List<RepairTicket> tickets;
  final ValueChanged<RepairTicket> onOpenTicket;

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  String selectedFilter = 'All';

  static const Color primaryColor = Color(0xFF2457C5);

  List<RepairTicket> get filteredTickets {
    final activeTickets = widget.tickets
        .where((ticket) => ticket.status != 'Resolved')
        .toList();

    switch (selectedFilter) {
      case 'Assigned':
        return activeTickets
            .where((ticket) => ticket.status == 'Assigned')
            .toList();

      case 'In Progress':
        return activeTickets
            .where((ticket) => ticket.status == 'In Progress')
            .toList();

      default:
        return activeTickets;
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobs = filteredTickets;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          const Text(
            'My Jobs',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18233B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage your assigned service requests.',
            style: TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Active Jobs',
                  widget.tickets
                      .where((ticket) => ticket.status != 'Resolved')
                      .length,
                  Icons.work_outline_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  'In Progress',
                  widget.tickets
                      .where((ticket) => ticket.status == 'In Progress')
                      .length,
                  Icons.pending_actions_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Filter Jobs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['All', 'Assigned', 'In Progress'].map((filter) {
              final isSelected = selectedFilter == filter;

              return ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                selectedColor: const Color(0xFFDCE6FF),
                onSelected: (_) {
                  setState(() => selectedFilter = filter);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Service Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF18233B),
                  ),
                ),
              ),
              Text(
                '${jobs.length} jobs',
                style: const TextStyle(color: Colors.blueGrey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (jobs.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 44,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No jobs found',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'There are no jobs for this filter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
            )
          else
            ...jobs.map(_jobCard),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String title,
      int count,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 14),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18233B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobCard(RepairTicket ticket) {
    final statusColor = _statusColor(ticket.status);

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
        onTap: () => widget.onOpenTicket(ticket),
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
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Priority: ${ticket.priority}',
                      style: TextStyle(
                        color: ticket.priority.toLowerCase() == 'high'
                            ? Colors.red
                            : Colors.blueGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'View Details',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'Assigned':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange.shade800;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }
}
