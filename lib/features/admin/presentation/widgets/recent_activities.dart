import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class RecentActivities extends ConsumerWidget {
  const RecentActivities({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingViewModelProvider);
    
    // Get recent bookings (last 10)
    final recentBookings = [...bookingState.bookings];
    recentBookings.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final displayBookings = recentBookings.take(10).toList();
    
    if (displayBookings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'no_recent_activities'.tr(ref),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'activities_appear_here'.tr(ref),
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
      children: displayBookings.map((booking) {
        final activity = _createActivityFromBooking(booking, ref);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: activity['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    activity['icon'],
                    color: activity['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity['description'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity['time'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Map<String, dynamic> _createActivityFromBooking(BookingEntity booking, WidgetRef ref) {
    String title;
    String description;
    IconData icon;
    Color color;
    
    switch (booking.status) {
      case BookingStatus.pending:
        title = 'new_booking'.tr(ref);
        description = '${'booking_created_for'.tr(ref)} ${_getMaintenanceTypeName(booking.maintenanceType, ref)}';
        icon = Icons.book_online;
        color = Colors.orange;
        break;
      case BookingStatus.confirmed:
        title = 'booking_confirmed'.tr(ref);
        description = '${_getMaintenanceTypeName(booking.maintenanceType, ref)} ${'confirmed'.tr(ref)}';
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;
      case BookingStatus.inProgress:
        title = 'service_in_progress'.tr(ref);
        description = '${_getMaintenanceTypeName(booking.maintenanceType, ref)} ${'is_being_serviced'.tr(ref)}';
        icon = Icons.build;
        color = Colors.purple;
        break;
      case BookingStatus.completedPendingPayment:
        title = 'awaiting_payment'.tr(ref);
        description = '${_getMaintenanceTypeName(booking.maintenanceType, ref)} ${'completed_waiting_payment'.tr(ref)} - ${booking.totalCost.toStringAsFixed(2)} ${'currency'.tr(ref)}';
        icon = Icons.payment;
        color = Colors.deepPurple;
        break;
      case BookingStatus.completed:
        title = 'service_completed'.tr(ref);
        description = '${_getMaintenanceTypeName(booking.maintenanceType, ref)} ${'service_completed'.tr(ref).toLowerCase()} - ${booking.totalCost.toStringAsFixed(2)} ${'currency'.tr(ref)}';
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case BookingStatus.cancelled:
        title = 'booking_cancelled'.tr(ref);
        description = '${_getMaintenanceTypeName(booking.maintenanceType, ref)} ${'was_cancelled'.tr(ref)}';
        icon = Icons.cancel;
        color = Colors.red;
        break;
    }
    
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'color': color,
      'time': _getTimeAgo(booking.updatedAt, ref),
    };
  }
  
  String _getMaintenanceTypeName(MaintenanceType type, WidgetRef ref) {
    switch (type) {
      case MaintenanceType.regular:
        return 'regular_maintenance'.tr(ref);
      case MaintenanceType.inspection:
        return 'inspection'.tr(ref);
      case MaintenanceType.repair:
        return 'repair_service'.tr(ref);
      case MaintenanceType.emergency:
        return 'emergency_service'.tr(ref);
    }
  }
  
  String _getTimeAgo(DateTime dateTime, WidgetRef ref) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM dd').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${'days_ago'.tr(ref)}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${'hours_ago'.tr(ref)}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${'minutes_ago'.tr(ref)}';
    } else {
      return 'just_now'.tr(ref);
    }
  }
}
