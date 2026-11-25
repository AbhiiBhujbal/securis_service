
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

  static const Color primaryColor = Color(0xFF172B4D);
  static const Color accentColor = Color(0xFF16B8A6);
  static const Color backgroundColor = Color(0xFFF4F7FB);
  static const Color textColor = Color(0xFF18243A);
  static const Color mutedColor = Color(0xFF718096);

  // FILTER LOGIC - ORIGINAL LOGIC PRESERVED
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

    final activeJobsCount = widget.tickets
        .where((ticket) => ticket.status != 'Resolved')
        .length;

    final inProgressCount = widget.tickets
        .where((ticket) => ticket.status == 'In Progress')
        .length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          children: [
            // HEADER
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Jobs',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage your assigned service requests.',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F7F4),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: accentColor,
                    size: 25,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // SUMMARY CARDS
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Active Jobs',
                    activeJobsCount,
                    Icons.work_outline_rounded,
                    const Color(0xFF356AE6),
                    const Color(0xFFEAF1FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    'In Progress',
                    inProgressCount,
                    Icons.pending_actions_rounded,
                    const Color(0xFFE58A28),
                    const Color(0xFFFFF3E4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            // FILTER SECTION
            const Text(
              'Filter Jobs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),

            const SizedBox(height: 13),

            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: ['All', 'Assigned', 'In Progress'].map((filter) {
                final isSelected = selectedFilter == filter;

                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : mutedColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? primaryColor
                        : const Color(0xFFE1E7EF),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            // SERVICE REQUESTS HEADER
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Service Requests',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F5F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${jobs.length} Jobs',
                    style: const TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // EMPTY STATE
            if (jobs.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: const Color(0xFFE8EDF4),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(17),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5F5F3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        size: 34,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'No jobs found',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'There are no jobs for this filter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...jobs.map(_jobCard),
          ],
        ),
      ),
    );
  }

  // SUMMARY CARD
  Widget _summaryCard(
      String title,
      int count,
      IconData icon,
      Color foregroundColor,
      Color cardColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EDF4),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: foregroundColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // JOB CARD
  Widget _jobCard(RepairTicket ticket) {
    final statusColor = _statusColor(ticket.status);

    final isHighPriority = ticket.priority.toLowerCase() == 'high';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE8EDF4),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () => widget.onOpenTicket(ticket),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TICKET ID AND STATUS
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ticket.status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // ISSUE TITLE
                Text(
                  ticket.issue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 15),

                // CUSTOMER
                _info(
                  Icons.person_outline_rounded,
                  ticket.customer,
                ),

                const SizedBox(height: 10),

                // PROPERTY
                _info(
                  Icons.location_on_outlined,
                  ticket.property,
                ),

                const SizedBox(height: 10),

                // CREATED DATE
                _info(
                  Icons.calendar_today_outlined,
                  ticket.created,
                ),

                const SizedBox(height: 16),

                const Divider(
                  height: 1,
                  color: Color(0xFFEDF0F5),
                ),

                const SizedBox(height: 14),

                // PRIORITY AND VIEW DETAILS
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 17,
                            color: isHighPriority
                                ? Colors.red.shade700
                                : mutedColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Priority: ${ticket.priority}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isHighPriority
                                    ? Colors.red.shade700
                                    : mutedColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                      color: accentColor,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'View Details',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // JOB INFORMATION ROW
  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: accentColor,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF526078),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // STATUS COLOR
  Color _statusColor(String status) {
    switch (status) {
      case 'Assigned':
        return const Color(0xFF356AE6);

      case 'In Progress':
        return const Color(0xFFE58A28);

      case 'Resolved':
        return const Color(0xFF15945B);

      default:
        return mutedColor;
    }
  }
}
