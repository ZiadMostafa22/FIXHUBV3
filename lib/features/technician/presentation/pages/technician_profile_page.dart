import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';
import 'package:car_maintenance_system_new/core/models/user_model.dart' as app_models;

class TechnicianProfilePage extends ConsumerStatefulWidget {
  const TechnicianProfilePage({super.key});

  @override
  ConsumerState<TechnicianProfilePage> createState() => _TechnicianProfilePageState();
}

class _TechnicianProfilePageState extends ConsumerState<TechnicianProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  DateTime? _accountCreatedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        // Load bookings for stats
        ref.read(bookingViewModelProvider.notifier).loadBookings(user.id, role: 'technician');
        // Load user data for editing
        _loadUserData();
        _loadUserFullData();
      }
    });
  }

  void _loadUserData() {
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
    }
  }

  Future<void> _loadUserFullData() async {
    try {
      final user = ref.read(authViewModelProvider).user;
      if (user == null) return;

      final doc = await FirebaseService.usersCollection.doc(user.id).get();
      if (doc.exists) {
        final userData = app_models.UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        if (mounted) {
          setState(() {
            _accountCreatedDate = userData.createdAt;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authViewModelProvider).user;
      if (user == null) throw 'User not found';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_updated'.tr(ref)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_updating_profile'.tr(ref)}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final bookingState = ref.watch(bookingViewModelProvider);
    final user = authState.user;

    // Calculate real stats from bookings - ONLY jobs where technician is explicitly assigned
    final completedJobs = bookingState.bookings.where((b) =>
      b.status == BookingStatus.completed &&
      b.assignedTechnicians != null && 
      b.assignedTechnicians!.isNotEmpty && 
      b.assignedTechnicians!.contains(user?.id)
    ).length;

    final totalHoursWorked = bookingState.bookings
        .where((b) => 
          b.status == BookingStatus.completed &&
          b.assignedTechnicians != null && 
          b.assignedTechnicians!.isNotEmpty && 
          b.assignedTechnicians!.contains(user?.id)
        )
        .fold<double>(0, (sum, booking) => sum + booking.hoursWorked);

    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr(ref)),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData(); // Reset to original values
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'T',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Profile Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'personal_info'.tr(ref),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (!_isEditing)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                setState(() => _isEditing = true);
                              },
                              tooltip: 'edit_information'.tr(ref),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'full_name'.tr(ref),
                          prefixIcon: const Icon(Icons.person),
                          border: const OutlineInputBorder(),
                          filled: !_isEditing,
                          fillColor: _isEditing ? null : Colors.grey.shade100,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'name_required'.tr(ref);
                          }
                          if (value.trim().length < 2) {
                            return 'name_min_length'.tr(ref);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field (Read-only)
                      TextFormField(
                        initialValue: user?.email ?? '',
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'email'.tr(ref),
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          helperText: 'email_cannot_change'.tr(ref),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'phone'.tr(ref),
                          prefixIcon: const Icon(Icons.phone),
                          border: const OutlineInputBorder(),
                          filled: !_isEditing,
                          fillColor: _isEditing ? null : Colors.grey.shade100,
                          hintText: '+1 (555) 123-4567',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'phone_required'.tr(ref);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.build, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'technician'.tr(ref).toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Save Button (shown when editing)
                      if (_isEditing) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveProfile,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isLoading ? 'saving'.tr(ref) : 'save_changes'.tr(ref)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Performance Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'performance_summary'.tr(ref),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            context,
                            'jobs_completed'.tr(ref),
                            completedJobs.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildStatItem(
                            context,
                            'hours_worked'.tr(ref),
                            '${totalHoursWorked.toStringAsFixed(0)}h',
                            Icons.schedule,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Account Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'account_info'.tr(ref),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.blue),
                        title: Text('member_since'.tr(ref)),
                        subtitle: Text(
                          _accountCreatedDate != null
                               ? DateFormat('MMMM dd, yyyy').format(_accountCreatedDate!)
                               : 'loading'.tr(ref),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text('sign_out'.tr(ref)),
                        content: Text('sign_out_confirm'.tr(ref)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text('cancel'.tr(ref)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Close dialog first
                              Navigator.pop(dialogContext);
                              // Small delay to ensure dialog is fully closed
                              await Future.delayed(const Duration(milliseconds: 100));
                              // Then sign out - router will handle navigation
                              if (mounted) {
                                await ref.read(authViewModelProvider.notifier).signOut();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text('sign_out'.tr(ref)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: Text('sign_out'.tr(ref)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
