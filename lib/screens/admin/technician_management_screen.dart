
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
  static const Color primaryColor = Color(0xFF2457C5);

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
          primaryColor: primaryColor,
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
      final sameTechnician = technician != null &&
          item['id'] == technician['id'];

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
          title: const Text('Deactivate Technician?'),
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
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving ? null : () => _showTechnicianDialog(),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Technician'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Technician Management',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF18233B),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Add, edit and manage your service team.',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EDFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${widget.technicians.length}',
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          if (widget.technicians.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No technicians added yet.'),
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

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color(0xFFE6EDFF),
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  technician['specialization'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            enabled: !isSaving,
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
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Edit'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              if (isActive)
                                const PopupMenuItem(
                                  value: 'deactivate',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.person_off_outlined,
                                      color: Colors.red,
                                    ),
                                    title: Text('Deactivate'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _infoRow(
                        Icons.email_outlined,
                        technician['email'] ?? 'No email',
                      ),

                      const SizedBox(height: 8),

                      _infoRow(
                        Icons.phone_outlined,
                        (technician['phone'] ?? '').isEmpty
                            ? 'No phone number'
                            : technician['phone']!,
                      ),

                      const Divider(height: 26),

                      Row(
                        children: [
                          Expanded(
                            child: _jobCount(
                              'Active Jobs',
                              assignedJobs,
                              Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _jobCount(
                              'Resolved',
                              resolvedJobs,
                              Colors.green,
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
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF344054)),
          ),
        ),
      ],
    );
  }

  Widget _jobCount(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }
}

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
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEditing ? 'Edit Technician' : 'Add Technician',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _input(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 14),

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

                const SizedBox(height: 14),

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

                const SizedBox(height: 14),

                _input(
                  controller: _specializationController,
                  label: 'Specialization',
                  icon: Icons.build_outlined,
                ),

                if (!widget.isEditing) ...[
                  const SizedBox(height: 14),

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
              ],
            ),
          ),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: Text(
            widget.isEditing ? 'Save Changes' : 'Add Technician',
          ),
        ),
      ],
    );
  }
}
