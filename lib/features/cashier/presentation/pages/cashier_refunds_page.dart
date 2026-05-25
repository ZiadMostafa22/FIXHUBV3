import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/refunds/domain/entities/refund_entity.dart';
import 'package:car_maintenance_system_new/features/refunds/data/repositories/refund_repository.dart';
import 'package:car_maintenance_system_new/core/services/notification_service.dart';
import 'package:car_maintenance_system_new/core/models/notification_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

// Model to hold refund with extra details
class RefundWithDetails {
  final RefundEntity refund;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? carMake;
  final String? carModel;
  final String? carYear;
  final String? licensePlate;
  final String? serviceType;
  final DateTime? bookingDate;

  RefundWithDetails({
    required this.refund,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.carMake,
    this.carModel,
    this.carYear,
    this.licensePlate,
    this.serviceType,
    this.bookingDate,
  });

  String get carInfo {
    if (carMake == null) return 'N/A';
    return '$carYear $carMake $carModel';
  }
}

class CashierRefundsPage extends ConsumerStatefulWidget {
  const CashierRefundsPage({super.key});

  @override
  ConsumerState<CashierRefundsPage> createState() => _CashierRefundsPageState();
}

class _CashierRefundsPageState extends ConsumerState<CashierRefundsPage> with SingleTickerProviderStateMixin {
  final RefundRepository _refundRepo = RefundRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late TabController _tabController;
  bool _isLoading = true;
  List<RefundWithDetails> _pendingRefunds = [];
  List<RefundWithDetails> _completedRefunds = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRefunds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRefunds() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get all refunds
      final snapshot = await _firestore
          .collection('refunds')
          .get();

      final refunds = snapshot.docs
          .map((doc) => RefundEntity.fromFirestore(doc.data(), doc.id))
          .where((r) => r.status == RefundStatus.approved || r.status == RefundStatus.processed)
          .toList();

      debugPrint('🔍 Found ${refunds.length} refunds to process');

      // Collect all unique booking, user, and car IDs
      final Set<String> bookingIds = refunds.map((r) => r.bookingId).toSet();
      
      // Batch fetch all bookings first
      final Map<String, Map<String, dynamic>> bookingsData = {};
      final Set<String> userIds = {};
      final Set<String> carIds = {};
      
      debugPrint('Batch fetching ${bookingIds.length} bookings');
      
      final bookingFutures = bookingIds.map((bookingId) async {
        try {
          final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
          if (bookingDoc.exists) {
            final data = bookingDoc.data()!;
            bookingsData[bookingId] = data;
            if (data['userId'] != null) userIds.add(data['userId']);
            if (data['carId'] != null) carIds.add(data['carId']);
          }
        } catch (e) {
          debugPrint('Error fetching booking $bookingId: $e');
        }
      });
      
      await Future.wait(bookingFutures);
      
      debugPrint('Batch fetching ${userIds.length} users and ${carIds.length} cars');
      
      // Batch fetch all users and cars in parallel
      final Map<String, Map<String, dynamic>> usersData = {};
      final Map<String, Map<String, dynamic>> carsData = {};
      
      final userFutures = userIds.map((userId) async {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            usersData[userId] = userDoc.data()!;
          }
        } catch (e) {
          debugPrint('Error fetching user $userId: $e');
        }
      });
      
      final carFutures = carIds.map((carId) async {
        try {
          final carDoc = await _firestore.collection('cars').doc(carId).get();
          if (carDoc.exists) {
            carsData[carId] = carDoc.data()!;
          }
        } catch (e) {
          debugPrint('Error fetching car $carId: $e');
        }
      });
      
      await Future.wait([...userFutures, ...carFutures]);
      
      debugPrint('Batch fetch complete! Processing refunds...');
      
      // Now build refunds with details from cached data
      final List<RefundWithDetails> refundsWithDetails = [];
      
      for (var refund in refunds) {
        final bookingData = bookingsData[refund.bookingId];
        
        String? customerName;
        String? customerPhone;
        String? customerEmail;
        String? carMake;
        String? carModel;
        String? carYear;
        String? licensePlate;
        String? serviceType;
        DateTime? bookingDate;
        
        if (bookingData != null) {
          final userId = bookingData['userId'] as String?;
          final carId = bookingData['carId'] as String?;
          serviceType = bookingData['maintenanceType'] as String?;
          
          if (bookingData['scheduledDate'] != null) {
            bookingDate = (bookingData['scheduledDate'] as Timestamp).toDate();
          }
          
          // Get user data from cache
          if (userId != null && usersData.containsKey(userId)) {
            final userData = usersData[userId]!;
            customerName = userData['name'] as String?;
            customerPhone = userData['phone'] as String?;
            customerEmail = userData['email'] as String?;
          }
          
          // Get car data from cache
          if (carId != null && carsData.containsKey(carId)) {
            final carData = carsData[carId]!;
            carMake = carData['make'] as String?;
            carModel = carData['model'] as String?;
            carYear = carData['year']?.toString();
            licensePlate = carData['licensePlate'] as String?;
          }
        }
        
        refundsWithDetails.add(RefundWithDetails(
          refund: refund,
          customerName: customerName,
          customerPhone: customerPhone,
          customerEmail: customerEmail,
          carMake: carMake,
          carModel: carModel,
          carYear: carYear,
          licensePlate: licensePlate,
          serviceType: serviceType,
          bookingDate: bookingDate,
        ));
        }

      // Sort by date descending
      refundsWithDetails.sort((a, b) => b.refund.requestedAt.compareTo(a.refund.requestedAt));

      // Separate into pending and completed
      final pending = refundsWithDetails
          .where((r) => r.refund.status == RefundStatus.approved)
          .toList();
      final completed = refundsWithDetails
          .where((r) => r.refund.status == RefundStatus.processed)
          .toList();

      debugPrint('Loaded ${pending.length} pending and ${completed.length} completed refunds');

      setState(() {
        _pendingRefunds = pending;
        _completedRefunds = completed;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading refunds: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _processRefund(RefundWithDetails refundDetails) async {
    try {
      // Mark refund as processed
      await _refundRepo.processRefund(refundDetails.refund.id);
      
      // Get customer ID from booking to send notification
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(refundDetails.refund.bookingId)
          .get();
      
      final customerId = bookingDoc.data()?['userId'] as String?;
      
      // Send notification to customer
      if (customerId != null) {
        await NotificationService().sendNotification(
          userId: customerId,
          title: 'refund_processed'.tr(ref),
          message: '${'your_refund'.tr(ref)} ${refundDetails.refund.refundAmount.toStringAsFixed(2)} ${'currency'.tr(ref)} ${'has_been_processed'.tr(ref)} ${'money_returned_via'.tr(ref)} ${refundDetails.refund.refundMethod ?? "original payment method"}.',
          category: NotificationCategory.payment,
          bookingId: refundDetails.refund.bookingId,
        );
      }
      
      // Reload list
      await _loadRefunds();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('refund_processed_notified'.tr(ref)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('phone_not_available'.tr(ref))),
      );
      return;
    }
    
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('refunds'.tr(ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRefunds,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('pending'.tr(ref)),
                  if (_pendingRefunds.isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingRefunds.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'completed'.tr(ref)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                      SizedBox(height: 16.h),
                      Text('Error: $_error'),
                      SizedBox(height: 16.h),
                      ElevatedButton(onPressed: _loadRefunds, child: Text('retry'.tr(ref))),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Pending Refunds Tab
                    _buildRefundsList(_pendingRefunds, isPending: true),
                    // Completed Refunds Tab
                    _buildRefundsList(_completedRefunds, isPending: false),
                  ],
                ),
    );
  }

  Widget _buildRefundsList(List<RefundWithDetails> refunds, {required bool isPending}) {
    if (refunds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            Icon(
              isPending ? Icons.hourglass_empty : Icons.check_circle_outline,
              size: 64.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              isPending ? 'no_pending_refunds'.tr(ref) : 'no_completed_refunds'.tr(ref),
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: refunds.length,
      itemBuilder: (context, index) {
        final refundDetails = refunds[index];
        return _buildRefundCard(refundDetails, isPending: isPending);
      },
    );
  }

  Widget _buildRefundCard(RefundWithDetails refundDetails, {required bool isPending}) {
    final refund = refundDetails.refund;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: isPending ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending 
            ? BorderSide(color: Colors.orange.shade300, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showRefundDetailsDialog(refundDetails, isPending),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
              CircleAvatar(
                backgroundColor: isPending ? Colors.orange.shade100 : Colors.green.shade100,
                radius: 24.r,
                child: Icon(
                  isPending ? Icons.pending_actions : Icons.check_circle,
                  color: isPending ? Colors.orange : Colors.green,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                      refundDetails.customerName ?? 'Unknown Customer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isPending ? Colors.orange : Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPending ? 'pending'.tr(ref).toUpperCase() : 'completed'.tr(ref).toUpperCase(),
                                    style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            refundDetails.carInfo,
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                    SizedBox(height: 4.h),
                    Text(
                      DateFormat('MMM d, yyyy • HH:mm').format(refund.requestedAt),
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                  Text(
                    '${refund.refundAmount.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  Text(
                    'refund'.tr(ref),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                            ),
                    ),
                  ],
              ),
            ],
          ),
        ),
                ),
    );
  }

  void _showRefundDetailsDialog(RefundWithDetails refundDetails, bool isPending) {
    final refund = refundDetails.refund;
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Container(
          width: 0.9.sw,
          constraints: BoxConstraints(
            maxHeight: 0.8.sh,
            maxWidth: 0.9.sw,
          ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
              // Header
                Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange : Colors.green,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    topRight: Radius.circular(12.r),
                  ),
                  ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                  child: Text(
                        'refund_details'.tr(ref),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                  ),
                ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                ),
              ],
            ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Information
                      _buildDialogSection(
                        dialogContext,
                        'customer_info'.tr(ref),
                        [
                          _buildDialogInfoRow('name'.tr(ref).replaceAll(':', ''), refundDetails.customerName ?? 'unknown'.tr(ref)),
                          _buildDialogInfoRow('phone'.tr(ref).replaceAll(':', ''), refundDetails.customerPhone ?? 'N/A', 
                              isPhone: true, onTap: () => _callCustomer(refundDetails.customerPhone)),
                          if (refundDetails.customerEmail != null)
                            _buildDialogInfoRow('email'.tr(ref).replaceAll(':', ''), refundDetails.customerEmail!),
                        ],
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Vehicle Information
                      _buildDialogSection(
                        dialogContext,
                        'vehicle_info'.tr(ref),
                        [
                          _buildDialogInfoRow('vehicle'.tr(ref).replaceAll(':', ''), refundDetails.carInfo),
                          if (refundDetails.licensePlate != null)
                            _buildDialogInfoRow('license_plate'.tr(ref).replaceAll(':', ''), refundDetails.licensePlate!),
                        ],
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Booking Details
                      _buildDialogSection(
                        dialogContext,
                        'booking_details'.tr(ref),
                        [
                          _buildDialogInfoRow('booking_id'.tr(ref).replaceAll(':', ''), '#${refund.bookingId.substring(0, 8)}'),
                          if (refundDetails.serviceType != null)
                            _buildDialogInfoRow('service'.tr(ref).replaceAll(':', ''), _formatServiceType(refundDetails.serviceType!, ref)),
                          if (refundDetails.bookingDate != null)
                            _buildDialogInfoRow('date'.tr(ref).replaceAll(':', ''), DateFormat('MMM d, yyyy').format(refundDetails.bookingDate!)),
                        ],
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Refund Details
                      _buildDialogSection(
                        dialogContext,
                        'refund_details'.tr(ref),
                        [
                          _buildDialogInfoRow('reason'.tr(ref).replaceAll(':', ''), refund.reason),
                          if (refund.customerNotes != null && refund.customerNotes!.isNotEmpty)
                            _buildDialogInfoRow('notes'.tr(ref).replaceAll(':', ''), refund.customerNotes!),
                          _buildDialogInfoRow('original_amount'.tr(ref).replaceAll(':', ''), '${refund.originalAmount.toStringAsFixed(2)} ${'currency'.tr(ref)}'),
                          if (refund.refundMethod != null)
                            _buildDialogInfoRow('payment_method'.tr(ref).replaceAll(':', ''), refund.refundMethod!.toUpperCase()),
                        ],
                      ),
                      
                      SizedBox(height: 20.h),
            
                      // Amount to Refund Box
            Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
              ),
                        child: Column(
                children: [
                            Text(
                              'Amount to Refund',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                  Text(
                    '${refund.refundAmount.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                    style: TextStyle(
                                fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                    ),
                  ),
                ],
                ),
              ),
            
            // Completed info
                      if (!isPending && refund.processedAt != null) ...[
                        SizedBox(height: 20.h),
              Container(
                          padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  '${'processed_on'.tr(ref)}${DateFormat('MMM d, yyyy \'at\' HH:mm').format(refund.processedAt!)}',
                                  style: TextStyle(color: Colors.green.shade700, fontSize: 13.sp),
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
              
              // Footer
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${'requested'.tr(ref)}${DateFormat('MMM dd, HH:mm').format(refund.requestedAt)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    if (isPending)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showProcessDialog(refundDetails);
                        },
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: Text('process'.tr(ref)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          minimumSize: Size(0, 32.h),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          minimumSize: Size(0, 32.h),
                        ),
                        child: Text(
                          'close'.tr(ref),
                          style: TextStyle(fontSize: 12.sp),
                        ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDialogSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8.h),
        ...children,
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildDialogInfoRow(String label, String value, {bool isPhone = false, VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: isPhone && onTap != null
                ? GestureDetector(
                    onTap: onTap,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.phone, size: 14.sp, color: Colors.blue),
                      ],
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(fontSize: 11.sp),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
          ),
        ],
      ),
    );
  }

  String _formatServiceType(String type, WidgetRef ref) {
    switch (type.toLowerCase()) {
      case 'regular':
        return 'regular_maintenance'.tr(ref);
      case 'inspection':
        return 'inspection'.tr(ref);
      case 'repair':
        return 'repair_service'.tr(ref);
      case 'emergency':
        return 'emergency_service'.tr(ref);
      default:
        return type;
    }
  }

  Future<void> _showProcessDialog(RefundWithDetails refundDetails) async {
    final refund = refundDetails.refund;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28.sp),
              SizedBox(width: 8.w),
              Text('confirm_refund'.tr(ref)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                  'confirm_refund_message'.tr(ref),
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              SizedBox(height: 16.h),
                
                // Customer summary
              Container(
                padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${'customer'.tr(ref)}${refundDetails.customerName ?? "unknown".tr(ref)}'),
                      if (refundDetails.customerPhone != null)
                        Text('${'phone'.tr(ref)}${refundDetails.customerPhone}'),
                      Text('${'vehicle'.tr(ref)}${refundDetails.carInfo}'),
                    ],
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Amount
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                ),
                  child: Column(
                  children: [
                      Text('amount_to_refund'.tr(ref)),
                      SizedBox(height: 4.h),
                    Text(
                      '${refund.refundAmount.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      if (refund.refundMethod != null)
                        Text(
                          '${'via'.tr(ref)} ${refund.refundMethod!.toUpperCase()}',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
                
                SizedBox(height: 12.h),
              Text(
                  '${'this_action_cannot_be_undone'.tr(ref)} ${'customer_will_be_notified'.tr(ref)}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
              ),
            ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('cancel'.tr(ref)),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.check),
              label: Text('yes_refund_completed'.tr(ref)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _processRefund(refundDetails);
    }
  }
}
