import 'package:flutter/material.dart';

import '../data/technician_store.dart';
import '../models/repair_ticket.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/technician_management_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'repair_requests_screen.dart';
import 'schedule_screen.dart';
import 'technician/my_jobs_screen.dart';
import 'technician/technician_dashboard_screen.dart';
import 'technician/work_history_screen.dart';
import 'ticket_details_screen.dart';

class ServiceHomePage extends StatefulWidget {
  const ServiceHomePage({
    super.key,
    this.initialRole = 'Admin',
    this.technicianName = 'Amit Technician',
  });

  final String initialRole;
  final String technicianName;

  @override
  State<ServiceHomePage> createState() => _ServiceHomePageState();
}

class _ServiceHomePageState extends State<ServiceHomePage> {
  // Premium Navy + Teal theme
  static const Color navyColor = Color(0xFF172B4D);
  static const Color navyDarkColor = Color(0xFF10213D);
  static const Color tealColor = Color(0xFF16B8A6);
  static const Color backgroundColor = Color(0xFFF4F7FB);
  static const Color textColor = Color(0xFF26354D);
  static const Color mutedColor = Color(0xFF8491A5);

  late String role;

  int selectedTab = 0;

  List<RepairTicket> tickets = [];

  String technicianId = '';

  bool isTicketsLoading = false;
  String ticketsError = '';

  Map<String, dynamic>? dashboardData;

  bool isDashboardLoading = false;
  String dashboardError = '';

  List<String> get technicianNames => [
    'Unassigned',
    ...technicianStore.map((technician) => technician['name']!),
  ];

  @override
  void initState() {
    super.initState();

    role = widget.initialRole;

    if (role == 'Admin') {
      loadDashboard();
      loadTechnicians();
    } else {
      loadTechnicianSession();
    }

    loadTickets();
  }

  // ============================================================
  // TECHNICIAN SESSION
  // ============================================================

  Future<void> loadTechnicianSession() async {
    final id = await AuthService.getUserId();

    if (!mounted) return;

    setState(() {
      technicianId = id;
    });

    debugPrint('========== TECHNICIAN SESSION ==========');
    debugPrint('Technician Name: ${widget.technicianName}');
    debugPrint('Technician ID: $technicianId');
  }

  // ============================================================
  // LOAD TICKETS
  // ============================================================

  Future<void> loadTickets() async {
    debugPrint('========== TICKETS API START ==========');

    try {
      if (mounted) {
        setState(() {
          isTicketsLoading = true;
          ticketsError = '';
        });
      }

      final response = await ApiService.get('tickets');

      debugPrint('TICKETS FULL RESPONSE: $response');

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'Failed to load repair tickets',
        );
      }

      final data = response['data'];

      if (data is! Map || data['tickets'] is! List) {
        throw Exception('Invalid tickets API response');
      }

      final List<RepairTicket> loadedTickets =
      (data['tickets'] as List).map((item) {
        if (item is! Map) {
          throw Exception('Invalid ticket data received');
        }

        return RepairTicket.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        tickets = loadedTickets;
      });

      debugPrint('TOTAL TICKETS LOADED: ${tickets.length}');
      debugPrint('========== TICKETS API SUCCESS ==========');
    } catch (e) {
      debugPrint('TICKETS API ERROR: $e');

      if (mounted) {
        setState(() {
          ticketsError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isTicketsLoading = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD TECHNICIANS
  // ============================================================

  Future<void> loadTechnicians() async {
    debugPrint('========== TECHNICIANS API START ==========');

    try {
      final response = await ApiService.get('technicians');

      debugPrint('TECHNICIANS FULL RESPONSE: $response');

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'Failed to load technicians',
        );
      }

      final data = response['data'];

      if (data is! Map || data['technicians'] is! List) {
        throw Exception('Invalid technicians API response');
      }

      final List<Map<String, String>> loadedTechnicians =
      (data['technicians'] as List).map((item) {
        final technician = Map<String, dynamic>.from(item);

        return <String, String>{
          'id': technician['id'].toString(),
          'name': (technician['name'] ?? '').toString(),
          'email': (technician['email'] ?? '').toString(),
          'phone': (technician['phone'] ?? '').toString(),
          'role': (technician['role'] ?? 'Technician').toString(),
          'is_active':
          technician['is_active'] == true ||
              technician['is_active'] == 1
              ? '1'
              : '0',
          'specialization': '',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        technicianStore
          ..clear()
          ..addAll(loadedTechnicians);
      });

      debugPrint('TOTAL TECHNICIANS: ${technicianStore.length}');
      debugPrint('========== TECHNICIANS API SUCCESS ==========');
    } catch (e) {
      debugPrint('TECHNICIANS API ERROR: $e');
    }
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> loadDashboard() async {
    debugPrint('========== DASHBOARD API START ==========');

    try {
      setState(() {
        isDashboardLoading = true;
        dashboardError = '';
      });

      final response = await ApiService.get('dashboard');

      debugPrint('DASHBOARD FULL RESPONSE: $response');

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;

        if (!mounted) return;

        setState(() {
          dashboardData = data;
        });

        debugPrint('ROLE: ${data['role']}');
        debugPrint('TOTAL TICKETS: ${data['total_tickets']}');
        debugPrint('TICKET COUNTS: ${data['ticket_counts']}');
        debugPrint('ACTIVE TECHNICIANS: ${data['active_technicians']}');

        debugPrint('========== DASHBOARD API SUCCESS ==========');
      } else {
        throw Exception(
          response['message'] ?? 'Dashboard API failed',
        );
      }
    } catch (e) {
      debugPrint('DASHBOARD API ERROR: $e');

      if (mounted) {
        setState(() {
          dashboardError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isDashboardLoading = false;
        });
      }
    }
  }

  // ============================================================
  // VISIBLE TICKETS
  // ============================================================

  List<RepairTicket> get visibleTickets {
    if (role == 'Admin') return tickets;

    if (technicianId.isEmpty) {
      debugPrint('TECHNICIAN ID NOT AVAILABLE');
      return [];
    }

    final assignedTickets = tickets.where((ticket) {
      final isAssignedToTechnician =
          ticket.assignedTo.trim() == technicianId.trim();

      debugPrint(
        'Ticket: ${ticket.id} | '
            'Assigned ID: ${ticket.assignedTo} | '
            'Logged In ID: $technicianId | '
            'Match: $isAssignedToTechnician',
      );

      return isAssignedToTechnician;
    }).toList();

    debugPrint('TECHNICIAN JOBS FOUND: ${assignedTickets.length}');

    return assignedTickets;
  }

  // ============================================================
  // OPEN TICKET
  // ============================================================

  Future<void> openTicket(RepairTicket ticket) async {
    debugPrint('OPEN TICKET: ${ticket.id}');

    final ticketUpdated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return TicketDetailsScreen(
          ticket: ticket,
          role: role,
          technicianNames: technicianNames,
          technicianName: widget.technicianName,
          onSave: (updatedTicket) {
            debugPrint('TICKET SAVE CALLBACK: ${updatedTicket.id}');
            Navigator.of(sheetContext).pop(true);
          },
        );
      },
    );

    if (!mounted) return;

    if (ticketUpdated == true) {
      debugPrint('BOTTOM SHEET CLOSED. REFRESHING TICKETS.');

      await loadTickets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ============================================================
  // ROLE SWITCH
  // ============================================================

  void switchRole(String newRole) {
    setState(() {
      role = newRole;
      selectedTab = 0;
    });
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  // ============================================================
  // ERROR SCREEN
  // ============================================================

  Widget _buildTicketsError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE8EDF4),
            ),
            boxShadow: [
              BoxShadow(
                color: navyColor.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFE05252),
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Unable to load repair requests',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: navyColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ticketsError,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: mutedColor,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: loadTickets,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING SCREEN
  // ============================================================

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: tealColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading repair requests...',
            style: TextStyle(
              color: mutedColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBarTitle() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                tealColor,
                Color(0xFF0E9E91),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: tealColor.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.home_repair_service_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SECURIS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              role == 'Admin' ? 'ADMIN PANEL' : 'TECHNICIAN PANEL',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currentTickets = visibleTickets;

    final pages = role == 'Admin'
        ? <Widget>[
      AdminDashboardScreen(
        tickets: currentTickets,
        onOpenTicket: openTicket,
        onViewRequests: () => setState(() => selectedTab = 1),
        onViewTechnicians: () => setState(() => selectedTab = 2),
        onViewSchedule: () => setState(() => selectedTab = 3),
        dashboardData: dashboardData,
      ),

      if (isTicketsLoading)
        _buildLoadingScreen()
      else if (ticketsError.isNotEmpty)
        _buildTicketsError()
      else
        RepairRequestsScreen(
          tickets: currentTickets,
          onOpenTicket: openTicket,
        ),

      TechnicianManagementScreen(
        tickets: tickets,
        technicians: technicianStore,
        onChanged: loadTechnicians,
      ),

      ScheduleScreen(
        tickets: currentTickets,
        onOpenTicket: openTicket,
      ),

      ProfileScreen(
        role: role,
        onSwitchRole: () => switchRole('Technician'),
        onLogout: logout,
      ),
    ]
        : <Widget>[
      TechnicianDashboardScreen(
        tickets: currentTickets,
        onOpenTicket: openTicket,
      ),

      MyJobsScreen(
        tickets: currentTickets,
        onOpenTicket: openTicket,
      ),

      ScheduleScreen(
        tickets: currentTickets,
        onOpenTicket: openTicket,
      ),

      WorkHistoryScreen(
        tickets: currentTickets,
        onOpenTicket: openTicket,
      ),

      ProfileScreen(
        role: role,
        onSwitchRole: () => switchRole('Admin'),
        onLogout: logout,
      ),
    ];

    final destinations = role == 'Admin'
        ? const <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.confirmation_number_outlined),
        selectedIcon: Icon(Icons.confirmation_number_rounded),
        label: 'Requests',
      ),
      NavigationDestination(
        icon: Icon(Icons.engineering_outlined),
        selectedIcon: Icon(Icons.engineering_rounded),
        label: 'Technicians',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month_rounded),
        label: 'Schedule',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ]
        : const <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.build_outlined),
        selectedIcon: Icon(Icons.build_rounded),
        label: 'My Jobs',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month_rounded),
        label: 'Schedule',
      ),
      NavigationDestination(
        icon: Icon(Icons.history_rounded),
        selectedIcon: Icon(Icons.history_rounded),
        label: 'History',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    if (selectedTab >= pages.length) {
      selectedTab = 0;
    }

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: tealColor,
          secondary: tealColor,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: navyColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          toolbarHeight: 70,
          titleSpacing: 18,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          height: 70,
          indicatorColor: tealColor.withValues(alpha: 0.13),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                (states) {
              final selected = states.contains(WidgetState.selected);

              return TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? navyColor : mutedColor,
              );
            },
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                (states) {
              final selected = states.contains(WidgetState.selected);

              return IconThemeData(
                size: 23,
                color: selected ? tealColor : mutedColor,
              );
            },
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: _buildAppBarTitle(),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Notifications will be connected later.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),

        body: SafeArea(
          child: IndexedStack(
            index: selectedTab,
            children: pages,
          ),
        ),

        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedTab,
          onDestinationSelected: (index) {
            setState(() {
              selectedTab = index;
            });
          },
          destinations: destinations,
        ),
      ),
    );
  }
}