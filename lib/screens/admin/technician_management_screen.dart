
import 'package:flutter/material.dart';

import '../../models/repair_ticket.dart';
import '../../services/api_service.dart';

class TechnicianManagementScreen extends StatefulWidget {
  const TechnicianManagementScreen({
    super.key,
    required this.tickets,
    required this.technicians,
    required this.onChanged,
  });

  final List<RepairTicket> tickets;
  final List<Map<String, String>> technicians;
  final VoidCallback onChanged;

  @override
  State<TechnicianManagementScreen> createState() =>
      _TechnicianManagementScreenState();
}

class _TechnicianManagementScreenState
    extends State<TechnicianManagementScreen> {
  static const Color primaryColor = Color(0xFF172B4D);
  static const Color accentColor = Color(0xFF16B8A6);
  static const Color backgroundColor = Color(0xFFF4F7FB);
  static const Color textColor = Color(0xFF18243A);
  static const Color mutedColor = Color(0xFF718096);

  bool isSaving = false;

  // ADD / EDIT TECHNICIAN
  Future<void> _showTechnicianDialog({
    Map<String, String>? technician,
  }) async {
    if (isSaving) return;

    final isEditing = technician != null;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _TechnicianFormDialog(
          technician: technician,
          isEditing: isEditing,
          primaryColor: accentColor,
        );
      },
    );

    if (result == null || !mounted) return;

    final name = result['name']!.trim();
    final email = result['email']!.trim();
    final phone = result['phone']!.trim();
    final specialization = result['specialization']!.trim();
    final password = result['password']?.trim() ?? '';

    final duplicate = widget.technicians.any((item) {
      final sameTechnician =
          technician != null && item['id'] == technician['id'];

      if (sameTechnician) return false;

      final sameName =
          (item['name'] ?? '').toLowerCase() == name.toLowerCase();

      final sameEmail =
          (item['email'] ?? '').toLowerCase() == email.toLowerCase();

      return sameName || sameEmail;
    });

    if (duplicate) {
      _showMessage('Technician name or email already exists.');
      return;
    }

    if (name.isEmpty) {
      _showMessage('Name is required.');
      return;
    }

    if (!isEditing && password.length < 10) {
      _showMessage('Password must be at least 10 characters.');
      return;
    }

    final Map<String, dynamic> body = {
      'name': name,
      'phone': phone,
    };

    if (!isEditing) {
      body['email'] = email;
      body['password'] = password;
    }

    setState(() {
      isSaving = true;
    });

    try {
      late Map<String, dynamic> response;

      if (isEditing) {
        final technicianId = technician['id'];

        if (technicianId == null || technicianId.isEmpty) {
          throw Exception('Technician ID not found.');
        }

        response = await ApiService.patch(
          'technicians/$technicianId',
          body: body,
        );
      } else {
        response = await ApiService.post(
          'technicians',
          body: body,
        );
      }

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'Technician save failed.',
        );
      }

      if (!mounted) return;

      widget.onChanged();

      _showMessage(
        isEditing
            ? 'Technician updated successfully.'
            : 'Technician added successfully.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Technician API Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // DEACTIVATE TECHNICIAN
  Future<void> _deactivateTechnician(
      Map<String, String> technician,
      ) async {
    final name = technician['name'] ?? 'Technician';
    final technicianId = technician['id'];

    if (technicianId == null || technicianId.isEmpty) {
      _showMessage('Technician ID not found.');
      return;
    }

    final alreadyInactive = technician['is_active'] == '0';

    if (alreadyInactive) {
      _showMessage('This technician is already inactive.');
      return;
    }

    final activeJobs = widget.tickets.where((ticket) {
      return ticket.assignedTo == name &&
          ticket.status != 'Resolved' &&
          ticket.status != 'Cancelled';
    }).length;

    if (activeJobs > 0) {
      _showMessage(
        '$name has $activeJobs active job(s). Reassign them before deactivating.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Deactivate Technician?',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Do you want to deactivate $name? This technician will no longer be active.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      isSaving = true;
    });

    try {
      final response = await ApiService.patch(
        'technicians/$technicianId',
        body: {
          'is_active': false,
        },
      );

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'Unable to deactivate technician.',
        );
      }

      if (!mounted) return;

      widget.onChanged();
      _showMessage('$name deactivated successfully.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Deactivate Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // MAIN UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving ? null : () => _showTechnicianDialog(),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Add Technician',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
          children: [
            // HEADER
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Team Management',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Manage your service technicians',
                        style: TextStyle(
                          fontSize: 13,
                          color: mutedColor,
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
                    Icons.groups_2_outlined,
                    color: accentColor,
                    size: 25,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // TEAM SUMMARY
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Technicians',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.technicians.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Your service team',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 65,
                    width: 65,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.engineering_outlined,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // SECTION TITLE
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Technicians',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                Text(
                  '${widget.technicians.length} Members',
                  style: const TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // EMPTY STATE
            if (widget.technicians.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE8EDF4),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      size: 48,
                      color: mutedColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No technicians yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add your first technician to get started.',
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
              ...widget.technicians.map((technician) {
                final name = technician['name'] ?? 'Unknown';
                final isActive = technician['is_active'] != '0';

                final assignedJobs = widget.tickets.where((ticket) {
                  return ticket.assignedTo == name &&
                      ticket.status != 'Resolved' &&
                      ticket.status != 'Cancelled';
                }).length;

                final resolvedJobs = widget.tickets.where((ticket) {
                  return ticket.assignedTo == name &&
                      ticket.status == 'Resolved';
                }).length;

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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TECHNICIAN PROFILE
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(0xFFE5F5F3),
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: accentColor,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    technician['specialization'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: mutedColor,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFFE5F7EF)
                                          : const Color(0xFFFFEEEE),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isActive ? 'ACTIVE' : 'INACTIVE',
                                      style: TextStyle(
                                        color: isActive
                                            ? const Color(0xFF15945B)
                                            : Colors.red.shade700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              enabled: !isSaving,
                              icon: const Icon(
                                Icons.more_vert,
                                color: mutedColor,
                              ),
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _showTechnicianDialog(
                                    technician: technician,
                                  );
                                } else if (action == 'deactivate') {
                                  _deactivateTechnician(technician);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 19,
                                      ),
                                      SizedBox(width: 10),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                if (isActive)
                                  const PopupMenuItem(
                                    value: 'deactivate',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person_off_outlined,
                                          color: Colors.red,
                                          size: 19,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Deactivate'),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        const Divider(
                          height: 1,
                          color: Color(0xFFEDF0F5),
                        ),
                        const SizedBox(height: 15),

                        // CONTACT DETAILS
                        _infoRow(
                          Icons.email_outlined,
                          technician['email'] ?? 'No email',
                        ),
                        const SizedBox(height: 11),
                        _infoRow(
                          Icons.phone_outlined,
                          (technician['phone'] ?? '').isEmpty
                              ? 'No phone number'
                              : technician['phone']!,
                        ),

                        const SizedBox(height: 17),

                        // JOB COUNTS
                        Row(
                          children: [
                            Expanded(
                              child: _jobCount(
                                'Active Jobs',
                                assignedJobs,
                                const Color(0xFFEAF2FF),
                                primaryColor,
                                Icons.assignment_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _jobCount(
                                'Resolved',
                                resolvedJobs,
                                const Color(0xFFE5F7EF),
                                const Color(0xFF15945B),
                                Icons.check_circle_outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // CONTACT INFORMATION ROW
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        const SizedBox(width: 2),
        Icon(
          icon,
          size: 17,
          color: accentColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
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

  // JOB COUNT CARD
  Widget _jobCount(
      String label,
      int count,
      Color cardColor,
      Color foregroundColor,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: foregroundColor,
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF526078),
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
}

// ============================================================
// ADD / EDIT TECHNICIAN FORM DIALOG
// ============================================================

class _TechnicianFormDialog extends StatefulWidget {
  const _TechnicianFormDialog({
    required this.technician,
    required this.isEditing,
    required this.primaryColor,
  });

  final Map<String, String>? technician;
  final bool isEditing;
  final Color primaryColor;

  @override
  State<_TechnicianFormDialog> createState() =>
      _TechnicianFormDialogState();
}

class _TechnicianFormDialogState extends State<_TechnicianFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _specializationController;
  late final TextEditingController _passwordController;

  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();

    final technician = widget.technician;

    _nameController = TextEditingController(
      text: technician?['name'] ?? '',
    );

    _emailController = TextEditingController(
      text: technician?['email'] ?? '',
    );

    _phoneController = TextEditingController(
      text: technician?['phone'] ?? '',
    );

    _specializationController = TextEditingController(
      text: technician?['specialization'] ?? '',
    );

    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // FORM INPUT FIELD
  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      validator: validator ??
              (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF16B8A6),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFFE1E7EF),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFFE1E7EF),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFF16B8A6),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // SUBMIT FORM
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'specialization': _specializationController.text.trim(),
      'password': _passwordController.text.trim(),
    });
  }

  // FORM UI
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DIALOG HEADER
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F5F3),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.engineering_outlined,
                        color: Color(0xFF16B8A6),
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditing
                                ? 'Edit Technician'
                                : 'Add Technician',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF172B4D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Enter technician details below',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // NAME
                _input(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 15),

                // EMAIL
                _input(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: widget.isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }

                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim())) {
                      return 'Enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // PHONE
                _input(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone Number is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // SPECIALIZATION
                _input(
                  controller: _specializationController,
                  label: 'Specialization',
                  icon: Icons.build_outlined,
                ),

                // PASSWORD
                if (!widget.isEditing) ...[
                  const SizedBox(height: 15),
                  _input(
                    controller: _passwordController,
                    label: 'Password (minimum 10 characters)',
                    icon: Icons.lock_outline,
                    obscureText: _hidePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _hidePassword = !_hidePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }

                      if (value.length < 10) {
                        return 'Password must be at least 10 characters';
                      }

                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 25),

                // ACTION BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF526078),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          side: const BorderSide(
                            color: Color(0xFFDCE3EC),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16B8A6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.isEditing
                              ? 'Save Changes'
                              : 'Add Technician',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
}
