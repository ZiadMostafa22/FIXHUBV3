import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/settings_page.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/widgets/admin_stats.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/widgets/recent_activities.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/notifications_page.dart';

import 'package:car_maintenance_system_new/features/shared/presentation/widgets/app_drawer.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    // Start real-time listeners for bookings and cars
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        // Start real-time listener for all bookings
        ref.read(bookingViewModelProvider.notifier).startListening(user.id, role: 'admin');
        ref.read(carViewModelProvider.notifier).loadCars(''); // Load all cars
      }
    });
  }

  @override
  void dispose() {
    // Stop listening when dashboard is disposed
    // Wrap in try-catch to handle cases where widget is already disposed during logout
    try {
      ref.read(bookingViewModelProvider.notifier).stopListening();
    } catch (e) {
      // Widget was already disposed, safe to ignore
      debugPrint('Dashboard disposed, listener cleanup skipped: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Scaffold(
      drawer: const AppDrawer(role: 'admin'),
      appBar: AppBar(
        title: Text(
          'admin_dashboard'.tr(ref),
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: SingleChildScrollView(
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
                      '${'welcome_back'.tr(ref)}${user?.name ?? 'admin'.tr(ref)}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'business_overview'.tr(ref),
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
            
            // Statistics
            Text(
              'overview'.tr(ref),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 16.h),
            const AdminStats(),
            
            SizedBox(height: 24.h),
            
            // Quick Actions - NEW FEATURES
            Text(
              'quick_actions'.tr(ref),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 16.h),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1,
              children: [
                _buildQuickActionCard(
                  context,
                  icon: Icons.build_circle,
                  label: 'services'.tr(ref),
                  color: Colors.blue,
                  onTap: () => context.push('/admin/services'),
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.receipt_long,
                  label: 'refunds'.tr(ref),
                  color: Colors.orange,
                  onTap: () => context.push('/admin/refunds'),
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.bar_chart,
                  label: 'reports'.tr(ref),
                  color: Colors.purple,
                  onTap: () => context.push('/admin/reports'),
                ),
              ],
            ),
            
            
            SizedBox(height: 24.h),
            
            // Recent Activities
            Text(
              'recent_activities'.tr(ref),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 16.h),
            const RecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32.sp),
              SizedBox(height: 8.h),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}