
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

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text(
          'Technician Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF18233B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'My Work',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'View your assigned service jobs and progress.',
            style: TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _WorkStat(
                title: 'Assigned',
                count: assigned,
                color: const Color(0xFF2457C5),
              ),
              const SizedBox(width: 10),
              _WorkStat(
                title: 'In Progress',
                count: inProgress,
                color: const Color(0xFFE79A26),
              ),
              const SizedBox(width: 10),
              _WorkStat(
                title: 'Completed',
                count: completed,
                color: const Color(0xFF239B72),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'My Assigned Jobs',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (tickets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No jobs are assigned to you yet.'),
              ),
            )
          else
            ...tickets.map(
                  (ticket) => Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EEFF),
                    child: Icon(
                      Icons.build_rounded,
                      color: Color(0xFF2457C5),
                    ),
                  ),
                  title: Text(
                    ticket.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${ticket.customer}\n'
                          '${ticket.issue}\n'
                          'Property: ${ticket.property}\n'
                          'Status: ${ticket.status}',
                    ),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onOpenTicket(ticket),
                ),
              ),
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
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
