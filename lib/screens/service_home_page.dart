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
          'is_active': technician['is_active'] == true ||
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


  void switchRole(String newRole) {
    setState(() {
      role = newRole;
      selectedTab = 0;
    });
  }
  void logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

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
        const Center(
          child: CircularProgressIndicator(),
        )
      else if (ticketsError.isNotEmpty)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text('Unable to load repair requests'),
                const SizedBox(height: 8),
                Text(
                  ticketsError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: loadTickets,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        )
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
      ScheduleScreen(tickets: currentTickets, onOpenTicket: openTicket),
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
      MyJobsScreen(tickets: currentTickets, onOpenTicket: openTicket),
      ScheduleScreen(tickets: currentTickets, onOpenTicket: openTicket),
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

    if (selectedTab >= pages.length) selectedTab = 0;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF2457D6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.home_repair_service_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SECURIS',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  role == 'Admin' ? 'ADMIN PANEL' : 'TECHNICIAN PANEL',
                  style: const TextStyle(fontSize: 9, letterSpacing: 1.2),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications will be connected later.'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: selectedTab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: destinations,
      ),
    );
  }
}