import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/core/utils/pdf_generator.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';
import 'package:car_maintenance_system_new/features/refunds/data/repositories/refund_repository.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class CashierPaymentDetailsPage extends ConsumerStatefulWidget {
  final String bookingId;
  
  const CashierPaymentDetailsPage({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<CashierPaymentDetailsPage> createState() => _CashierPaymentDetailsPageState();
}

class _CashierPaymentDetailsPageState extends ConsumerState<CashierPaymentDetailsPage> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load car details
      ref.read(carViewModelProvider.notifier).loadCars('');
    });
  }

  Future<void> _exportInvoice(BookingEntity booking) async {
    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get car details - fetch if not found
      final carState = ref.read(carViewModelProvider);
      Car? car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
      
      // If car not found, fetch it
      if (car == null && booking.carId.isNotEmpty) {
        car = await ref.read(carViewModelProvider.notifier).getCarById(booking.carId);
      }

      // Get customer details from Firebase
      final customerDoc = await FirebaseService.firestore
          .collection('users')
          .doc(booking.userId)
          .get();
      
      final customerData = customerDoc.data();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Generate and share PDF
      if (mounted) {
        await PdfGenerator.generateAndShareInvoice(
          context,
          booking,
          car,
          customerData,
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_exporting'.tr(ref)}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processPayment(BookingEntity booking) async {
    // Capture ScaffoldMessenger before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() => _isProcessing = true);

    try {
      final user = ref.read(authViewModelProvider).user;
      if (user == null) {
        throw 'User not found';
      }

      final success = await ref.read(bookingViewModelProvider.notifier).processPayment(
        bookingId: widget.bookingId,
        cashierId: user.id,
        paymentMethod: _selectedPaymentMethod,
      );

      setState(() => _isProcessing = false);

      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('payment_processed'.tr(ref)),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back after short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/cashier');
        }
      } else {
        throw 'failed_payment'.tr(ref);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingViewModelProvider);
    final carState = ref.watch(carViewModelProvider);
    
    final booking = bookingState.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => throw 'Booking not found',
    );
    
    // Debug: Print discount information
    print('🔍 Cashier Payment Details - Booking ID: ${booking.id}');
    print('🔍 Discount Code: ${booking.offerCode}');
    print('🔍 Offer Title: ${booking.offerTitle}');
    print('🔍 Discount Percentage: ${booking.discountPercentage}');
    print('🔍 Subtotal: ${booking.subtotal}');
    print('🔍 Discount Amount: ${booking.discountAmount}');
    print('🔍 Subtotal After Discount: ${booking.subtotalAfterDiscount}');
    print('🔍 Total Cost: ${booking.totalCost}');
    
    Car? car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
    
    // If car not found, fetch it
    if (car == null && booking.carId.isNotEmpty) {
      ref.read(carViewModelProvider.notifier).getCarById(booking.carId).then((fetchedCar) {
        if (mounted && fetchedCar != null) {
          setState(() {});
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('invoice_details'.tr(ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'export_invoice'.tr(ref),
            onPressed: () => _exportInvoice(booking),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'booking_info'.tr(ref),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildInfoRow('invoice_number'.tr(ref), '#${booking.id.substring(0, 8)}'),
                    if (car != null)
                      _buildInfoRow('vehicle'.tr(ref), '${car.make} ${car.model} (${car.year})'),
                    // Customer Details
                    FutureBuilder<String>(
                      future: _getUserName(booking.userId),
                      builder: (context, snapshot) {
                        final customerName = snapshot.data ?? 'Loading...';
                        return _buildInfoRow('customer'.tr(ref).replaceAll(':', ''), customerName);
                      },
                    ),
                    if (booking.completedAt != null)
                      _buildInfoRow(
                        'completion_date'.tr(ref),
                        DateFormat('dd/MM/yyyy HH:mm').format(booking.completedAt!),
                      ),
                    // Debug: Show discount information
                    if (booking.offerCode != null)
                      _buildInfoRow('discount_code'.tr(ref), booking.offerCode!),
                    if (booking.offerTitle != null)
                      _buildInfoRow('offer_title'.tr(ref), booking.offerTitle!),
                    if (booking.discountPercentage != null)
                      _buildInfoRow('discount_percentage'.tr(ref), '${booking.discountPercentage}%'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Car Details Card
            if (car != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: Theme.of(context).primaryColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'vehicle_details'.tr(ref),
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _buildCarInfoRow('make'.tr(ref), car.make),
                      _buildCarInfoRow('model'.tr(ref), car.model),
                      _buildCarInfoRow('year'.tr(ref), car.year.toString()),
                      _buildCarInfoRow('license_plate'.tr(ref), car.licensePlate),
                      _buildCarInfoRow('color'.tr(ref), car.color),
                      _buildCarInfoRow('type'.tr(ref), car.type.toString().split('.').last.toUpperCase()),
                      if (car.vin != null && car.vin!.isNotEmpty)
                        _buildCarInfoRow('vin'.tr(ref), car.vin!),
                      if (car.mileage != null)
                        _buildCarInfoRow('mileage'.tr(ref), '${car.mileage} km'),
                      if (car.engineType != null && car.engineType!.isNotEmpty)
                        _buildCarInfoRow('engine_type'.tr(ref), car.engineType!),
                    ],
                  ),
                ),
              ),
            
            SizedBox(height: 16.h),
            
            // Service Items Card
            if (booking.serviceItems != null && booking.serviceItems!.isNotEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'parts_services'.tr(ref),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ...booking.serviceItems!.map((item) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${'qty'.tr(ref)}${item.quantity} × ${item.price.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.totalPrice.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            
            SizedBox(height: 16.h),
            
            // Cost Breakdown Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'cost_breakdown'.tr(ref),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildCostRow('subtotal'.tr(ref), booking.subtotal, ref: ref),
                    // Debug: Show discount info even if percentage is 0
                    if (booking.offerCode != null || booking.offerTitle != null || (booking.discountPercentage != null && booking.discountPercentage! > 0)) ...[
                      if (booking.discountPercentage != null && booking.discountPercentage! > 0) ...[
                        _buildCostRow(
                          '${'discount'.tr(ref)} (${booking.discountPercentage}%)',
                          -booking.discountAmount,
                          color: Colors.green,
                          ref: ref,
                        ),
                        _buildCostRow('after_discount'.tr(ref), booking.subtotalAfterDiscount, ref: ref),
                      ] else if (booking.offerCode != null || booking.offerTitle != null) ...[
                        // Show discount info even if percentage is 0 or null
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'discount_applied'.tr(ref),
                                style: TextStyle(fontSize: 14.sp),
                              ),
                              Text(
                                '${'code'.tr(ref)}${booking.offerCode ?? 'N/A'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    if (booking.laborCost != null)
                      _buildCostRow('labor_cost'.tr(ref), booking.laborCost!, ref: ref),
                    _buildCostRow(
                      'tax'.tr(ref),
                      (booking.tax ?? (booking.subtotalAfterDiscount * 0.10)),
                      ref: ref,
                    ),
                    Divider(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'total'.tr(ref),
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${booking.totalCost.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Payment Method Selection
            if (booking.status == BookingStatus.completedPendingPayment) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'payment_method'.tr(ref),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      RadioListTile<PaymentMethod>(
                       title: Row(
                          children: [
                            const Icon(Icons.money, color: Colors.green),
                            const SizedBox(width: 8),
                            Text('cash'.tr(ref)),
                          ],
                        ),
                        value: PaymentMethod.cash,
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() => _selectedPaymentMethod = value!);
                        },
                      ),
                      RadioListTile<PaymentMethod>(
                       title: Row(
                          children: [
                            const Icon(Icons.credit_card, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text('card'.tr(ref)),
                          ],
                        ),
                        value: PaymentMethod.card,
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() => _selectedPaymentMethod = value!);
                        },
                      ),
                      RadioListTile<PaymentMethod>(
                       title: Row(
                          children: [
                            const Icon(Icons.phone_android, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text('digital_wallet'.tr(ref)),
                          ],
                        ),
                        value: PaymentMethod.digital,
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() => _selectedPaymentMethod = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Process Payment Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _processPayment(booking),
                  icon: _isProcessing
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isProcessing ? 'processing'.tr(ref) : 'confirm_payment'.tr(ref),
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ]
            else ...[
              // Simple Payment Completed Section
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'payment_completed'.tr(ref),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const Spacer(),
                      if (booking.paymentMethod != null)
                        Text(
                          _getPaymentMethodName(booking.paymentMethod!, ref),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Request Refund Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showRefundDialog(booking),
                  icon: const Icon(Icons.receipt_long, color: Colors.orange),
                  label: Text('request_refund'.tr(ref)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildCarInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600], 
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                fontSize: 14.sp,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, double amount, {Color? color, required WidgetRef ref}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14.sp),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ${'currency'.tr(ref)}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(PaymentMethod method, WidgetRef ref) {
    switch (method) {
      case PaymentMethod.cash:
        return 'cash'.tr(ref);
      case PaymentMethod.card:
        return 'card'.tr(ref);
      case PaymentMethod.digital:
        return 'digital_wallet'.tr(ref);
    }
  }

  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data()?['name'] ?? 'Unknown Customer';
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
    return 'Unknown Customer';
  }

  Future<void> _showRefundDialog(BookingEntity booking) async {
    final reasonController = TextEditingController();
    final refundAmountController = TextEditingController(
      text: booking.totalCost.toStringAsFixed(2),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('request_refund'.tr(ref)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'booking'.tr(ref).replaceAll(':', '')}: #${booking.id.substring(0, 8)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  '${'original_amount'.tr(ref)}${booking.totalCost.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: refundAmountController,
                  decoration: InputDecoration(
                    labelText: 'refund_amount'.tr(ref),
                    prefixText: '${'currency'.tr(ref)} ',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'reason_refund'.tr(ref),
                    border: const OutlineInputBorder(),
                    hintText: 'enter_reason'.tr(ref),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('cancel'.tr(ref)),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('please_enter_reason'.tr(ref)),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('submit_request'.tr(ref)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final user = ref.read(authViewModelProvider).user;
        final refundAmount = double.tryParse(refundAmountController.text) ?? booking.totalCost;
        
        await RefundRepository().createRefundRequest(
          bookingId: booking.id,
          originalAmount: booking.totalCost,
          refundAmount: refundAmount,
          reason: reasonController.text.trim(),
          requestedBy: user?.id ?? 'cashier',
          originalPaymentMethod: booking.paymentMethod?.toString().split('.').last,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('refund_submitted'.tr(ref)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}