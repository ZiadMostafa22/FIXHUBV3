import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/core/widgets/detailed_invoice_dialog.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class ActiveServices extends ConsumerWidget {
  const ActiveServices({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingViewModelProvider);
    final carState = ref.watch(carViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter for active services: inProgress or completedPendingPayment
    final activeBookings = bookingState.bookings.where((booking) {
      return booking.status == BookingStatus.inProgress || 
             booking.status == BookingStatus.completedPendingPayment;
    }).toList();

    if (activeBookings.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no active services
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.engineering,
              color: Theme.of(context).primaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'active_services'.tr(ref),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${activeBookings.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ...activeBookings.map((booking) {
        // Find the car for this booking
        final car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
        
        // Skip this booking if car is not found
        if (car == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: isDark ? 0 : 3,
          color: isDark ? const Color(0xFF1E1E1E) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: isDark ? BorderSide(color: Colors.grey.shade800) : BorderSide.none,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: booking.status == BookingStatus.completedPendingPayment
                    ? (isDark ? [Colors.deepPurple.shade900.withOpacity(0.3), Colors.purple.shade900.withOpacity(0.1)] : [Colors.deepPurple.shade50, Colors.purple.shade50])
                    : (isDark ? [Colors.blue.shade900.withOpacity(0.3), Colors.lightBlue.shade900.withOpacity(0.1)] : [Colors.blue.shade50, Colors.lightBlue.shade50]),
              ),
            ),
            child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(booking.status),
                                size: 14.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                _getStatusText(booking.status, ref),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (booking.status == BookingStatus.completedPendingPayment)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.payment, size: 12.sp, color: Colors.white),
                                SizedBox(width: 4.w),
                                Text(
                                  'payment_due'.tr(ref),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    // Car Info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                          radius: 24.r,
                          child: Icon(
                            Icons.directions_car,
                            color: Theme.of(context).primaryColor,
                            size: 28.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${car.make} ${car.model}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                car.licensePlate,
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12.h),
                    Divider(height: 1.h, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    SizedBox(height: 12.h),
                    
                    // Service Type & Date
                    Row(
                      children: [
                        Icon(Icons.build, size: 16.sp, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _getMaintenanceTypeName(booking.maintenanceType, ref),
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16.sp, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        SizedBox(width: 8.w),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(booking.scheduledDate),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                    
                    // Show total cost if completed and pending payment
                    if (booking.status == BookingStatus.completedPendingPayment) ...[
                      SizedBox(height: 12.h),
                      GestureDetector(
                        onTap: () {
                          final car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
                          showDialog(
                            context: context,
                            builder: (context) => DetailedInvoiceDialog(
                              booking: booking,
                              car: car,
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'total_amount'.tr(ref),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Text(
                                        '${'currency'.tr(ref)}${booking.totalCost.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.greenAccent : Colors.green,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Icon(
                                        Icons.receipt_long,
                                        size: 16.sp,
                                        color: isDark ? Colors.greenAccent : Colors.green,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16.sp,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Show progress message if in progress
                    if (booking.status == BookingStatus.inProgress) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: isDark ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: isDark ? Theme.of(context).primaryColor.withOpacity(0.5) : Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'technician_working'.tr(ref),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: isDark ? Colors.blue.shade100 : Colors.blue.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
      }),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completedPendingPayment:
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.inProgress:
        return Icons.build_circle;
      case BookingStatus.completedPendingPayment:
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(BookingStatus status, WidgetRef ref) {
    switch (status) {
      case BookingStatus.inProgress:
        return 'service_in_progress'.tr(ref);
      case BookingStatus.completedPendingPayment:
        return 'service_completed'.tr(ref);
      default:
        return 'Unknown';
    }
  }

  String _getMaintenanceTypeName(MaintenanceType type, WidgetRef ref) {
    switch (type) {
      case MaintenanceType.regular:
        return 'regular_maintenance'.tr(ref);
      case MaintenanceType.repair:
        return 'repair_service'.tr(ref);
      case MaintenanceType.inspection:
        return 'inspection'.tr(ref);
      case MaintenanceType.emergency:
        return 'emergency_service'.tr(ref);
    }
  }
}
