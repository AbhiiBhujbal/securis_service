import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/technician_store.dart';
import '../models/repair_ticket.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class TicketDetailsScreen extends StatefulWidget {
  const TicketDetailsScreen({
    super.key,
    required this.ticket,
    required this.role,
    required this.technicianNames,
    required this.technicianName,
    required this.onSave,
  });

  final RepairTicket ticket;
  final String role;
  final List<String> technicianNames;
  final String technicianName;
  final ValueChanged<RepairTicket> onSave;

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  // Premium Navy + Teal theme
  static const Color navy = Color(0xFF172B4D);
  static const Color navyDark = Color(0xFF10213D);
  static const Color teal = Color(0xFF16B8A6);
  static const Color background = Color(0xFFF4F7FB);
  static const Color textColor = Color(0xFF26354D);
  static const Color muted = Color(0xFF8491A5);
  static const Color borderColor = Color(0xFFE7ECF3);

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _notesController;
  late final TextEditingController _resolutionController;

  late String _status;
  late String _assignedTo;
  late List<String> _photoPaths;

  bool _saving = false;
  bool _completeDialogOpen = false;
  bool _scheduling = false;

  StreamSubscription<Position>? _positionSubscription;
  Position? _technicianPosition;
  bool _locationLoading = false;

  List<LatLng> _routePoints = [];
  bool _routeLoading = false;

  double? _remainingDistanceKm;
  double? _remainingDurationMinutes;

  LatLng? _pendingRoutePoint;

  bool get isAdmin => widget.role.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();

    _notesController = TextEditingController(text: widget.ticket.notes);
    _resolutionController =
        TextEditingController(text: widget.ticket.resolution);

    _status = widget.ticket.status;
    _assignedTo = widget.ticket.assignedTo;
    _photoPaths = List<String>.from(widget.ticket.photoPaths);

    debugPrint('IS ADMIN: $isAdmin');
    debugPrint('TICKET STATUS: ${widget.ticket.status}');

    if (!isAdmin && widget.ticket.status == 'In Progress') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('STARTING TECHNICIAN LIVE TRACKING...');
          _startTechnicianLiveTracking();
        }
      });
    }
  }

  @override
  void dispose() {
    debugPrint('STOPPING TECHNICIAN GPS TRACKING');

    _positionSubscription?.cancel();
    _notesController.dispose();
    _resolutionController.dispose();

    super.dispose();
  }

  // ============================================================
  // COMMON UI HELPERS
  // ============================================================

  void _showMessage(
      String message, {
        Color backgroundColor = Colors.red,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: muted, size: 21),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: teal, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: teal.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: teal, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool loading = false,
    Color color = navy,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Icon(icon, size: 20),
        label: Text(
          loading ? 'Please wait...' : label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _outlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 49,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PHOTO SELECTION
  // ============================================================

  Future<void> _pickPhotos() async {
    if (_saving || _scheduling) return;

    try {
      final selectedPhotos = await _imagePicker.pickMultiImage();

      if (!mounted || selectedPhotos.isEmpty) return;

      setState(() {
        _photoPaths.addAll(selectedPhotos.map((photo) => photo.path));
      });
    } catch (e) {
      _showMessage('Unable to select photos: $e');
    }
  }

  void _removePhoto(int index) {
    if (_saving || _scheduling) return;
    if (index < 0 || index >= _photoPaths.length) return;

    setState(() {
      _photoPaths.removeAt(index);
    });

    widget.ticket.photoPaths = List<String>.from(_photoPaths);
  }

  Future<void> _uploadPendingPhotos() async {
    if (widget.ticket.backendId <= 0) {
      throw Exception('Invalid ticket database ID.');
    }

    final pendingPhotos = _photoPaths
        .where(
          (path) =>
      !path.startsWith('http://') &&
          !path.startsWith('https://'),
    )
        .toList();

    if (pendingPhotos.isEmpty) {
      debugPrint('No pending photos to upload.');
      return;
    }

    debugPrint('========== PHOTO UPLOAD START ==========');
    debugPrint('Ticket DB ID: ${widget.ticket.backendId}');
    debugPrint('Pending photos: ${pendingPhotos.length}');

    for (final path in pendingPhotos) {
      if (!mounted) return;

      final file = File(path);

      if (!await file.exists()) {
        throw Exception('Selected photo not found: $path');
      }

      debugPrint('Uploading photo: $path');

      final response = await ApiService.uploadPhoto(
        'tickets/${widget.ticket.backendId}/photos',
        filePath: path,
      );

      debugPrint('PHOTO UPLOAD RESPONSE: $response');

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'Photo upload failed.',
        );
      }

      final data = response['data'];
      final photos = data is Map ? data['photos'] : null;

      if (photos is! List || photos.isEmpty) {
        throw Exception(
          'Photo uploaded but server returned no photo URLs.',
        );
      }

      final uploadedUrl = photos.last.toString().trim();

      if (uploadedUrl.isEmpty) {
        throw Exception('Server returned an empty photo URL.');
      }

      if (!mounted) return;

      final index = _photoPaths.indexOf(path);

      if (index != -1) {
        setState(() {
          _photoPaths[index] = uploadedUrl;
        });
      }

      widget.ticket.photoPaths = List<String>.from(_photoPaths);

      debugPrint('PHOTO UPLOAD SUCCESS: $uploadedUrl');
    }

    debugPrint('========== PHOTO UPLOAD COMPLETED ==========');
  }

  // ============================================================
  // TECHNICIAN ASSIGNMENT
  // ============================================================

  Future<void> _assignTechnician() async {
    if (_assignedTo == widget.ticket.assignedTo) return;

    if (_assignedTo == 'Unassigned' || _assignedTo.isEmpty) {
      throw Exception(
        'Unassign is not supported by the current backend API.',
      );
    }

    final selectedTechnician = technicianStore.firstWhere(
          (technician) => technician['name'] == _assignedTo,
      orElse: () => <String, String>{},
    );

    final technicianId = selectedTechnician['id'];
    final isActive = selectedTechnician['is_active'];

    debugPrint('SELECTED TECHNICIAN: $selectedTechnician');

    if (technicianId == null || technicianId.isEmpty) {
      throw Exception('Technician ID not found. Reload technicians.');
    }

    if (isActive != 'true' && isActive != '1') {
      throw Exception('Selected technician is inactive.');
    }

    if (widget.ticket.backendId <= 0) {
      throw Exception('Invalid ticket database ID.');
    }

    debugPrint('========== ASSIGNMENT API START ==========');
    debugPrint('Ticket DB ID: ${widget.ticket.backendId}');
    debugPrint('Ticket Code: ${widget.ticket.id}');
    debugPrint('Technician ID: $technicianId');
    debugPrint('Technician Name: $_assignedTo');

    final response = await ApiService.post(
      'tickets/${widget.ticket.backendId}/assign',
      body: {
        'technician_id': int.parse(technicianId),
      },
    );

    debugPrint('ASSIGNMENT API RESPONSE: $response');

    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Technician assignment failed.',
      );
    }

    widget.ticket
      ..assignedTo = _assignedTo
      ..status = 'Assigned';

    _status = 'Assigned';

    debugPrint('========== ASSIGNMENT API SUCCESS ==========');
  }

  // ============================================================
  // SAVE WORK
  // ============================================================

  Future<void> _saveWork() async {
    if (_saving || _scheduling) return;

    if (!_formKey.currentState!.validate()) return;

    if (isAdmin &&
        widget.ticket.status != 'Open' &&
        widget.ticket.status != 'Assigned' &&
        _status != widget.ticket.status) {
      _showMessage(
        'Only the assigned technician can change an active or resolved ticket status.',
      );
      return;
    }

    if (isAdmin &&
        (_status == 'In Progress' || _status == 'Resolved')) {
      _showMessage(
        'Technician must update In Progress and Resolved statuses through the service visit workflow.',
      );
      return;
    }

    if (_status == 'Resolved' &&
        _resolutionController.text.trim().isEmpty) {
      _showMessage(
        'Enter the resolution before resolving this ticket.',
      );
      return;
    }

    if (isAdmin &&
        _assignedTo == 'Unassigned' &&
        widget.ticket.assignedTo != 'Unassigned' &&
        widget.ticket.assignedTo.isNotEmpty) {
      _showMessage(
        'Unassign is not supported by the current backend API.',
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (isAdmin && _assignedTo != widget.ticket.assignedTo) {
        await _assignTechnician();
      }

      debugPrint('SAVE WORK: Starting photo upload');

      await _uploadPendingPhotos();

      if (!mounted) return;

      debugPrint('SAVE WORK: Photo upload completed');

      _applyCurrentFields();

      widget.onSave(widget.ticket);

      debugPrint('SAVE WORK: Ticket details updated in parent.');
    } catch (e) {
      debugPrint('SAVE TICKET ERROR: $e');

      _showMessage('Unable to save: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _applyCurrentFields() {
    widget.ticket
      ..status = _status
      ..assignedTo = _assignedTo
      ..notes = _notesController.text.trim()
      ..resolution = _resolutionController.text.trim()
      ..photoPaths = List<String>.from(_photoPaths);
  }

  // ============================================================
  // SCHEDULE VISIT
  // ============================================================

  Future<void> _scheduleVisit() async {
    if (!isAdmin || _saving || _scheduling) return;

    if (widget.ticket.assignedTo == 'Unassigned' ||
        widget.ticket.assignedTo.isEmpty) {
      _showMessage(
        'Please assign a technician before scheduling a visit.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (widget.ticket.backendId <= 0) {
      _showMessage('Invalid ticket database ID.');
      return;
    }

    setState(() => _scheduling = true);

    try {
      final now = DateTime.now();

      final date = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: now.add(const Duration(days: 365)),
      );

      if (!mounted || date == null) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (!mounted || time == null) return;

      final scheduledDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final formattedDateTime =
          '${scheduledDateTime.year}-'
          '${scheduledDateTime.month.toString().padLeft(2, '0')}-'
          '${scheduledDateTime.day.toString().padLeft(2, '0')} '
          '${scheduledDateTime.hour.toString().padLeft(2, '0')}:'
          '${scheduledDateTime.minute.toString().padLeft(2, '0')}:00';

      if (!mounted) return;

      setState(() => _saving = true);

      debugPrint('========== SCHEDULE VISIT API START ==========');
      debugPrint('Ticket DB ID: ${widget.ticket.backendId}');
      debugPrint('Scheduled At: $formattedDateTime');

      final response = await ApiService.post(
        'tickets/${widget.ticket.backendId}/schedule',
        body: {
          'scheduled_at': formattedDateTime,
          'schedule_notes': 'Service visit scheduled by Admin',
        },
      );

      debugPrint('SCHEDULE VISIT API RESPONSE: $response');

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'Unable to schedule service visit.',
        );
      }

      if (!mounted) return;

      widget.ticket.scheduledVisit = formattedDateTime;
      _applyCurrentFields();

      debugPrint('========== SCHEDULE VISIT API SUCCESS ==========');

      widget.onSave(widget.ticket);
    } catch (e) {
      debugPrint('SCHEDULE VISIT API ERROR: $e');

      _showMessage('Unable to schedule visit: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _scheduling = false;
        });
      }
    }
  }

  // ============================================================
  // START VISIT
  // ============================================================

  Future<void> _startVisit() async {
    if (isAdmin || _saving || _scheduling) return;

    if (widget.ticket.status == 'Resolved' ||
        widget.ticket.status == 'Cancelled') {
      return;
    }

    setState(() => _saving = true);

    try {
      final currentTechnicianId = await AuthService.getUserId();

      if (!mounted) return;

      debugPrint('========== START VISIT VALIDATION ==========');
      debugPrint('Ticket Code: ${widget.ticket.id}');
      debugPrint('Assigned Technician ID: ${widget.ticket.assignedTo}');
      debugPrint('Logged In Technician ID: $currentTechnicianId');

      if (widget.ticket.assignedTo.trim() !=
          currentTechnicianId.trim()) {
        debugPrint('START VISIT BLOCKED: Technician ID mismatch');

        _showMessage('You can only start a visit assigned to you.');
        return;
      }

      if (widget.ticket.status == 'In Progress' ||
          widget.ticket.visitStartedAt.isNotEmpty) {
        _showMessage('This service visit has already started.');
        return;
      }

      if (widget.ticket.assignedTo == 'Unassigned' ||
          widget.ticket.assignedTo.isEmpty) {
        _showMessage('Assign a technician before starting the visit.');
        return;
      }

      if (widget.ticket.scheduledVisit.isEmpty) {
        _showMessage('Please schedule the visit first.');
        return;
      }

      if (widget.ticket.backendId <= 0) {
        _showMessage('Invalid ticket database ID.');
        return;
      }

      debugPrint('START VISIT VALIDATION SUCCESS');
      debugPrint('========== START VISIT API START ==========');
      debugPrint('Ticket DB ID: ${widget.ticket.backendId}');
      debugPrint('Ticket Code: ${widget.ticket.id}');
      debugPrint('Technician ID: $currentTechnicianId');

      final response = await ApiService.post(
        'tickets/${widget.ticket.backendId}/visit/start',
      );

      debugPrint('START VISIT API RESPONSE: $response');

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'Unable to start service visit.',
        );
      }

      if (!mounted) return;

      final ticketData = response['data']?['ticket'];

      widget.ticket
        ..notes = _notesController.text.trim()
        ..resolution = _resolutionController.text.trim()
        ..photoPaths = List<String>.from(_photoPaths)
        ..visitStartedAt =
            ticketData?['visit_started_at']?.toString() ??
                DateTime.now().toString()
        ..status = ticketData?['status']?.toString() ?? 'In Progress';

      _status = widget.ticket.status;

      debugPrint('========== START VISIT API SUCCESS ==========');
      debugPrint('Updated Status: ${widget.ticket.status}');
      debugPrint('Visit Started At: ${widget.ticket.visitStartedAt}');

      await _startTechnicianLiveTracking();

      widget.onSave(widget.ticket);
    } catch (e) {
      debugPrint('START VISIT API ERROR: $e');

      _showMessage('Unable to start visit: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ============================================================
  // COMPLETE VISIT
  // ============================================================

  Future<void> _completeVisit() async {
    if (isAdmin || _saving || _scheduling || _completeDialogOpen) {
      return;
    }

    setState(() => _completeDialogOpen = true);

    try {
      final currentTechnicianId = await AuthService.getUserId();

      if (!mounted) return;

      debugPrint('========== COMPLETE VISIT VALIDATION ==========');
      debugPrint('Ticket Code: ${widget.ticket.id}');
      debugPrint('Assigned Technician ID: ${widget.ticket.assignedTo}');
      debugPrint('Logged In Technician ID: $currentTechnicianId');

      if (widget.ticket.assignedTo.trim() !=
          currentTechnicianId.trim()) {
        _showMessage(
          'Only the assigned technician can complete this visit.',
        );
        return;
      }

      if (widget.ticket.status == 'Resolved') {
        _showMessage('This ticket is already resolved.');
        return;
      }

      if (widget.ticket.visitStartedAt.isEmpty) {
        _showMessage('Start the visit before completing it.');
        return;
      }

      if (widget.ticket.backendId <= 0) {
        _showMessage('Invalid ticket database ID.');
        return;
      }

      final resolution = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _CompleteVisitDialog(
            initialResolution: widget.ticket.resolution,
          );
        },
      );

      if (!mounted) return;

      if (resolution == null) return;

      if (widget.ticket.visitStartedAt.isEmpty) {
        _showMessage('Start the visit before completing it.');
        return;
      }

      setState(() {
        _completeDialogOpen = false;
        _saving = true;
      });

      debugPrint('========== COMPLETE VISIT API START ==========');
      debugPrint('Ticket DB ID: ${widget.ticket.backendId}');
      debugPrint('Ticket Code: ${widget.ticket.id}');
      debugPrint('Technician ID: $currentTechnicianId');
      debugPrint('Resolution: $resolution');
      debugPrint('COMPLETE VISIT: Starting photo upload');

      await _uploadPendingPhotos();

      if (!mounted) return;

      debugPrint('COMPLETE VISIT: Photo upload completed');

      final response = await ApiService.post(
        'tickets/${widget.ticket.backendId}/visit/complete',
        body: {
          'work_notes': _notesController.text.trim(),
          'resolution': resolution,
        },
      );

      debugPrint('COMPLETE VISIT API RESPONSE: $response');

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'Unable to complete service visit.',
        );
      }

      if (!mounted) return;

      final ticketData = response['data']?['ticket'];

      widget.ticket
        ..notes = _notesController.text.trim()
        ..resolution =
            ticketData?['resolution']?.toString() ?? resolution
        ..photoPaths = List<String>.from(_photoPaths)
        ..visitCompletedAt =
            ticketData?['visit_completed_at']?.toString() ??
                DateTime.now().toString()
        ..status = ticketData?['status']?.toString() ?? 'Resolved';

      _resolutionController.text = resolution;
      _status = widget.ticket.status;

      debugPrint('========== COMPLETE VISIT API SUCCESS ==========');
      debugPrint('Updated Status: ${widget.ticket.status}');
      debugPrint('Resolution: ${widget.ticket.resolution}');
      debugPrint('Visit Completed At: ${widget.ticket.visitCompletedAt}');

      widget.onSave(widget.ticket);
    } catch (e) {
      debugPrint('COMPLETE VISIT API ERROR: $e');

      _showMessage('Unable to complete visit: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _completeDialogOpen = false;
        });
      }
    }
  }

  // ============================================================
  // STATUS COLORS
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF20A46B);
      case 'in progress':
        return const Color(0xFFE99A36);
      case 'assigned':
        return const Color(0xFF3976C8);
      case 'open':
        return const Color(0xFFE05252);
      default:
        return const Color(0xFF718096);
    }
  }

  Widget _badge(String text) {
    final color = _statusColor(text);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // READ ONLY FIELD
  // ============================================================

  Widget _readOnlyField(
      String label,
      String value,
      IconData icon,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: teal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: teal, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SERVICE VISIT SECTION
  // ============================================================

  Widget _serviceVisitSection() {
    final ticket = widget.ticket;
    final isResolved = ticket.status == 'Resolved';
    final hasStarted = ticket.visitStartedAt.isNotEmpty;

    return _sectionCard(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: teal),
              SizedBox(width: 10),
              Text(
                'Service Visit',
                style: TextStyle(
                  color: navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _readOnlyField(
            'Scheduled Visit',
            ticket.scheduledVisit,
            Icons.event_outlined,
          ),
          if (ticket.visitStartedAt.isNotEmpty)
            _readOnlyField(
              'Visit Started',
              ticket.visitStartedAt,
              Icons.play_circle_outline,
            ),
          if (ticket.visitCompletedAt.isNotEmpty)
            _readOnlyField(
              'Visit Completed',
              ticket.visitCompletedAt,
              Icons.task_alt,
            ),
          if (isAdmin && !isResolved)
            _outlinedButton(
              label: ticket.scheduledVisit.isEmpty
                  ? 'Schedule Visit'
                  : 'Reschedule Visit',
              icon: Icons.calendar_month_rounded,
              onPressed: (_saving || _scheduling) ? null : _scheduleVisit,
            ),
          if (!isAdmin && !isResolved && !hasStarted)
            _primaryButton(
              label: 'Start Visit',
              icon: Icons.play_arrow_rounded,
              onPressed: _saving ? null : _startVisit,
              loading: _saving,
              color: teal,
            ),
          if (!isAdmin && !isResolved && hasStarted)
            _primaryButton(
              label: 'Complete Visit',
              icon: Icons.check_circle_outline_rounded,
              onPressed: (_saving || _completeDialogOpen)
                  ? null
                  : _completeVisit,
              loading: _saving,
              color: teal,
            ),
          if (isResolved)
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF20A46B)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Service visit completed',
                      style: TextStyle(
                        color: Color(0xFF187A4B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }



  Widget _liveDistanceCard() {
    final distance = _remainingDistanceKm;
    final duration = _remainingDurationMinutes;

    if (distance == null || duration == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: teal,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Calculating route distance and arrival time...',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final distanceText = distance < 1
        ? '${(distance * 1000).round()} m'
        : '${distance.toStringAsFixed(1)} km';

    final minutes = duration.ceil();

    final timeText = minutes < 1
        ? 'Less than 1 min'
        : '$minutes min';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10213D),
            Color(0xFF1B4560),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: teal.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: teal,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Technician is on the way',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Distance remaining: $distanceText',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: teal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  timeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'ETA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER LOCATION MAP
  // ============================================================

  Widget _customerLocationMap() {
    final latitude = widget.ticket.latitude;
    final longitude = widget.ticket.longitude;

    debugPrint(
      'MAPTILER KEY LOADED: '
          '${dotenv.env['MAPTILER_API_KEY']?.isNotEmpty == true}',
    );

    final hasValidLocation = latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;

    final technicianPosition = _technicianPosition;

    final customerPoint = hasValidLocation
        ? LatLng(latitude!, longitude!)
        : null;

    final technicianPoint = technicianPosition != null
        ? LatLng(
      technicianPosition.latitude,
      technicianPosition.longitude,
    )
        : null;

    final mapCenter = customerPoint != null && technicianPoint != null
        ? LatLng(
      (customerPoint.latitude + technicianPoint.latitude) / 2,
      (customerPoint.longitude + technicianPoint.longitude) / 2,
    )
        : customerPoint ??
        technicianPoint ??
        const LatLng(18.5204, 73.8567);

    return _sectionCard(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: teal),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Customer & Technician Location',
                  style: TextStyle(
                    color: navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (!hasValidLocation)
            Container(
              height: 150,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 36,
                    color: muted,
                  ),
                  SizedBox(height: 9),
                  Text(
                    'Customer location not available',
                    style: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 280,
                width: double.infinity,
                child: FlutterMap(
                  key: ValueKey(technicianPoint != null),
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: technicianPoint != null ? 11 : 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://api.maptiler.com/maps/streets-v4/256/{z}/{x}/{y}.png?key={key}',
                      additionalOptions: {
                        'key': dotenv.env['MAPTILER_API_KEY'] ?? '',
                      },
                      userAgentPackageName:
                      'com.example.securis_service_app',
                    ),
                    if (_routePoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: teal,
                            strokeWidth: 5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: customerPoint!,
                          width: 45,
                          height: 45,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 42,
                          ),
                        ),
                        if (technicianPoint != null)
                          Marker(
                            point: technicianPoint,
                            width: 45,
                            height: 45,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue,
                              size: 42,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          // Show Distance and ETA only on Technician App
          // Customer location and Technician GPS must be available.
          if (!isAdmin &&
              hasValidLocation &&
              technicianPoint != null)
            _liveDistanceCard(),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 9,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_pin, color: Colors.red, size: 20),
                  SizedBox(width: 5),
                  Text(
                    'Customer',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (technicianPoint != null)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 20,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Technician',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '© MapTiler © OpenStreetMap contributors',
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GET TECHNICIAN LOCATION
  // ============================================================

  Future<void> _getTechnicianCurrentLocation() async {
    try {
      if (!mounted) return;

      setState(() {
        _locationLoading = true;
      });

      bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint('GPS is disabled on this device');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable GPS on your phone.'),
            ),
          );
        }
        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required.'),
            ),
          );
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please allow location permission from app settings.',
              ),
            ),
          );

          await Geolocator.openAppSettings();
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      debugPrint('TECHNICIAN LATITUDE: ${position.latitude}');
      debugPrint('TECHNICIAN LONGITUDE: ${position.longitude}');

      if (!mounted) return;

      setState(() {
        _technicianPosition = position;
        debugPrint(
          'TECHNICIAN POSITION UPDATED: '
              '${position.latitude}, ${position.longitude}',
        );
      });
    } catch (e) {
      debugPrint('TECHNICIAN LOCATION ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to get location: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _locationLoading = false;
        });
      }
    }
  }


  Future<void> _saveTechnicianLocation(Position position) async {
    try {
      final response = await ApiService.post(
        'technician-location/update',
        body: {
          'ticket_id': widget.ticket.backendId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        },
      );

      debugPrint('LOCATION SAVED TO DATABASE: $response');
    } catch (e) {
      debugPrint('LOCATION API ERROR: $e');
    }
  }

  // ============================================================
  // LIVE TECHNICIAN TRACKING
  // ============================================================

  Future<void> _startTechnicianLiveTracking() async {
    try {
      if (!mounted) return;

      debugPrint('========== LIVE GPS START ==========');

      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint('GPS SERVICE DISABLED');
        _showMessage('Please enable GPS on your phone.');
        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('LOCATION PERMISSION DENIED');
        _showMessage('Location permission is required.');
        return;
      }

      await _positionSubscription?.cancel();

      const LocationSettings settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
            (Position position) {
          if (!mounted) return;

          debugPrint(
            'LIVE TECHNICIAN LOCATION: '
                '${position.latitude}, ${position.longitude}',
          );

          setState(() {
            _technicianPosition = position;

          });
          _saveTechnicianLocation(position);
          _loadTechnicianRoute(
            LatLng(position.latitude, position.longitude),
          );
        },
        onError: (error) {
          debugPrint('LIVE GPS STREAM ERROR: $error');
        },
      );

      debugPrint('TECHNICIAN LIVE TRACKING STARTED');
    } catch (e) {
      debugPrint('LIVE TRACKING FAILED: $e');

      _showMessage('Unable to start live tracking: $e');
    }
  }

  // ============================================================
  // ROAD ROUTE
  // ============================================================

  Future<void> _loadTechnicianRoute(LatLng technicianPoint) async {
    final latitude = widget.ticket.latitude;
    final longitude = widget.ticket.longitude;

    if (latitude == null || longitude == null) {
      debugPrint('ROUTE ERROR: Customer location not available.');
      return;
    }

    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      debugPrint('ROUTE ERROR: Invalid customer coordinates.');
      return;
    }
    if (_routeLoading) {
      _pendingRoutePoint = technicianPoint;
      debugPrint('ROUTE: Latest location queued.');
      return;
    }

    _routeLoading = true;

    LatLng? currentPoint = technicianPoint;

    try {
      while (currentPoint != null && mounted) {
        _pendingRoutePoint = null;

        debugPrint('========== ROAD ROUTE API START ==========');
        debugPrint(
          'TECHNICIAN: ${currentPoint.latitude}, ${currentPoint.longitude}',
        );
        debugPrint('CUSTOMER: $latitude, $longitude');

        final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
              '${currentPoint.longitude},${currentPoint.latitude};'
              '$longitude,$latitude'
              '?overview=full&geometries=geojson',
        );

        final response = await http.get(url).timeout(
          const Duration(seconds: 20),
        );

        debugPrint('ROUTE API STATUS: ${response.statusCode}');

        if (response.statusCode != 200) {
          throw Exception('Route API failed: ${response.statusCode}');
        }

        final responseData = jsonDecode(response.body);

        if (responseData['code'] != 'Ok') {
          throw Exception('No road route found.');
        }

        final routes = responseData['routes'];

        if (routes == null || routes.isEmpty) {
          throw Exception('Route data is empty.');
        }

        final route = routes[0];

        // OSRM distance meters
        final distanceMeters = (route['distance'] as num).toDouble();

        // OSRM duration seconds
        final durationSeconds = (route['duration'] as num).toDouble();

        final distanceKm = distanceMeters / 1000;
        final durationMinutes = durationSeconds / 60;

        final coordinates =
        route['geometry']['coordinates'] as List;

        final points = coordinates.map<LatLng>((coordinate) {
          return LatLng(
            (coordinate[1] as num).toDouble(),
            (coordinate[0] as num).toDouble(),
          );
        }).toList();

        if (!mounted) return;

        setState(() {
          _routePoints = points;
          _remainingDistanceKm = distanceKm;
          _remainingDurationMinutes = durationMinutes;
        });

        debugPrint('========== ROAD ROUTE SUCCESS ==========');
        debugPrint('REMAINING DISTANCE: ${distanceKm.toStringAsFixed(2)} KM');
        debugPrint(
          'ESTIMATED TIME: ${durationMinutes.toStringAsFixed(1)} MINUTES',
        );
        debugPrint('ROUTE POINTS: ${points.length}');
        currentPoint = _pendingRoutePoint;
      }
    } catch (e) {
      debugPrint('ROAD ROUTE ERROR: $e');
    } finally {
      _routeLoading = false;
      final pendingPoint = _pendingRoutePoint;
      _pendingRoutePoint = null;

      if (mounted && pendingPoint != null) {
        _loadTechnicianRoute(pendingPoint);
      }
    }
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: background,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: teal,
          secondary: teal,
          surface: Colors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 68,
          titleSpacing: 18,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ticket Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ticket.id,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              // Ticket header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [navyDark, navy, Color(0xFF24516D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'REPAIR REQUEST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.build_circle_outlined,
                          color: Colors.white.withValues(alpha: 0.75),
                          size: 25,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      ticket.issue,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _badge(ticket.priority),
                        _badge(_status),
                      ],
                    ),
                  ],
                ),
              ),

              // Customer details
              _sectionTitle('Customer Details', Icons.person_outline_rounded),
              _sectionCard(
                child: Column(
                  children: [
                    _readOnlyField(
                      'Customer',
                      ticket.customer,
                      Icons.person_outline,
                    ),
                    _readOnlyField(
                      'Property',
                      ticket.property,
                      Icons.location_on_outlined,
                    ),
                    _readOnlyField(
                      'Created',
                      ticket.created,
                      Icons.calendar_today_outlined,
                    ),
                    _readOnlyField(
                      'Problem Description',
                      ticket.description,
                      Icons.description_outlined,
                    ),
                  ],
                ),
              ),

              _customerLocationMap(),

              // Assignment
              _sectionTitle(
                'Assignment',
                Icons.assignment_ind_outlined,
              ),
              _sectionCard(
                child: isAdmin
                    ? DropdownButtonFormField<String>(
                  value: widget.technicianNames.contains(_assignedTo)
                      ? _assignedTo
                      : 'Unassigned',
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: 'Assign Technician',
                    icon: Icons.engineering_outlined,
                  ),
                  items: [
                    'Unassigned',
                    ...widget.technicianNames.where(
                          (name) => name != 'Unassigned',
                    ),
                  ].map((name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (_saving ||
                      widget.ticket.status == 'In Progress' ||
                      widget.ticket.status == 'Resolved')
                      ? null
                      : (value) {
                    if (value == null) return;

                    if (value == 'Unassigned' &&
                        widget.ticket.assignedTo !=
                            'Unassigned' &&
                        widget.ticket.assignedTo.isNotEmpty) {
                      _showMessage(
                        'Unassign is not supported by the current backend API.',
                        backgroundColor: Colors.orange,
                      );
                      return;
                    }

                    setState(() {
                      _assignedTo = value;

                      if (value != 'Unassigned' &&
                          _status == 'Open') {
                        _status = 'Assigned';
                      } else if (value == 'Unassigned' &&
                          _status == 'Assigned') {
                        _status = 'Open';
                      }
                    });
                  },
                )
                    : _readOnlyField(
                  'Assigned Technician',
                  ticket.assignedTo,
                  Icons.engineering_outlined,
                ),
              ),

              // Service visit
              _sectionTitle(
                'Service Visit',
                Icons.calendar_month_outlined,
              ),
              _serviceVisitSection(),

              // Work status
              _sectionTitle(
                'Work Status',
                Icons.track_changes_rounded,
              ),
              _sectionCard(
                child: isAdmin &&
                    (widget.ticket.status == 'Open' ||
                        widget.ticket.status == 'Assigned')
                    ? DropdownButtonFormField<String>(
                  value: _status == 'Assigned' ? 'Assigned' : 'Open',
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: 'Update Status',
                    icon: Icons.flag_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Open',
                      child: Text('Open'),
                    ),
                    DropdownMenuItem(
                      value: 'Assigned',
                      child: Text('Assigned'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                    if (value == null) return;

                    if (value == 'Assigned' &&
                        (_assignedTo == 'Unassigned' ||
                            _assignedTo.isEmpty)) {
                      _showMessage(
                        'Assign a technician before setting status to Assigned.',
                        backgroundColor: Colors.orange,
                      );
                      return;
                    }

                    if (value == 'Open' &&
                        _assignedTo != 'Unassigned' &&
                        _assignedTo.isNotEmpty) {
                      _showMessage(
                        'Unassign is not supported by the current backend API.',
                        backgroundColor: Colors.orange,
                      );
                      return;
                    }

                    setState(() {
                      _status = value;
                    });
                  },
                )
                    : _readOnlyField(
                  'Current Status',
                  _status,
                  Icons.track_changes,
                ),
              ),

              // Work notes
              _sectionTitle('Visit Notes', Icons.edit_note_rounded),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                enabled: !_saving,
                decoration: _inputDecoration(
                  label: 'Work Notes',
                  hint:
                  'Enter inspection details, work performed, or observations...',
                  icon: Icons.notes_rounded,
                  alignLabelWithHint: true,
                ),
              ),

              // Photos
              _sectionTitle(
                'Work Photos',
                Icons.photo_library_outlined,
              ),
              _sectionCard(
                child: Column(
                  children: [
                    _outlinedButton(
                      label: 'Select Photos',
                      icon: Icons.add_a_photo_outlined,
                      onPressed: (_saving || _scheduling)
                          ? null
                          : _pickPhotos,
                    ),
                    if (_photoPaths.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _photoPaths.length,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final path = _photoPaths[index];
                          final isRemote = path.startsWith('http://') ||
                              path.startsWith('https://');

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: isRemote
                                    ? Image.network(
                                  path,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      color: background,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        color: muted,
                                      ),
                                    );
                                  },
                                )
                                    : Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      color: background,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        color: muted,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 3,
                                right: 3,
                                child: IconButton(
                                  onPressed: _saving
                                      ? null
                                      : () => _removePhoto(index),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: navy.withValues(
                                      alpha: 0.75,
                                    ),
                                    minimumSize: const Size(30, 30),
                                    maximumSize: const Size(30, 30),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // Resolution
              _sectionTitle('Resolution', Icons.task_alt_rounded),
              TextFormField(
                controller: _resolutionController,
                maxLines: 4,
                enabled: !_saving,
                decoration: _inputDecoration(
                  label: 'Resolution Details',
                  hint: 'Explain how the issue was fixed...',
                  icon: Icons.check_circle_outline,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (_status == 'Resolved' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Resolution is required to resolve the ticket';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 26),

              _primaryButton(
                label: 'Save Work Details',
                icon: Icons.save_outlined,
                onPressed: _saving ? null : _saveWork,
                loading: _saving,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// COMPLETE VISIT DIALOG
// ============================================================

class _CompleteVisitDialog extends StatefulWidget {
  const _CompleteVisitDialog({
    required this.initialResolution,
  });

  final String initialResolution;

  @override
  State<_CompleteVisitDialog> createState() =>
      _CompleteVisitDialogState();
}

class _CompleteVisitDialogState extends State<_CompleteVisitDialog> {
  static const Color navy = Color(0xFF172B4D);
  static const Color teal = Color(0xFF16B8A6);

  late final TextEditingController _resolutionController;

  @override
  void initState() {
    super.initState();

    _resolutionController = TextEditingController(
      text: widget.initialResolution,
    );
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  void _complete() {
    final resolution = _resolutionController.text.trim();

    if (resolution.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter resolution details.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(resolution);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(Icons.task_alt_rounded, color: teal),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Complete Service Visit',
              style: TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: TextField(
        controller: _resolutionController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Resolution details',
          hintText: 'Describe the work completed...',
          filled: true,
          fillColor: const Color(0xFFF4F7FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFE7ECF3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: teal,
              width: 1.5,
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Color(0xFF8491A5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _complete,
          style: ElevatedButton.styleFrom(
            backgroundColor: teal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: const Text(
            'Complete',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}