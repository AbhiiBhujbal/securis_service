
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

  static const Color navyColor = Color(0xFF172B4D);
  static const Color tealColor = Color(0xFF16B8A6);
  static const Color backgroundColor = Color(0xFFF4F7FB);
  static const Color textColor = Color(0xFF18233B);

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
      final matchesSearch =
          ticket.id.toLowerCase().contains(query) ||
              ticket.customer.toLowerCase().contains(query) ||
              ticket.issue.toLowerCase().contains(query) ||
              ticket.property.toLowerCase().contains(query);

      final matchesStatus =
          statusFilter == 'All' || ticket.status == statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    return Container(
      color: backgroundColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const SectionHeading(
            title: 'Repair requests',
            subtitle: 'Track and manage service tickets',
          ),

          const SizedBox(height: 18),

          // Search field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.blueGrey.shade50,
              ),
              boxShadow: [
                BoxShadow(
                  color: navyColor.withValues(alpha: 0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() => searchText = value);
              },
              decoration: InputDecoration(
                hintText: 'Search ticket, customer or issue',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey.shade300,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: tealColor,
                ),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchText = '');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                  ),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Filter heading
          const Text(
            'Filter by status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),

          const SizedBox(height: 12),

          // Status filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statuses.map((status) {
                final isSelected = statusFilter == status;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => statusFilter = status);
                    },
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.blueGrey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedColor: navyColor,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? navyColor
                          : Colors.blueGrey.shade100,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Result count
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Colors.blueGrey.shade50,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: tealColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Matching requests',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${filtered.length} request(s) found',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: navyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (statusFilter != 'All' || searchText.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      searchController.clear();
                      setState(() {
                        searchText = '';
                        statusFilter = 'All';
                      });
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: tealColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Request list
          if (filtered.isEmpty)
            const EmptyState(
              message: 'No requests match your search.',
            )
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
      ),
    );
  }
}
