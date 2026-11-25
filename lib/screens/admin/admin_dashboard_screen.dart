
import 'package:flutter/material.dart';

import '../../models/repair_ticket.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.tickets,
    required this.onOpenTicket,
    required this.onViewRequests,
    required this.onViewTechnicians,
    required this.onViewSchedule,
    this.dashboardData,
  });

  final List<RepairTicket> tickets;
  final ValueChanged<RepairTicket> onOpenTicket;
  final VoidCallback onViewRequests;
  final VoidCallback onViewTechnicians;
  final VoidCallback onViewSchedule;
  final Map<String, dynamic>? dashboardData;

  static const Color navy = Color(0xFF142B4A);
  static const Color primary = Color(0xFF245B82);
  static const Color teal = Color(0xFF19A99A);
  static const Color background = Color(0xFFF4F7FA);
  static const Color textDark = Color(0xFF172B43);
  static const Color textMuted = Color(0xFF8290A3);

  @override
  Widget build(BuildContext context) {
    final counts =
        dashboardData?['ticket_counts'] as Map<String, dynamic>? ?? {};

    final totalRequests =
        dashboardData?['total_tickets'] ?? tickets.length;

    final resolvedCount = counts['Resolved'] ?? 0;

    final activeJobsCount =
        (counts['Assigned'] ?? 0) +
            (counts['Scheduled'] ?? 0) +
            (counts['In Progress'] ?? 0);

    final technicianCount =
        dashboardData?['active_technicians'] ?? 0;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // HEADER
                  // _buildHeader(context),

                  const SizedBox(height: 22),

                  // WELCOME CARD
                  _EntranceAnimation(
                    child: _buildWelcomeCard(),
                  ),

                  const SizedBox(height: 26),

                  // OVERVIEW HEADING
                  _buildSectionHeading(
                    'Overview',
                    'Service performance at a glance',
                  ),

                  const SizedBox(height: 14),

                  // STATISTICS
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth =
                          (constraints.maxWidth - 12) / 2;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _AdminStatCard(
                            width: cardWidth,
                            title: 'Total Requests',
                            value: '$totalRequests',
                            icon: Icons.confirmation_number_outlined,
                            color: const Color(0xFF3978C5),
                            backgroundColor: const Color(0xFFEAF2FC),
                          ),
                          _AdminStatCard(
                            width: cardWidth,
                            title: 'Resolved',
                            value: '$resolvedCount',
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF159B79),
                            backgroundColor: const Color(0xFFE6F6F0),
                          ),
                          _AdminStatCard(
                            width: cardWidth,
                            title: 'Active Jobs',
                            value: '$activeJobsCount',
                            icon: Icons.autorenew_rounded,
                            color: const Color(0xFFD99432),
                            backgroundColor: const Color(0xFFFFF3E1),
                          ),
                          _AdminStatCard(
                            width: cardWidth,
                            title: 'Technicians',
                            value: '$technicianCount',
                            icon: Icons.groups_outlined,
                            color: const Color(0xFF8066C8),
                            backgroundColor: const Color(0xFFF0ECFC),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // QUICK ACTIONS
                  _buildSectionHeading(
                    'Quick Actions',
                    'Manage your service operations',
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _AdminActionCard(
                          icon: Icons.engineering_outlined,
                          title: 'Technicians',
                          subtitle: 'Manage team',
                          color: const Color(0xFF3978C5),
                          backgroundColor: const Color(0xFFEAF2FC),
                          onTap: onViewTechnicians,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AdminActionCard(
                          icon: Icons.calendar_month_outlined,
                          title: 'Schedule',
                          subtitle: 'Manage visits',
                          color: teal,
                          backgroundColor: const Color(0xFFE5F6F3),
                          onTap: onViewSchedule,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // RECENT REQUESTS HEADING
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Requests',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Latest customer service requests',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: onViewRequests,
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // REQUEST LIST
                  if (tickets.isEmpty)
                    _buildEmptyState()
                  else
                    ...tickets.take(3).map(
                          (ticket) => _RecentRequestCard(
                        ticket: ticket,
                        onTap: () => onOpenTicket(ticket),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // VIEW ALL BUTTON
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: onViewRequests,
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text(
                        'View All Requests',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: const BorderSide(
                          color: Color(0xFFD5E1ED),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER
  // Widget _buildHeader(BuildContext context) {
  //   return Row(
  //     children: [
  //       Container(
  //         height: 46,
  //         width: 46,
  //         decoration: BoxDecoration(
  //           color: navy,
  //           borderRadius: BorderRadius.circular(14),
  //         ),
  //         child: const Icon(
  //           Icons.home_repair_service_rounded,
  //           color: Colors.white,
  //           size: 25,
  //         ),
  //       ),
  //       const SizedBox(width: 11),
  //       const Expanded(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'SECURIS',
  //               style: TextStyle(
  //                 color: navy,
  //                 fontSize: 17,
  //                 fontWeight: FontWeight.w900,
  //                 letterSpacing: 1.2,
  //               ),
  //             ),
  //             Text(
  //               'SERVICE MANAGEMENT',
  //               style: TextStyle(
  //                 color: textMuted,
  //                 fontSize: 9,
  //                 letterSpacing: 1.1,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       Material(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(13),
  //         child: InkWell(
  //           borderRadius: BorderRadius.circular(13),
  //           onTap: () {
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               const SnackBar(
  //                 content: Text(
  //                   'Notifications will be connected later.',
  //                 ),
  //               ),
  //             );
  //           },
  //           child: Container(
  //             height: 44,
  //             width: 44,
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(13),
  //               border: Border.all(
  //                 color: const Color(0xFFE5EBF1),
  //               ),
  //             ),
  //             child: const Icon(
  //               Icons.notifications_none_rounded,
  //               color: navy,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // WELCOME CARD
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF142B4A),
            Color(0xFF245B82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -18,
            child: Icon(
              Icons.settings_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'ADMIN PANEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Welcome Back, Admin!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Manage your repair services easily\nfrom one place.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SECTION HEADING
  Widget _buildSectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EDF2),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            color: Color(0xFF9AA8B8),
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'No service requests yet',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'New requests will appear here.',
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ENTRANCE ANIMATION
class _EntranceAnimation extends StatelessWidget {
  const _EntranceAnimation({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// STATISTICS CARD
class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return _EntranceAnimation(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEAF0F5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 39,
                  width: 39,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 21,
                  ),
                ),
                Icon(
                  Icons.trending_up_rounded,
                  color: color.withValues(alpha: 0.65),
                  size: 19,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              value,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: AdminDashboardScreen.textDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AdminDashboardScreen.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// QUICK ACTION CARD
class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE8EDF3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: AdminDashboardScreen.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AdminDashboardScreen.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: color,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// RECENT REQUEST CARD
class _RecentRequestCard extends StatelessWidget {
  const _RecentRequestCard({
    required this.ticket,
    required this.onTap,
  });

  final RepairTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE8EDF3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  height: 43,
                  width: 43,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FC),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.build_circle_outlined,
                    color: AdminDashboardScreen.primary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.id,
                        style: const TextStyle(
                          color: AdminDashboardScreen.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.customer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AdminDashboardScreen.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ticket.issue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AdminDashboardScreen.textDark,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Assigned: ${ticket.assignedTo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AdminDashboardScreen.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: ticket.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// STATUS BADGE
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    Color statusColor;

    switch (status) {
      case 'Resolved':
        statusColor = const Color(0xFF159B79);
        break;
      case 'In Progress':
        statusColor = const Color(0xFFD99432);
        break;
      case 'Assigned':
        statusColor = const Color(0xFF3978C5);
        break;
      case 'Scheduled':
        statusColor = const Color(0xFF8066C8);
        break;
      case 'Cancelled':
        statusColor = const Color(0xFFD65B65);
        break;
      default:
        statusColor = const Color(0xFF8290A3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
