import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PaymentReportData {
  final String bookingId;
  final DateTime paidAt;
  final double totalAmount;
  final double laborCost;
  final double partsCost;
  final double profit;
  final String paymentMethod;
  final String customerName;
  final String carInfo;
  final String serviceType;

  PaymentReportData({
    required this.bookingId,
    required this.paidAt,
    required this.totalAmount,
    required this.laborCost,
    required this.partsCost,
    required this.profit,
    required this.paymentMethod,
    required this.customerName,
    required this.carInfo,
    required this.serviceType,
  });
}

class CashierReportsPage extends ConsumerStatefulWidget {
  const CashierReportsPage({super.key});

  @override
  ConsumerState<CashierReportsPage> createState() => _CashierReportsPageState();
}

class _CashierReportsPageState extends ConsumerState<CashierReportsPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  List<PaymentReportData> _payments = [];
  String? _error;
  bool _showAllTime = false;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get all paid bookings
      Query query = _firestore.collection('bookings').where('isPaid', isEqualTo: true);
      
      final snapshot = await query.get();
      
      debugPrint('🔍 Found ${snapshot.docs.length} paid bookings');
      
      // Collect all unique user and car IDs
      final Set<String> userIds = {};
      final Set<String> carIds = {};
      final List<Map<String, dynamic>> bookingsData = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get payment date
        DateTime? paidAt;
        if (data['paidAt'] != null) {
          paidAt = (data['paidAt'] as Timestamp).toDate();
        } else if (data['completedAt'] != null) {
          paidAt = (data['completedAt'] as Timestamp).toDate();
        } else {
          continue; // Skip if no date
        }

        // Filter by date range (if not showing all time)
        if (!_showAllTime) {
          final startOfDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
          final endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
          
          if (paidAt.isBefore(startOfDay) || paidAt.isAfter(endOfDay)) {
            continue;
          }
        }

        // Store booking data with date
        bookingsData.add({
          'doc': doc,
          'data': data,
          'paidAt': paidAt,
        });
        
        // Collect IDs for batch fetching
        if (data['userId'] != null) userIds.add(data['userId']);
        if (data['carId'] != null) carIds.add(data['carId']);
      }
      
      debugPrint('Batch fetching ${userIds.length} users and ${carIds.length} cars');
      
      // Batch fetch all users and cars in parallel
      final Map<String, String> userNames = {};
      final Map<String, String> carInfos = {};
        
      // Fetch users in parallel
      final userFutures = userIds.map((userId) async {
          try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
            userNames[userId] = userDoc.data()?['name'] ?? 'Unknown';
            }
          } catch (e) {
          debugPrint('Error fetching user $userId: $e');
          }
      });
        
      // Fetch cars in parallel
      final carFutures = carIds.map((carId) async {
          try {
          final carDoc = await _firestore.collection('cars').doc(carId).get();
            if (carDoc.exists) {
              final carData = carDoc.data()!;
            carInfos[carId] = '${carData['year']} ${carData['make']} ${carData['model']}';
            }
          } catch (e) {
          debugPrint('Error fetching car $carId: $e');
          }
      });
      
      // Wait for all fetches to complete
      await Future.wait([...userFutures, ...carFutures]);
      
      debugPrint('Batch fetch complete! Processing payments...');
      
      // Now process all bookings
      final List<PaymentReportData> payments = [];
      
      for (var bookingData in bookingsData) {
        final doc = bookingData['doc'];
        final data = bookingData['data'];
        final paidAt = bookingData['paidAt'];

        // Calculate costs and profit
        final totalAmount = (data['totalCost'] as num?)?.toDouble() ?? 0.0;
        final laborCost = (data['laborCost'] as num?)?.toDouble() ?? 0.0;
        
        // Calculate parts selling price from serviceItems
        double partsSellingPrice = 0.0;
        if (data['serviceItems'] != null) {
          final items = data['serviceItems'] as List;
          for (var item in items) {
            final itemData = item as Map<String, dynamic>;
            final type = itemData['type'] as String?;
            
            // Only count parts, not labor/service
            if (type == 'part') {
              final price = (itemData['price'] as num?)?.toDouble() ?? 0.0;
              final quantity = (itemData['quantity'] as num?)?.toInt() ?? 1;
              partsSellingPrice += (price * quantity);
            }
          }
        }
        
        // Estimate parts cost (assume 70% of selling price is cost, 30% is profit margin)
        final partsCost = partsSellingPrice * 0.7;
        
        // Calculate profit: Total - Labor - Parts Cost - Tax
        final profit = totalAmount - laborCost - partsCost;
        
        // Get customer name from cache
        final customerName = userNames[data['userId']] ?? 'Unknown';
        
        // Get car info from cache
        final carInfo = carInfos[data['carId']] ?? 'N/A';
        
        payments.add(PaymentReportData(
          bookingId: doc.id,
          paidAt: paidAt,
          totalAmount: totalAmount,
          laborCost: laborCost,
          partsCost: partsCost,
          profit: profit,
          paymentMethod: data['paymentMethod']?.toString() ?? 'cash',
          customerName: customerName,
          carInfo: carInfo,
          serviceType: data['maintenanceType']?.toString() ?? 'N/A',
        ));
      }

      // Sort by date descending
      payments.sort((a, b) => b.paidAt.compareTo(a.paidAt));
      
      debugPrint('Loaded ${payments.length} payments successfully');

      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('Error loading payments: $e\n$stack');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToCSV() async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('creating_report'.tr(ref)),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Create CSV content
      StringBuffer csv = StringBuffer();
      
      // BOM for Excel UTF-8 support
      csv.write('\uFEFF');
      
      // Header row
      csv.writeln('Date,Booking ID,Customer,Car,Service Type,Payment Method,Total Amount,Labor Cost,Parts Cost,Profit');
      
      // Helper to escape CSV strings
      String _csvEscape(String text) {
        return '"${text.replaceAll('"', '""')}"';
      }

      // Data rows
      for (var payment in _payments) {
        csv.writeln(
          '${DateFormat('yyyy-MM-dd HH:mm').format(payment.paidAt)},'
          '${payment.bookingId.substring(0, 8)},'
          '${_csvEscape(payment.customerName)},'
          '${_csvEscape(payment.carInfo)},'
          '${_csvEscape(payment.serviceType)},'
          '${payment.paymentMethod.toUpperCase()},'
          '${payment.totalAmount.toStringAsFixed(2)},'
          '${payment.laborCost.toStringAsFixed(2)},'
          '${payment.partsCost.toStringAsFixed(2)},'
          '${payment.profit.toStringAsFixed(2)}'
        );
      }
      
      // Prepare filename
      final dateRange = _showAllTime 
          ? 'all_time'
          : '${DateFormat('yyyy-MM-dd').format(_startDate)}_to_${DateFormat('yyyy-MM-dd').format(_endDate)}';
      final fileName = 'FixHub_Report_$dateRange.csv';
      
      // Get directory and save file (no permission needed for app-specific storage)
      Directory directory;
      String filePath;
      String displayPath;
      
      if (Platform.isAndroid) {
        // On Android 10+, use app-specific external storage (no permission needed)
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Create a "Downloads" subfolder in app storage
          final downloadsDir = Directory('${externalDir.path}/Downloads');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          directory = downloadsDir;
          displayPath = 'Internal Storage/Android/data/com.fixhub.app/files/Downloads';
        } else {
          directory = await getApplicationDocumentsDirectory();
          displayPath = 'App Documents';
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
        displayPath = 'App Documents';
      } else {
        directory = await getApplicationDocumentsDirectory();
        displayPath = 'App Documents';
      }
      
      filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csv.toString(), encoding: utf8);
      
      debugPrint('File saved to: $filePath');
      
      if (mounted) {
        // Show success dialog with option to open file
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('File Saved'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'csv_saved_successfully'.tr(ref),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'location'.tr(ref),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayPath,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'You can access this file using any file manager app',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('close'.tr(ref)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final result = await OpenFile.open(filePath);
                  if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('install_csv_viewer_tip'.tr(ref)),
                        action: SnackBarAction(
                          label: 'OK',
                          onPressed: () {},
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.folder_open),
                label: Text('open_file'.tr(ref)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Export error: $e');
      debugPrint('Stack trace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('financial_reports'.tr(ref)),
        actions: [
              if (_payments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'export_csv'.tr(ref),
              onPressed: _exportToCSV,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              switch (value) {
                case 'today':
                  setState(() {
                    _startDate = DateTime.now();
                    _endDate = DateTime.now();
                    _showAllTime = false;
                  });
                  _loadPayments();
                  break;
                case 'week':
                  setState(() {
                    _startDate = DateTime.now().subtract(const Duration(days: 7));
                    _endDate = DateTime.now();
                    _showAllTime = false;
                  });
                  _loadPayments();
                  break;
                case 'month':
                  setState(() {
                    _startDate = DateTime.now().subtract(const Duration(days: 30));
                    _endDate = DateTime.now();
                    _showAllTime = false;
                  });
                  _loadPayments();
                  break;
                case 'all':
                  setState(() {
                    _showAllTime = true;
                  });
                  _loadPayments();
                  break;
                case 'custom':
                  _selectDateRange();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'today', child: Text('today'.tr(ref))),
              PopupMenuItem(value: 'week', child: Text('last_7_days'.tr(ref))),
              PopupMenuItem(value: 'month', child: Text('last_30_days'.tr(ref))),
              PopupMenuItem(value: 'all', child: Text('all_time'.tr(ref))),
              PopupMenuItem(value: 'custom', child: Text('custom_range'.tr(ref))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor.withOpacity(0.1), Theme.of(context).primaryColor.withOpacity(0.05)],
              ),
            ),
            child: Text(
              _showAllTime 
                  ? '📊 ${'all_time_report'.tr(ref)}'
                  : '📊 ${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
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
                            ElevatedButton(
                              onPressed: _loadPayments,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Calculate totals
    double totalRevenue = 0;
    double totalLaborCost = 0;
    double totalPartsCost = 0;
    double totalProfit = 0;
    
    Map<String, double> paymentMethods = {};
    Map<String, int> paymentMethodsCount = {};

    for (var payment in _payments) {
      totalRevenue += payment.totalAmount;
      totalLaborCost += payment.laborCost;
      totalPartsCost += payment.partsCost;
      totalProfit += payment.profit;
      
      paymentMethods[payment.paymentMethod] = 
          (paymentMethods[payment.paymentMethod] ?? 0) + payment.totalAmount;
      paymentMethodsCount[payment.paymentMethod] = 
          (paymentMethodsCount[payment.paymentMethod] ?? 0) + 1;
    }

    final profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0;

    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              'no_payments_found'.tr(ref),
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
            SizedBox(height: 8.h),
            Text(
              _showAllTime ? 'no_paid_bookings_in_db'.tr(ref) : 'try_different_range'.tr(ref),
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main KPIs
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'total_revenue'.tr(ref),
                  '${totalRevenue.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                  Colors.blue,
                  Icons.attach_money,
                  subtitle: '${_payments.length} ${'transactions'.tr(ref)}',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _kpiCard(
                  'total_profit'.tr(ref),
                  '${totalProfit.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                  Colors.green,
                  Icons.trending_up,
                  subtitle: '${profitMargin.toStringAsFixed(1)}% ${'margin'.tr(ref)}',
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Cost Breakdown
          Row(
            children: [
              Expanded(
                child: _costCard('labor_cost'.tr(ref), '${totalLaborCost.toStringAsFixed(2)} ${'currency'.tr(ref)}', Colors.orange),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _costCard('parts_cost'.tr(ref), '${totalPartsCost.toStringAsFixed(2)} ${'currency'.tr(ref)}', Colors.purple),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Payment Methods Breakdown
          Text(
            'payment_methods'.tr(ref),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),
          
          ...paymentMethods.entries.map((entry) {
            final method = entry.key;
            final amount = entry.value;
            final count = paymentMethodsCount[method] ?? 0;
            final percentage = (amount / totalRevenue * 100);
            
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _getPaymentColor(method).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getPaymentColor(method).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_getPaymentIcon(method), color: _getPaymentColor(method), size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                        ),
                        Text(
                          '$count ${'transactions'.tr(ref)}',
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${amount.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: _getPaymentColor(method),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          SizedBox(height: 24.h),

          // Transaction List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'transactions'.tr(ref)} (${_payments.length})',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              if (_payments.isNotEmpty)
                TextButton.icon(
                  onPressed: _exportToCSV,
                  icon: const Icon(Icons.file_download, size: 18),
                  label: Text('export_csv'.tr(ref)),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // Transaction List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _payments.length,
            itemBuilder: (context, index) {
              final payment = _payments[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8.h),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPaymentColor(payment.paymentMethod).withOpacity(0.2),
                    child: Icon(
                      _getPaymentIcon(payment.paymentMethod),
                      color: _getPaymentColor(payment.paymentMethod),
                      size: 20.sp,
                    ),
                  ),
                  title: Text(
                    payment.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${DateFormat('MMM d, HH:mm').format(payment.paidAt)} • ${payment.paymentMethod.toUpperCase()}',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${payment.totalAmount.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '${'profit'.tr(ref)}: ${payment.profit.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: payment.profit >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('booking_id'.tr(ref), '#${payment.bookingId.substring(0, 8)}'),
                          _detailRow('vehicle'.tr(ref), payment.carInfo),
                          _detailRow('service'.tr(ref), payment.serviceType),
                          Divider(height: 24.h),
                          _detailRow('total_amount'.tr(ref), '${payment.totalAmount.toStringAsFixed(2)} ${'currency'.tr(ref)}', isBold: true),
                          _detailRow('labor_cost'.tr(ref), '${payment.laborCost.toStringAsFixed(2)} ${'currency'.tr(ref)}'),
                          _detailRow('parts_cost'.tr(ref), '${payment.partsCost.toStringAsFixed(2)} ${'currency'.tr(ref)}'),
                          Divider(height: 16.h),
                          _detailRow(
                            'profit'.tr(ref),
                            '${payment.profit.toStringAsFixed(2)} ${'currency'.tr(ref)}',
                            isBold: true,
                            color: payment.profit >= 0 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color, IconData icon, {String? subtitle}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28.sp),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12.sp),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10.sp),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _costCard(String label, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'digital':
      case 'wallet':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'digital':
      case 'wallet':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _showAllTime = false;
      });
      _loadPayments();
    }
  }
}
