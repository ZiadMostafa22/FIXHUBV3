import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/settings_page.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/notifications_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

import 'package:car_maintenance_system_new/features/shared/presentation/widgets/app_drawer.dart';

class CashierDashboard extends ConsumerStatefulWidget {
  const CashierDashboard({super.key});

  @override
  ConsumerState<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends ConsumerState<CashierDashboard> {
  // Cache for user names
  final Map<String, String> _userNames = {};
  Stream<int>? _pendingRefundsStream;

  Future<String> _getUserName(String userId) async {
    if (_userNames.containsKey(userId)) {
      return _userNames[userId]!;
    }
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userName = userDoc.data()?['name'] ?? 'Unknown Customer';
        _userNames[userId] = userName;
        return userName;
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
    
    _userNames[userId] = 'Unknown Customer';
    return 'Unknown Customer';
  }

  @override
  void initState() {
    super.initState();
    // Setup real-time stream for pending refunds
    _pendingRefundsStream = FirebaseFirestore.instance
        .collection('refunds')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        // Load all bookings for cashier
        ref.read(bookingViewModelProvider.notifier).startListening(user.id, role: 'cashier');
        // Load car details
        ref.read(carViewModelProvider.notifier).loadCars('');
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
      await ref.read(bookingViewModelProvider.notifier).loadBookings(user.id, role: 'cashier');
      // Stream will auto-update, no need to manually reload
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final bookingState = ref.watch(bookingViewModelProvider);
    
    // Filter bookings waiting for payment
    final pendingPayments = bookingState.bookings
        .where((b) => b.status == BookingStatus.completedPendingPayment)
        .toList();
    
    
    // Get today's completed payments
    final today = DateTime.now();
    final todayPayments = bookingState.bookings.where((b) {
      return b.isPaid && 
             b.paidAt != null && 
             b.paidAt!.year == today.year &&
             b.paidAt!.month == today.month &&
             b.paidAt!.day == today.day;
    }).toList();
    
    final todayTotal = todayPayments.fold<double>(
      0, 
      (sum, booking) => sum + booking.totalCost,
    );

    return Scaffold(
      drawer: const AppDrawer(role: 'cashier'),
      appBar: AppBar(
        title: Text(
          '${'welcome_cashier'.tr(ref)}${user?.name ?? 'cashier'.tr(ref)}',
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
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pending_actions,
                              color: Colors.orange,
                              size: 32.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '${pendingPayments.length}',
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              'pending_payments'.tr(ref),
                              style: TextStyle(fontSize: 12.sp),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: Colors.green,
                              size: 32.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '${todayTotal.toStringAsFixed(0)} ${'currency'.tr(ref)}',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'todays_total'.tr(ref),
                              style: TextStyle(fontSize: 12.sp),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Pending Refunds Alert Card (Real-time)
              StreamBuilder<int>(
                stream: _pendingRefundsStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  
                  return Column(
                    children: [
                      SizedBox(height: 16.h),
                      InkWell(
                        onTap: () => context.go('/cashier/refunds'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.money_off,
                                  color: Colors.white,
                                  size: 28.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$count ${'refunds_pending'.tr(ref)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'tap_to_process_refunds'.tr(ref),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              SizedBox(height: 24.h),
              
              // Pending Payments Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'awaiting_payment'.tr(ref),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                  if (pendingPayments.isNotEmpty)
                    TextButton(
                      onPressed: () => context.go('/cashier/payments'),
                      child: Text('view_all'.tr(ref)),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              
              if (pendingPayments.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'no_pending_payments'.tr(ref),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingPayments.length > 5 ? 5 : pendingPayments.length,
                  itemBuilder: (context, index) {
                    final booking = pendingPayments[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8.h),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final carState = ref.watch(carViewModelProvider);
                          final car = carState.cars.isEmpty 
                              ? null 
                              : carState.cars.where((c) => c.id == booking.carId).firstOrNull;
                          
                          return InkWell(
                            onTap: () {
                              context.go('/cashier/payment/${booking.id}');
                            },
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.orange.shade100,
                                    child: const Icon(Icons.payment, color: Colors.orange),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${'invoice'.tr(ref)}${booking.id.substring(0, 8)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 4.h),
                                        FutureBuilder<String>(
                                          future: _getUserName(booking.userId),
                                          builder: (context, snapshot) {
                                            final customerName = snapshot.data ?? 'Loading...';
                                            return Text(
                                              '${'customer'.tr(ref)}$customerName',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          '${'amount'.tr(ref)}${booking.totalCost.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                                          style: TextStyle(fontSize: 12.sp),
                                        ),
                                        if (car != null) ...[
                                          SizedBox(height: 4.h),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(4.r),
                                              border: Border.all(color: Colors.blue.shade200),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.directions_car,
                                                  size: 12.sp,
                                                  color: Colors.blue.shade700,
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  '${car.year} ${car.make} ${car.model}',
                                                  style: TextStyle(
                                                    fontSize: 10.sp,
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (booking.completedAt != null) ...[
                                          SizedBox(height: 4.h),
                                          Text(
                                            '${'completed_at'.tr(ref)}${DateFormat('dd/MM/yyyy HH:mm').format(booking.completedAt!)}',
                                            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.go('/cashier/payment/${booking.id}');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                    ),
                                    child: Text(
                                      'receive'.tr(ref),
                                      style: TextStyle(fontSize: 12.sp),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
