import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/settings_page.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/quick_actions.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/upcoming_appointments.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/active_services.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/missed_appointments.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/customer_bottom_nav_bar.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/widgets/app_drawer.dart';

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  @override
  void initState() {
    super.initState();
    // Start real-time listeners for bookings and load cars when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        // Start real-time listener for bookings
        ref.read(bookingViewModelProvider.notifier).startListening(user.id);
        // Load cars (one-time)
        ref.read(carViewModelProvider.notifier).loadCars(user.id);
      }
    });
  }

  @override
  void dispose() {
    try {
      ref.read(bookingViewModelProvider.notifier).stopListening();
    } catch (e) {
      debugPrint('Dashboard disposed, listener cleanup skipped: $e');
    }
    super.dispose();
  }

  Future<void> _refreshData() async {
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      await ref.read(bookingViewModelProvider.notifier).loadBookings(user.id);
      await ref.read(carViewModelProvider.notifier).loadCars(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Scaffold(
      drawer: const AppDrawer(role: 'customer'),
      appBar: AppBar(
        title: Text(
          '${'welcome'.tr(ref)}, ${user?.name ?? ''}',
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
                      'how_can_we_help'.tr(ref),
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
            
            // Quick Actions
            Text(
              'quick_actions'.tr(ref),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 16.h),
            const QuickActions(),
            
            SizedBox(height: 24.h),
            
            // Upcoming Appointments
            Consumer(
              builder: (context, ref, child) {
                final bookingState = ref.watch(bookingViewModelProvider);
                final upcomingBookings = bookingState.bookings.where((booking) {
                  return (booking.status == BookingStatus.pending ||
                          booking.status == BookingStatus.confirmed) &&
                         booking.scheduledDate.isAfter(DateTime.now());
                }).toList();
                
                if (upcomingBookings.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'upcoming_appointments'.tr(ref),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    const UpcomingAppointments(),
                    SizedBox(height: 24.h),
                  ],
                );
              },
            ),
            
            const MissedAppointments(),
            const ActiveServices(),
            SizedBox(height: 24.h),
          ],
        ),
        ),
      ),
      bottomNavigationBar: CustomerBottomNavBar(context: context),
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