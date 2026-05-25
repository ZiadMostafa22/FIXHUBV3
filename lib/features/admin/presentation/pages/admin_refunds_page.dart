import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:car_maintenance_system_new/features/refunds/domain/entities/refund_entity.dart';
import 'package:car_maintenance_system_new/features/refunds/data/repositories/refund_repository.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/core/services/notification_service.dart';
import 'package:car_maintenance_system_new/core/models/notification_model.dart';
import 'package:intl/intl.dart';

final refundRepositoryProvider = Provider((ref) => RefundRepository());

final allRefundsProvider = StreamProvider<List<RefundEntity>>((ref) {
  final repo = ref.watch(refundRepositoryProvider);
  return repo.getRefundsStream();
});

class AdminRefundsPage extends ConsumerWidget {
  const AdminRefundsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refundsAsync = ref.watch(allRefundsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Management'),
      ),
      body: refundsAsync.when(
        data: (refunds) {
          final pendingCount = refunds.where((r) => r.status == RefundStatus.requested).length;
          final approvedCount = refunds.where((r) => r.status == RefundStatus.approved).length;

          return Column(
            children: [
              // Summary banners
              if (pendingCount > 0)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions, color: Colors.orange.shade800, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '$pendingCount pending - waiting for approval',
                          style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              if (approvedCount > 0)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  color: Colors.green.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade800, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '$approvedCount approved - pending cashier',
                          style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ),

              // List
              Expanded(
                child: refunds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64.sp, color: Colors.grey),
                            SizedBox(height: 16.h),
                            const Text('No refund requests'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: refunds.length,
                        itemBuilder: (context, index) {
                          final refund = refunds[index];
                          return _RefundCard(refund: refund);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _RefundCard extends ConsumerWidget {
  final RefundEntity refund;

  const _RefundCard({required this.refund});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusChip(refund.status),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy').format(refund.requestedAt),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Booking: ${refund.bookingId.substring(0, 8)}...',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4.h),
            Text('Reason: ${refund.reason}'),
            if (refund.customerNotes != null && refund.customerNotes!.isNotEmpty)
              Text('Notes: ${refund.customerNotes}', style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
            SizedBox(height: 8.h),
            Row(
              children: [
                Text('Original: \$${refund.originalAmount.toStringAsFixed(2)}'),
                SizedBox(width: 16.w),
                Text(
                  'Refund: \$${refund.refundAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
            
            // Action buttons based on status
            if (refund.status == RefundStatus.requested)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _rejectRefund(context, ref, refund),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                    SizedBox(width: 8.w),
                    ElevatedButton(
                      onPressed: () => _approveRefund(context, ref, refund),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              ),
            
            // Show workflow status
            if (refund.status == RefundStatus.approved)
              Container(
                padding: EdgeInsets.all(12.w),
                margin: EdgeInsets.only(top: 12.h),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Waiting for Cashier',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Cashier needs to refund \$${refund.refundAmount.toStringAsFixed(2)} to customer and mark as processed.',
                      style: TextStyle(fontSize: 12.sp, color: Colors.blue.shade600),
                    ),
                  ],
                ),
              ),
            
            if (refund.status == RefundStatus.processed)
              Container(
                padding: EdgeInsets.all(12.w),
                margin: EdgeInsets.only(top: 12.h),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18.sp),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refund Completed',
                          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                        ),
                        if (refund.processedAt != null)
                          Text(
                            'Processed on ${DateFormat('MMM d, yyyy HH:mm').format(refund.processedAt!)}',
                            style: TextStyle(fontSize: 11.sp, color: Colors.green.shade600),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            
            if (refund.status == RefundStatus.rejected)
              Container(
                padding: EdgeInsets.all(12.w),
                margin: EdgeInsets.only(top: 12.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Rejected: ${refund.customerNotes ?? "No reason provided"}',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(RefundStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case RefundStatus.requested:
        color = Colors.orange;
        label = 'Pending Approval';
        break;
      case RefundStatus.approved:
        color = Colors.blue;
        label = 'Approved - Pending Cashier';
        break;
      case RefundStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
      case RefundStatus.processed:
        color = Colors.green;
        label = 'Completed';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.sp),
      ),
    );
  }

  Future<void> _approveRefund(BuildContext context, WidgetRef ref, RefundEntity refund) async {
    final authState = ref.read(authViewModelProvider);
    
    try {
      await ref.read(refundRepositoryProvider).approveRefund(
        refundId: refund.id,
        approvedBy: authState.userId ?? 'admin',
        refundMethod: refund.originalPaymentMethod,
      );
      
      // Send notification to cashier (requestedBy is the cashier who requested)
      await NotificationService().sendNotification(
        userId: refund.requestedBy,
        title: 'Refund Approved',
        message: 'Refund request for \$${refund.refundAmount.toStringAsFixed(2)} has been approved. Please process the refund to the customer.',
        category: NotificationCategory.payment,
        bookingId: refund.bookingId,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refund approved - Cashier notified')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectRefund(BuildContext context, WidgetRef ref, RefundEntity refund) async {
    final authState = ref.read(authViewModelProvider);
    
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Refund'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Rejection Reason',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      try {
        await ref.read(refundRepositoryProvider).rejectRefund(
          refundId: refund.id,
          rejectedBy: authState.userId ?? 'admin',
          rejectionReason: reason,
        );
        
        // Notify cashier
        await NotificationService().sendNotification(
          userId: refund.requestedBy,
          title: 'Refund Rejected',
          message: 'Refund request for \$${refund.refundAmount.toStringAsFixed(2)} was rejected. Reason: $reason',
          category: NotificationCategory.payment,
          bookingId: refund.bookingId,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Refund rejected - Cashier notified')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
