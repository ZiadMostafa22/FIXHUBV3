import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class AdminStats extends ConsumerWidget {
  const AdminStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingViewModelProvider);
    
    // Calculate real statistics from bookings
    final activeBookings = bookingState.bookings.where((b) => 
      b.status == BookingStatus.pending || 
      b.status == BookingStatus.confirmed ||
      b.status == BookingStatus.inProgress
    ).length;
    
    final completedToday = bookingState.bookings.where((b) {
      if (b.status != BookingStatus.completed) return false;
      final today = DateTime.now();
      final completedDate = b.completedAt ?? b.updatedAt;
      return completedDate.year == today.year &&
             completedDate.month == today.month &&
             completedDate.day == today.day;
    }).length;
    
    final completedBookings = bookingState.bookings.where((b) => 
      b.status == BookingStatus.completed
    ).toList();
    
    // Calculate real revenue from completed bookings
    final totalRevenue = completedBookings.fold<double>(0, (sum, booking) => sum + booking.totalCost);
    
    // TODO: Get actual user count from user provider
    final totalUsers = bookingState.bookings.map((b) => b.userId).toSet().length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      crossAxisSpacing: 8.w,
      mainAxisSpacing: 8.h,
      children: [
        _buildStatCard(
          context,
          title: 'total_users'.tr(ref),
          value: totalUsers.toString(),
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          title: 'active_bookings'.tr(ref),
          value: activeBookings.toString(),
          icon: Icons.book_online,
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          title: 'completed_today'.tr(ref),
          value: completedToday.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          title: 'total_revenue'.tr(ref),
          value: '${totalRevenue.toStringAsFixed(2)} ${'currency'.tr(ref)}',
          icon: Icons.attach_money,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(21.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 20.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
