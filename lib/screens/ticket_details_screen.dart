import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../data/technician_store.dart';
import '../models/repair_ticket.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  // Technician live GPS tracking
  StreamSubscription<Position>? _positionSubscription;
  Position? _technicianPosition;
  bool _locationLoading = false;

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
  }

  @override
  void dispose() {
    _notesController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  void _showMessage(
      String message, {
        Color backgroundColor = Colors.red,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

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
      await _getTechnicianCurrentLocation();

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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'open':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF176B60)),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyField(
      String label,
      String value,
      IconData icon,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceVisitSection() {
    final ticket = widget.ticket;
    final isResolved = ticket.status == 'Resolved';
    final hasStarted = ticket.visitStartedAt.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(top: 22),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF176B60),
                ),
                SizedBox(width: 10),
                Text(
                  'Service Visit',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_saving || _scheduling)
                      ? null
                      : _scheduleVisit,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    ticket.scheduledVisit.isEmpty
                        ? 'Schedule Visit'
                        : 'Reschedule Visit',
                  ),
                ),
              ),
            if (!isAdmin && !isResolved && !hasStarted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _startVisit,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Visit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B60),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (!isAdmin && !isResolved && hasStarted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_saving || _completeDialogOpen)
                      ? null
                      : _completeVisit,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Complete Visit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B60),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (isResolved)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Service visit completed'),
                subtitle: Text('This ticket is marked as resolved.'),
              ),
          ],
        ),
      ),
    );
  }



  Widget _customerLocationMap() {
    final latitude = widget.ticket.latitude;
    final longitude = widget.ticket.longitude;
    debugPrint(
      'MAPTILER KEY LOADED: '
          '${dotenv.env['MAPTILER_API_KEY']?.isNotEmpty == true}',
    );
    // Check whether customer coordinates are available.
    final hasValidLocation =
        latitude != null &&
            longitude != null &&
            latitude.isFinite &&
            longitude.isFinite &&
            latitude >= -90 &&
            latitude <= 90 &&
            longitude >= -180 &&
            longitude <= 180;

    return Card(
      margin: const EdgeInsets.only(top: 22),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Color(0xFF176B60),
                ),
                SizedBox(width: 10),
                Text(
                  'Customer Location',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!hasValidLocation)
              Container(
                height: 120,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 35,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Customer location not available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 230,
                  width: double.infinity,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        latitude,
                        longitude,
                      ),
                      initialZoom: 15,
                    ),
                    children: [

                      TileLayer(
                        urlTemplate:
                        'https://api.maptiler.com/maps/streets-v4/256/{z}/{x}/{y}.png?key={key}',
                        additionalOptions: {
                          'key': dotenv.env['MAPTILER_API_KEY'] ?? '',
                        },
                        userAgentPackageName: 'com.example.securis_service_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              latitude,
                              longitude,
                            ),
                            width: 45,
                            height: 45,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),
            const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getTechnicianCurrentLocation() async {
    try {
      if (!mounted) return;

      setState(() {
        _locationLoading = true;
      });

      // Check whether phone GPS is enabled
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

      // Check location permission
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

      // Get current GPS location
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






  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.id),
        backgroundColor: const Color(0xFF176B60),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF176B60),
                    Color(0xFF269688),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REPAIR REQUEST',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket.issue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
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

            _sectionTitle('Customer Details', Icons.person_outline),
            _readOnlyField('Customer', ticket.customer, Icons.person),
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
            _customerLocationMap(),
            _sectionTitle(
              'Assignment',
              Icons.assignment_ind_outlined,
            ),

            if (isAdmin)
              DropdownButtonFormField<String>(
                value: widget.technicianNames.contains(_assignedTo)
                    ? _assignedTo
                    : 'Unassigned',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Assign Technician',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Unassigned',
                  ...widget.technicianNames.where(
                        (name) => name != 'Unassigned',
                  ),
                ].map((name) {
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(name),
                  );
                }).toList(),
                onChanged:
                (_saving ||
                    widget.ticket.status == 'In Progress' ||
                    widget.ticket.status == 'Resolved')
                    ? null
                    : (value) {
                  if (value == null) return;

                  if (value == 'Unassigned' &&
                      widget.ticket.assignedTo != 'Unassigned' &&
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
            else
              _readOnlyField(
                'Assigned Technician',
                ticket.assignedTo,
                Icons.engineering_outlined,
              ),
            _serviceVisitSection(),
            _sectionTitle('Work Status', Icons.track_changes),

            if (isAdmin &&
                (widget.ticket.status == 'Open' ||
                    widget.ticket.status == 'Assigned'))
              DropdownButtonFormField<String>(
                value: _status == 'Assigned' ? 'Assigned' : 'Open',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Update Status',
                  border: OutlineInputBorder(),
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
            else
              _readOnlyField(
                'Current Status',
                _status,
                Icons.track_changes,
              ),
            _sectionTitle('Visit Notes', Icons.edit_note),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              enabled: !_saving,
              decoration: InputDecoration(
                hintText:
                'Enter inspection details, work performed, or observations...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            _sectionTitle(
              'Work Photos',
              Icons.photo_library_outlined,
            ),
            OutlinedButton.icon(
              onPressed: (_saving || _scheduling)
                  ? null
                  : _pickPhotos,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Select Photos'),
            ),

            if (_photoPaths.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                        borderRadius: BorderRadius.circular(10),
                        child: isRemote
                            ? Image.network(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.broken_image,
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
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.broken_image,
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
                            Icons.close,
                            color: Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],

            _sectionTitle('Resolution', Icons.task_alt),
            TextFormField(
              controller: _resolutionController,
              maxLines: 4,
              enabled: !_saving,
              decoration: InputDecoration(
                hintText: 'Explain how the issue was fixed...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveWork,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _saving ? 'Saving...' : 'Save Work Details',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF176B60),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    final color = _statusColor(text);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

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
      title: const Text('Complete Service Visit'),
      content: TextField(
        controller: _resolutionController,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Resolution details',
          hintText: 'Describe the work completed...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _complete,
          child: const Text('Complete'),
        ),
      ],
    );
  }
}