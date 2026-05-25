import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class UpcomingAppointments extends ConsumerStatefulWidget {
  const UpcomingAppointments({super.key});

  @override
  ConsumerState<UpcomingAppointments> createState() => _UpcomingAppointmentsState();
}

class _UpcomingAppointmentsState extends ConsumerState<UpcomingAppointments> {
  final Set<String> _fetchingCars = {};

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingViewModelProvider);
    final carState = ref.watch(carViewModelProvider);
    
    // Fetch missing cars when bookings change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final booking in bookingState.bookings) {
        if (booking.carId.isNotEmpty) {
          final carExists = carState.cars.any((c) => c.id == booking.carId);
          if (!carExists && !_fetchingCars.contains(booking.carId)) {
            _fetchingCars.add(booking.carId);
            ref.read(carViewModelProvider.notifier).getCarById(booking.carId).then((_) {
              if (mounted) {
                setState(() {
                  _fetchingCars.remove(booking.carId);
                });
              } else {
                _fetchingCars.remove(booking.carId);
              }
            });
          }
        }
      }
    });
    
    // Filter upcoming bookings (pending, confirmed only - not inProgress)
    final upcomingBookings = bookingState.bookings.where((booking) {
      return (booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.confirmed) &&
             booking.scheduledDate.isAfter(DateTime.now());
    }).toList();
    
    // Sort by scheduled date
    upcomingBookings.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    
    // Show only next 3 upcoming
    final displayBookings = upcomingBookings.take(3).toList();

    // Don't show the section at all if no upcoming appointments
    if (displayBookings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: displayBookings.map((booking) {
        // Get car info
        final car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
        final carName = car != null ? '${car.make} ${car.model}' : 'loading'.tr(ref);
        
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 4.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getMaintenanceTypeName(booking.maintenanceType, ref),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            carName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 13.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14.sp,
                                color: Colors.grey[500],
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${DateFormat('MMM dd, yyyy').format(booking.scheduledDate)} ${'at'.tr(ref)} ${booking.timeSlot}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        _getStatusName(booking.status, ref),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(booking.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Cancel button (only for pending and confirmed bookings)
                if (booking.status == BookingStatus.pending || 
                    booking.status == BookingStatus.confirmed) ...[
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, ref, booking),
                      icon: Icon(Icons.cancel_outlined, size: 16.sp),
                      label: Text('cancel_appointment'.tr(ref)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, BookingEntity booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('cancel_appointment'.tr(ref)),
        content: Text(
          'cancel_appointment_confirm'.tr(ref),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('keep_appointment'.tr(ref)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close confirmation dialog first
              Navigator.pop(dialogContext);
              
              // Show simple loading indicator
              if (!context.mounted) return;
              
              // Use a simple loading overlay instead of dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                // Quick cancellation with immediate UI update
                final success = await ref.read(bookingViewModelProvider.notifier).cancelBooking(
                  booking.id,
                );
                
                // Close loading immediately
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                
                // Show result immediately
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success 
                          ? 'appointment_cancelled_success'.tr(ref)
                          : 'failed_cancel_appointment'.tr(ref),
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                print('Cancellation error: $e');
                
                // Close loading immediately
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                
                // Show error
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error cancelling appointment: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('cancel_appointment'.tr(ref)),
          ),
        ],
      ),
    );
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

  String _getStatusName(BookingStatus status, WidgetRef ref) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending'.tr(ref);
      case BookingStatus.confirmed:
        return 'confirmed'.tr(ref);
      case BookingStatus.inProgress:
        return 'service_in_progress'.tr(ref);
      case BookingStatus.completedPendingPayment:
        return 'awaiting_payment'.tr(ref);
      case BookingStatus.completed:
        return 'completed'.tr(ref);
      case BookingStatus.cancelled:
        return 'was_cancelled'.tr(ref);
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pending:
        return Colors.orange;
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