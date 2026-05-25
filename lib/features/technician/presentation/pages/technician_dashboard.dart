import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/settings_page.dart';
import 'package:car_maintenance_system_new/features/technician/presentation/widgets/today_jobs.dart';
import 'package:car_maintenance_system_new/features/technician/presentation/widgets/performance_stats.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/notifications_page.dart';

import 'package:car_maintenance_system_new/features/shared/presentation/widgets/app_drawer.dart';

class TechnicianDashboard extends ConsumerStatefulWidget {
  const TechnicianDashboard({super.key});

  @override
  ConsumerState<TechnicianDashboard> createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends ConsumerState<TechnicianDashboard> {
  @override
  void initState() {
    super.initState();
    // Start real-time listeners for bookings and load cars when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        // Start real-time listener for all bookings
        ref.read(bookingViewModelProvider.notifier).startListening(user.id, role: 'technician');
        // Load all cars to display car info in jobs
        ref.read(carViewModelProvider.notifier).loadCars('');
      }
      
    });
  }

  @override
  void dispose() {
    // NOTE: Do NOT call stopListening() here.
    // The listener lifecycle is managed by TechnicianJobsPage.
    // Stopping it here would trigger a listener restart when the user
    // navigates to Jobs, causing the first real-time batch to be silently skipped.
    super.dispose();
  }

  Future<void> _refreshData() async {
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      await ref.read(bookingViewModelProvider.notifier).loadBookings(user.id, role: 'technician');
      await ref.read(carViewModelProvider.notifier).loadCars('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Scaffold(
      drawer: const AppDrawer(role: 'technician'),
      appBar: AppBar(
        title: Text(
          '${'welcome_technician'.tr(ref)}${user?.name ?? 'technician'.tr(ref)}',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(ref),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'ready_start_day'.tr(ref),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Performance Stats
            Text(
              'performance'.tr(ref),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 16.h),
            const PerformanceStats(),
            
            SizedBox(height: 24.h),
            
            // Today's Jobs
            Text(
              "todays_jobs".tr(ref),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 16.h),
            const TodayJobs(),
          ],
        ),
        ),
      ),
    );
  }

  String _getGreeting(WidgetRef ref) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'good_morning'.tr(ref);
    } else if (hour < 17) {
      return 'good_afternoon'.tr(ref);
    } else {
      return 'good_evening'.tr(ref);
    }
  }
}