import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

class TodayJobs extends ConsumerStatefulWidget {
  const TodayJobs({super.key});

  @override
  ConsumerState<TodayJobs> createState() => _TodayJobsState();
}

class _TodayJobsState extends ConsumerState<TodayJobs> {
  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingViewModelProvider);
    final carState = ref.watch(carViewModelProvider);
    
    // Fetch missing cars when bookings change (only once per build cycle)
    // This ensures all technicians see car names immediately
    // Removed addPostFrameCallback from build to prevent performance issues
    
    // Filter today's jobs (confirmed, in progress, pending)
    final today = DateTime.now();
    
    // Debug: Print all bookings with dates
    debugPrint('📅 Today is: ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}');
    debugPrint('Total bookings: ${bookingState.bookings.length}');
    
    final todayJobs = bookingState.bookings.where((booking) {
      final bookingDate = booking.scheduledDate;
      final isToday = bookingDate.year == today.year &&
                     bookingDate.month == today.month &&
                     bookingDate.day == today.day;
      
      final isActiveStatus = booking.status == BookingStatus.confirmed ||
                            booking.status == BookingStatus.inProgress ||
                            booking.status == BookingStatus.pending;
      
      // Show ALL today's jobs to ALL technicians (no assignment filter)
      // This allows any technician to see and work on today's bookings
      
      // Debug: Print each booking with its date
      debugPrint('  Booking ${booking.id}: ${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}, status: ${booking.status}, isToday: $isToday, isActive: $isActiveStatus');
      
      if (isToday && isActiveStatus) {
        debugPrint('Today\'s job found: ${booking.id}, status: ${booking.status}');
      }
      
      return isToday && isActiveStatus;
    }).toList();
    
    // Sort by time slot
    todayJobs.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
    
    // Only show first 2 jobs
    final displayJobs = todayJobs.take(2).toList();
    final hasMore = todayJobs.length > 2;

    if (todayJobs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.work_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No jobs scheduled for today',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enjoy your free time!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...displayJobs.map((booking) {
        // Get car info
        final car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
        final carName = car != null ? '${car.make} ${car.model} (${car.year})' : 'Loading...';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => context.go('/technician/job-details/${booking.id}'),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 8),
                Text(
                  carName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.timeSlot,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
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
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      }),
        // View All button
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/technician/jobs'),
              icon: const Icon(Icons.arrow_forward),
              label: Text('View All Jobs (${todayJobs.length})'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
      ],
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
