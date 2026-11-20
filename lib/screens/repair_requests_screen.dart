import 'package:flutter/material.dart';
import '../models/repair_ticket.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_heading.dart';
import '../widgets/ticket_card.dart';

class RepairRequestsScreen extends StatefulWidget {
  const RepairRequestsScreen({
    super.key,
    required this.tickets,
    required this.onOpenTicket,
  });

  final List<RepairTicket> tickets;
  final ValueChanged<RepairTicket> onOpenTicket;

  @override
  State<RepairRequestsScreen> createState() =>
      _RepairRequestsScreenState();
}

class _RepairRequestsScreenState extends State<RepairRequestsScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchText = '';
  String statusFilter = 'All';

  final List<String> statuses = [
    'All',
    'Received',
    'Open',
    'Assigned',
    'Scheduled',
    'In Progress',
    'Resolved',
    'Cancelled',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = searchText.toLowerCase();
    final filtered = widget.tickets.where((ticket) {
      final matchesSearch = ticket.id.toLowerCase().contains(query) ||
          ticket.customer.toLowerCase().contains(query) ||
          ticket.issue.toLowerCase().contains(query) ||
          ticket.property.toLowerCase().contains(query);
      final matchesStatus =
          statusFilter == 'All' || ticket.status == statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const SectionHeading(
          title: 'Repair requests',
          subtitle: 'Track and manage service tickets',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          onChanged: (value) => setState(() => searchText = value),
          decoration: const InputDecoration(
            hintText: 'Search ticket, customer or issue',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: statuses.map((status) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status),
                  selected: statusFilter == status,
                  onSelected: (_) {
                    setState(() => statusFilter = status);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${filtered.length} request(s) found',
          style: const TextStyle(
            color: Colors.blueGrey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const EmptyState(message: 'No requests match your search.')
        else
          ...filtered.map(
                (ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TicketCard(
                ticket: ticket,
                onTap: () => widget.onOpenTicket(ticket),
              ),
            ),
          ),
      ],
    );
  }
}