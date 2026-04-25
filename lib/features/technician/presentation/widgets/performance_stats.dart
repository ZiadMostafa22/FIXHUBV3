import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

class PerformanceStats extends ConsumerWidget {
  const PerformanceStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Calculate stats from bookings
    final completedJobs = bookingState.bookings.where((b) =>
      b.status == BookingStatus.completed &&
      b.assignedTechnicians != null &&
      b.assignedTechnicians!.isNotEmpty &&
      b.assignedTechnicians!.contains(user?.id)
    ).length;

    final completedToday = bookingState.bookings.where((b) =>
      b.status == BookingStatus.completed &&
      b.assignedTechnicians != null &&
      b.assignedTechnicians!.isNotEmpty &&
      b.assignedTechnicians!.contains(user?.id) &&
      b.completedAt != null &&
      b.completedAt!.isAfter(todayStart) &&
      b.completedAt!.isBefore(todayEnd)
    ).length;

    final inProgressJobs = bookingState.bookings.where((b) =>
      b.status == BookingStatus.inProgress &&
      b.assignedTechnicians != null &&
      b.assignedTechnicians!.isNotEmpty &&
      b.assignedTechnicians!.contains(user?.id)
    ).length;

    // Calculate total hours worked from completed bookings - ONLY assigned jobs
    final totalHoursWorked = bookingState.bookings
        .where((b) =>
          b.status == BookingStatus.completed &&
          b.assignedTechnicians != null &&
          b.assignedTechnicians!.isNotEmpty &&
          b.assignedTechnicians!.contains(user?.id)
        )
        .fold<double>(0, (sum, booking) => sum + booking.hoursWorked);

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
          title: 'Completed Today',
          value: completedToday.toString(),
          icon: Icons.today,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          title: 'Total Completed',
          value: completedJobs.toString(),
          icon: Icons.check_circle,
          color: Colors.teal,
        ),
        _buildStatCard(
          context,
          title: 'In Progress',
          value: inProgressJobs.toString(),
          icon: Icons.work,
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          title: 'Total Hours',
          value: '${totalHoursWorked.toStringAsFixed(1)}h',
          icon: Icons.schedule,
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
