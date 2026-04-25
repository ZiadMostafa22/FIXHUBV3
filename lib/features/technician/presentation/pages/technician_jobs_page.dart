import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/core/widgets/unified_filter_widget.dart';

class TechnicianJobsPage extends ConsumerStatefulWidget {
  const TechnicianJobsPage({super.key});

  @override
  ConsumerState<TechnicianJobsPage> createState() => _TechnicianJobsPageState();
}

class _TechnicianJobsPageState extends ConsumerState<TechnicianJobsPage> {
  String _filterStatus = 'all';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        // Start real-time listener for bookings
        ref.read(bookingViewModelProvider.notifier).startListening(user.id, role: 'technician');
        ref.read(carViewModelProvider.notifier).loadCars('');
      }
    });
  }

  @override
  void dispose() {
    // Stop listening when page is disposed
    // Wrap in try-catch to handle cases where widget is already disposed during logout
    try {
      ref.read(bookingViewModelProvider.notifier).stopListening();
    } catch (e) {
      // Widget was already disposed, safe to ignore
      debugPrint('Jobs page disposed, listener cleanup skipped: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingViewModelProvider);
    final carState = ref.watch(carViewModelProvider);
    
    // Removed addPostFrameCallback from build to prevent performance issues and unwanted notifications
    
    // Filter bookings - show ALL jobs to ALL technicians (no assignment filter)
    final filteredBookings = bookingState.bookings.where((booking) {
      // Apply date range filter
      if (_dateRange != null) {
        final d = booking.scheduledDate;
        final start = DateTime(
            _dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
        final end = DateTime(
            _dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59);
        if (d.isBefore(start) || d.isAfter(end)) return false;
      }

      // Apply status filter
      if (_filterStatus == 'all') return true;
      if (_filterStatus == 'pending') return booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed;
      if (_filterStatus == 'in_progress') return booking.status == BookingStatus.inProgress;
      if (_filterStatus == 'completed') return booking.status == BookingStatus.completed;
      return true;
    }).toList();
    
    // Sort by scheduled date
    filteredBookings.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
      ),
      body: Column(
        children: [
          // Unified Filter Widget
          UnifiedFilterWidget(
            selectedFilter: _filterStatus,
            dateRange: _dateRange,
            filterOptions: FilterOptions.technicianJobs,
            onFilterChanged: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            onDateRangeChanged: (range) {
              setState(() {
                _dateRange = range;
              });
            },
            showDateFilter: true,
            showStatusFilter: true,
          ),
          // Content
          Expanded(
            child: bookingState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.work,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filterStatus == 'all' ? 'No jobs assigned' : 'No $_filterStatus jobs',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your assigned jobs will appear here',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    
                    // Get car info
                    final car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
                    final carName = car != null ? '${car.make} ${car.model} (${car.year})' : 'Loading...';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getMaintenanceTypeName(booking.maintenanceType),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getStatusName(booking.status),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getStatusColor(booking.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.directions_car, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    carName,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(booking.scheduledDate),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  booking.timeSlot,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            if (booking.description != null && booking.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                booking.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => context.go('/technician/job-details/${booking.id}'),
                                icon: Icon(
                                  booking.status == BookingStatus.inProgress 
                                      ? Icons.build 
                                      : booking.status == BookingStatus.completed
                                          ? Icons.check_circle
                                          : Icons.play_arrow,
                                ),
                                label: Text(
                                  booking.status == BookingStatus.inProgress 
                                      ? 'Continue Work & Complete Job' 
                                      : booking.status == BookingStatus.completed
                                          ? 'View Invoice'
                                          : 'Start Job & Add Invoice',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: booking.status == BookingStatus.inProgress 
                                      ? Colors.blue 
                                      : booking.status == BookingStatus.completed
                                          ? Colors.green
                                          : Theme.of(context).primaryColor,
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
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

  String _getStatusName(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completedPendingPayment:
        return 'Awaiting Payment';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completedPendingPayment:
        return Colors.deepPurple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }
}