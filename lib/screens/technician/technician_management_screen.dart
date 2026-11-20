
import 'package:flutter/material.dart';

import '../../models/repair_ticket.dart';

class TechnicianManagementScreen extends StatelessWidget {
  const TechnicianManagementScreen({
    super.key,
    required this.tickets,
  });

  final List<RepairTicket> tickets;

  @override
  Widget build(BuildContext context) {
    final technicianNames = tickets
        .where(
          (ticket) =>
      ticket.assignedTo.trim().isNotEmpty &&
          ticket.assignedTo != 'Unassigned',
    )
        .map((ticket) => ticket.assignedTo)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('Technician Management'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF18233B),
      ),
      body: technicianNames.isEmpty
          ? const Center(
        child: Text('No technicians have been assigned to jobs yet.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: technicianNames.length,
        itemBuilder: (context, index) {
          final name = technicianNames[index];

          final technicianJobs = tickets
              .where((ticket) => ticket.assignedTo == name)
              .toList();

          final activeJobs = technicianJobs
              .where(
                (ticket) =>
            ticket.status == 'Assigned' ||
                ticket.status == 'In Progress',
          )
              .length;

          final completedJobs = technicianJobs
              .where((ticket) => ticket.status == 'Resolved')
              .length;

          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8EEFF),
                child: Icon(
                  Icons.engineering_rounded,
                  color: Color(0xFF2457C5),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Total assigned: ${technicianJobs.length}\n'
                      'Active jobs: $activeJobs\n'
                      'Completed jobs: $completedJobs',
                ),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
