
class RepairTicket {
  RepairTicket({
    required this.id,
    required this.backendId,
    required this.customer,
    required this.property,
    required this.issue,
    required this.priority,
    required this.status,
    required this.assignedTo,
    required this.created,
    required this.description,
    this.notes = '',
    this.resolution = '',
    this.photoPaths = const [],
    this.scheduledVisit = '',
    this.visitStartedAt = '',
    this.visitCompletedAt = '',
    this.latitude,
    this.longitude,
  });

  final String id;
  final int backendId;
  final String customer;
  final String property;
  final String issue;
  final String priority;

  String status;
  String assignedTo;

  final String created;
  final String description;

  String notes;
  String resolution;
  List<String> photoPaths;

  String scheduledVisit;
  String visitStartedAt;
  String visitCompletedAt;

  // Customer location coordinates
  final double? latitude;
  final double? longitude;

  factory RepairTicket.fromJson(Map<String, dynamic> json) {
    final photos = json['photos'];

    return RepairTicket(
      backendId: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      id: (json['ticket_code'] ?? json['id'] ?? '').toString(),
      customer: (json['customer_name'] ?? '').toString(),
      property: (json['property'] ?? '').toString(),
      issue: (json['issue'] ?? '').toString(),
      priority: (json['priority'] ?? 'Medium').toString(),
      status: (json['status'] ?? 'Received').toString(),
      assignedTo: (json['assigned_to'] ?? 'Unassigned').toString(),
      created: (json['created_at'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      notes: (json['work_notes'] ?? '').toString(),
      resolution: (json['resolution'] ?? '').toString(),
      scheduledVisit: (json['scheduled_at'] ?? '').toString(),
      visitStartedAt: (json['visit_started_at'] ?? '').toString(),
      visitCompletedAt: (json['visit_completed_at'] ?? '').toString(),

      // Read customer coordinates from API
      latitude: double.tryParse(
        (json['latitude'] ?? '').toString(),
      ),
      longitude: double.tryParse(
        (json['longitude'] ?? '').toString(),
      ),

      photoPaths: photos is List
          ? photos.map((photo) {
        if (photo is Map) {
          return (photo['url'] ??
              photo['path'] ??
              photo['photo_url'] ??
              '')
              .toString();
        }
        return photo.toString();
      }).where((path) => path.isNotEmpty).toList()
          : [],
    );
  }
}
