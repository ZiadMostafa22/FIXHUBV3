import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';
import 'package:car_maintenance_system_new/core/models/service_item_model.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';

import 'package:car_maintenance_system_new/core/services/notification_service.dart';
import 'package:car_maintenance_system_new/core/repositories/service_repository.dart';
import 'package:car_maintenance_system_new/core/constants/service_items_constants.dart';

/// Read-only stream provider for available services (used by technician)
final availableServicesProvider = StreamProvider<List<ServiceItemEntity>>((ref) {
  return ServiceRepository().getServices();
});

class JobDetailsPage extends ConsumerStatefulWidget {
  final String bookingId;

  const JobDetailsPage({super.key, required this.bookingId});

  @override
  ConsumerState<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends ConsumerState<JobDetailsPage> {
  final List<ServiceItemEntity> _serviceItems = [];
  final _laborCostController = TextEditingController();
  final _technicianNotesController = TextEditingController();
  
  BookingEntity? _booking;
  CarEntity? _car;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookingDetails();
    });
  }

  Future<void> _loadBookingDetails() async {
    try {
      // Try to find booking in current state first (fast path)
      final bookingState = ref.read(bookingViewModelProvider);
      BookingEntity? found = bookingState.bookings
          .where((b) => b.id == widget.bookingId)
          .firstOrNull;

      // If not in state yet, reload from server
      if (found == null) {
        final user = ref.read(authViewModelProvider).user;
        if (user != null) {
          await ref
              .read(bookingViewModelProvider.notifier)
              .loadBookings(user.id, role: 'technician');
          if (!mounted) return;
          found = ref
              .read(bookingViewModelProvider)
              .bookings
              .where((b) => b.id == widget.bookingId)
              .firstOrNull;
        }
      }

      if (!mounted) return;
      if (found == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load job details. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
        return;
      }

      _booking = found;

      // Load car
      final carState = ref.read(carViewModelProvider);
      _car = carState.cars
          .where((c) => c.id == _booking!.carId)
          .firstOrNull;
      if (_car == null && _booking!.carId.isNotEmpty) {
        ref
            .read(carViewModelProvider.notifier)
            .getCarById(_booking!.carId)
            .then((fetchedCar) {
          if (mounted && fetchedCar != null) {
            setState(() => _car = fetchedCar);
          }
        });
      }

      // Safely load service items — BookingEntity.serviceItems uses domain
      // ServiceItemEntity which may differ from core/models ServiceItemEntity.
      // Convert via map to be safe.
      if (_booking!.serviceItems != null &&
          _booking!.serviceItems!.isNotEmpty) {
        _serviceItems.clear();
        for (final raw in _booking!.serviceItems!) {
          try {
            // raw is domain ServiceItemEntity; convert via map round-trip
            final map = <String, dynamic>{
              'id': raw.id,
              'name': raw.name,
              'type': raw.type.toString().split('.').last,
              'price': raw.price,
              'quantity': raw.quantity,
              'description': raw.description,
            };
            _serviceItems.add(ServiceItemEntity.fromMap(map));
          } catch (_) {
            // skip malformed item
          }
        }
      }

      // Set labor cost
      if (_booking!.laborCost != null) {
        _laborCostController.text =
            _booking!.laborCost!.toStringAsFixed(2);
      } else if (_booking!.status == BookingStatus.inProgress) {
        final defaultLabor = ServiceItemsConstants.getDefaultLaborCost(
            _booking!.maintenanceType);
        _laborCostController.text = defaultLabor.toStringAsFixed(2);
      }

      if (_booking!.technicianNotes != null) {
        _technicianNotesController.text = _booking!.technicianNotes!;
      }
    } catch (e, stack) {
      debugPrint('❌ _loadBookingDetails error: $e\n$stack');
    } finally {
      // Always rebuild — even on error, so we don't hang on loading screen
      if (mounted) setState(() {});
    }
  }

  Future<Map<String, String>> _getUserInfo(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return <String, String>{
          'name': data['name']?.toString() ?? 'Unknown',
          'phone': data['phone']?.toString() ?? 'N/A',
        };
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }

    return <String, String>{'name': 'Unknown', 'phone': 'N/A'};
  }

  @override
  void dispose() {
    // Auto-save on exit if there are unsaved changes
    if (_hasUnsavedChanges && _booking?.status == BookingStatus.inProgress) {
      _saveProgressSilently();
    }
    _laborCostController.dispose();
    _technicianNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final subtotal = _calculateSubtotal();
    final tax = subtotal * 0.10; // 10% tax
    final total = subtotal + tax;

    // Calculate hours worked if job is completed
    final hoursWorked = _booking!.hoursWorked;

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges && _booking!.status == BookingStatus.inProgress) {
          await _saveProgressSilently();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Job'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMaintenanceTypeName(_booking!.maintenanceType),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<Map<String, String>>(
                        future: _getUserInfo(_booking!.userId),
                        builder: (context, snapshot) {
                          final customerName = snapshot.data?['name'] ?? 'Loading...';
                          return Text('Customer: $customerName');
                        },
                      ),
                      if (_car != null) ...[
                        Text('Car: ${_car!.make} ${_car!.model}'),
                        Text('Plate: ${_car!.licensePlate}'),
                      ],
                      Text('Date: ${DateFormat('MMM dd, yyyy').format(_booking!.scheduledDate)}'),
                      Text('Time: ${_booking!.timeSlot}'),
                      if (_booking!.description != null && _booking!.description!.isNotEmpty)
                        Text('Description: ${_booking!.description}'),
                      if (_booking!.startedAt != null)
                        Text('Started: ${DateFormat('MMM dd, HH:mm').format(_booking!.startedAt!)}'),
                      if (_booking!.completedAt != null) ...[
                        Text('Completed: ${DateFormat('MMM dd, HH:mm').format(_booking!.completedAt!)}'),
                        Text('Hours Worked: ${hoursWorked.toStringAsFixed(2)}h',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Service Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service Items & Parts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: _booking!.status == BookingStatus.inProgress ? _addServiceItem : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_serviceItems.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.build, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'No items added yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          if (_booking!.status == BookingStatus.inProgress)
                            TextButton.icon(
                              onPressed: _addServiceItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._serviceItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(_getItemIcon(item.type)),
                      ),
                      title: Text(
                        item.name,
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type: ${item.type.toString().split('.').last}'),
                          Text('Price: \$${item.price.toStringAsFixed(2)} x ${item.quantity}'),
                          if (item.description != null && item.description!.isNotEmpty)
                            Text('Note: ${item.description}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${item.totalPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          if (_booking!.status == BookingStatus.inProgress)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeServiceItem(index),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Labor Cost
              Text(
                'Labor Cost',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _laborCostController,
                enabled: _booking!.status == BookingStatus.inProgress,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Labor Cost',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  hintText: '0.00',
                ),
                onChanged: (value) {
                  setState(() {
                    _hasUnsavedChanges = true;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Technician Notes
              Text(
                'Technician Notes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _technicianNotesController,
                enabled: _booking!.status == BookingStatus.inProgress,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Add any notes about the service...',
                ),
                onChanged: (value) {
                  setState(() {
                    _hasUnsavedChanges = true;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Invoice Summary
              Card(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal:',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white70 
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            '\$${subtotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white70 
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tax (10%):',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white70 
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            '\$${tax.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white70 
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white 
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white 
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (_booking!.status == BookingStatus.pending)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startJob,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Job'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),

              if (_booking!.status == BookingStatus.inProgress)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveProgress,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Progress'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveAndComplete,
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Complete Job',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateSubtotal() {
    double itemsTotal = _serviceItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    double laborCost = double.tryParse(_laborCostController.text) ?? 0;
    return itemsTotal + laborCost;
  }

  void _addServiceItem() {
    showDialog(
      context: context,
      builder: (context) => _ServiceItemDialog(
        maintenanceCategory: _booking!.maintenanceType.toString().split('.').last,
        onAddAll: (items) {
          setState(() {
            _serviceItems.addAll(items);
            _hasUnsavedChanges = true;
          });
        },
      ),
    );
  }

  void _removeServiceItem(int index) {
    setState(() {
      _serviceItems.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _startJob() async {
    final user = ref.read(authViewModelProvider).user;
    
    // Assign technician to job when starting
    final assignedTechs = _booking!.assignedTechnicians ?? [];
    if (user != null && !assignedTechs.contains(user.id)) {
      assignedTechs.add(user.id);
    }
    
    final success = await ref.read(bookingViewModelProvider.notifier).updateBooking(
      _booking!.id,
      {
        'status': BookingStatus.inProgress.toString().split('.').last,
        'startedAt': Timestamp.now(),
        'assignedTechnicians': assignedTechs,
        'updatedAt': Timestamp.now(),
      },
    );

    if (mounted) {
      if (success) {
        // Reload bookings from Firebase
        final user = ref.read(authViewModelProvider).user;
        if (user != null) {
          await ref.read(bookingViewModelProvider.notifier).loadBookings(user.id, role: 'technician');
        }
        
        if (mounted) {
          _loadBookingDetails();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job started!'), backgroundColor: Colors.green),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start job'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProgress() async {
    final laborCost = double.tryParse(_laborCostController.text) ?? 0;
    final tax = _calculateSubtotal() * 0.10;

    final success = await ref.read(bookingViewModelProvider.notifier).updateBooking(
      _booking!.id,
      {
        'serviceItems': _serviceItems.map((item) => item.toMap()).toList(),
        'laborCost': laborCost,
        'tax': tax,
        'technicianNotes': _technicianNotesController.text,
        'updatedAt': Timestamp.now(),
      },
    );

    if (mounted) {
      if (success) {
        // Reload bookings from Firebase
        final user = ref.read(authViewModelProvider).user;
        if (user != null) {
          await ref.read(bookingViewModelProvider.notifier).loadBookings(user.id, role: 'technician');
        }
        
        if (mounted) {
          setState(() {
            _hasUnsavedChanges = false;
          });
          _loadBookingDetails();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Progress saved!'), backgroundColor: Colors.green),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save progress'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProgressSilently() async {
    final laborCost = double.tryParse(_laborCostController.text) ?? 0;
    final tax = _calculateSubtotal() * 0.10;

    await ref.read(bookingViewModelProvider.notifier).updateBooking(
      _booking!.id,
      {
        'serviceItems': _serviceItems.map((item) => item.toMap()).toList(),
        'laborCost': laborCost,
        'tax': tax,
        'technicianNotes': _technicianNotesController.text,
        'updatedAt': Timestamp.now(),
      },
    );
  }

  Future<void> _saveAndComplete() async {
    // Validate that service items or labor cost is added
    if (_serviceItems.isEmpty && (_laborCostController.text.isEmpty || double.tryParse(_laborCostController.text) == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one service item or labor cost'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final laborCost = double.tryParse(_laborCostController.text) ?? 0;
    final subtotal = _calculateSubtotal();
    final tax = subtotal * 0.10;
    final totalCost = subtotal + tax;

    final success = await ref.read(bookingViewModelProvider.notifier).updateBooking(
      _booking!.id,
      {
        'serviceItems': _serviceItems.map((item) => item.toMap()).toList(),
        'laborCost': laborCost,
        'tax': tax,
        'totalCost': totalCost, // Add total cost
        'technicianNotes': _technicianNotesController.text,
        'status': BookingStatus.completedPendingPayment.toString().split('.').last,
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
    );

    if (mounted) {
      if (success) {
        // Send service completed notification to customer
        try {
          final carInfo = _car != null 
              ? '${_car!.year} ${_car!.make} ${_car!.model}'
              : 'Your vehicle';
          await NotificationService().sendServiceCompleted(
            userId: _booking!.userId,
            bookingId: _booking!.id,
            carInfo: carInfo,
            totalCost: _calculateSubtotal() * 1.10, // Include tax
          );
          debugPrint('📬 Service completed notification sent to customer');
        } catch (e) {
          debugPrint('⚠️ Failed to send service completed notification: $e');
        }
        
        // Reload bookings to reflect the update
        final user = ref.read(authViewModelProvider).user;
        if (user != null) {
          await ref.read(bookingViewModelProvider.notifier).loadBookings(user.id, role: 'technician');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job completed successfully!'), backgroundColor: Colors.green),
          );
          context.pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete job'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getMaintenanceTypeName(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.regular:
        return 'Regular Maintenance';
      case MaintenanceType.inspection:
        return 'Inspection';
      case MaintenanceType.repair:
        return 'Repair Service';
      case MaintenanceType.emergency:
        return 'Emergency Service';
    }
  }

  IconData _getItemIcon(ServiceItemType type) {
    switch (type) {
      case ServiceItemType.part:
        return Icons.settings;
      case ServiceItemType.labor:
        return Icons.build;
      case ServiceItemType.service:
        return Icons.car_repair;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Multi-item dialog — technician selects multiple items at once
// ─────────────────────────────────────────────────────────────
class _ServiceItemDialog extends ConsumerStatefulWidget {
  final String maintenanceCategory;
  final Function(List<ServiceItemEntity>) onAddAll;

  const _ServiceItemDialog({
    required this.maintenanceCategory,
    required this.onAddAll,
  });

  @override
  ConsumerState<_ServiceItemDialog> createState() => _ServiceItemDialogState();
}

/// Tracks per-item selection state inside the dialog
class _ItemSelection {
  final ServiceItemEntity item;
  bool selected;
  int quantity;
  _ItemSelection({required this.item, required this.selected, required this.quantity});
}

class _ServiceItemDialogState extends ConsumerState<_ServiceItemDialog> {
  List<_ItemSelection> _selections = [];
  bool _initialized = false;

  void _initSelections(List<ServiceItemEntity> items) {
    if (_initialized) return;
    _initialized = true;
    _selections = items
        .map((item) => _ItemSelection(item: item, selected: false, quantity: 1))
        .toList();
  }

  int get _selectedCount => _selections.where((s) => s.selected).length;

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(availableServicesProvider);

    return AlertDialog(
      title: Text('Add Items to Invoice', style: TextStyle(fontSize: 18.sp)),
      contentPadding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 0),
      content: SizedBox(
        width: 0.9.sw,
        height: 0.6.sh,
        child: servicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (allItems) {
            final items = allItems
                .where((s) =>
                    s.category == widget.maintenanceCategory ||
                    s.category == null)
                .toList();

            if (items.isEmpty) {
              return Center(
                child: Text(
                  'No catalog items available for this maintenance type.\nAsk admin to add services.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13.sp),
                ),
              );
            }

            _initSelections(items);

            // Group by type label
            final groups = <String, List<_ItemSelection>>{};
            for (final sel in _selections) {
              final label = sel.item.type.toString().split('.').last;
              groups.putIfAbsent(label, () => []).add(sel);
            }

            return ListView(
              children: [
                for (final entry in groups.entries) ...[
                  // Group header
                  Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 4.h),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  // Items in group
                  for (final sel in entry.value)
                    _ItemRow(
                      sel: sel,
                      onToggle: (v) => setState(() => sel.selected = v),
                      onQtyChanged: (q) => setState(() => sel.quantity = q),
                    ),
                ],
              ],
            );
          },
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
        ),
        ElevatedButton.icon(
          onPressed: _selectedCount == 0
              ? null
              : () {
                  final selected = _selections
                      .where((s) => s.selected)
                      .map((s) => ServiceItemEntity(
                            id: '${DateTime.now().millisecondsSinceEpoch}_${s.item.id}',
                            name: s.item.name,
                            type: s.item.type,
                            price: s.item.price,
                            quantity: s.quantity,
                            description: s.item.description,
                            category: s.item.category,
                          ))
                      .toList();
                  widget.onAddAll(selected);
                  Navigator.pop(context);
                },
          icon: const Icon(Icons.check),
          label: Text(
            _selectedCount == 0
                ? 'Add Selected'
                : 'Add $_selectedCount Item${_selectedCount > 1 ? 's' : ''}',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      ],
    );
  }
}

/// Single row inside the multi-item dialog
class _ItemRow extends StatelessWidget {
  final _ItemSelection sel;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onQtyChanged;

  const _ItemRow({
    required this.sel,
    required this.onToggle,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(vertical: 3.h),
      decoration: BoxDecoration(
        color: sel.selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.07)
            : null,
        border: Border.all(
          color: sel.selected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: sel.selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => onToggle(!sel.selected),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          child: Row(
            children: [
              Checkbox(
                value: sel.selected,
                onChanged: (v) => onToggle(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sel.item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                    Text(
                      '${sel.item.price.toStringAsFixed(0)} EGP / unit',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (sel.selected) ...[
                SizedBox(width: 8.w),
                // Quantity controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: sel.quantity > 1
                          ? () => onQtyChanged(sel.quantity - 1)
                          : null,
                      child: CircleAvatar(
                        radius: 12.r,
                        backgroundColor: sel.quantity > 1
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        child: Icon(Icons.remove,
                            size: 14.sp, color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        '${sel.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onQtyChanged(sel.quantity + 1),
                      child: CircleAvatar(
                        radius: 12.r,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(Icons.add,
                            size: 14.sp, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
