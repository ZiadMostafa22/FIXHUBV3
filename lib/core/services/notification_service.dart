import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:car_maintenance_system_new/core/models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize FCM for push notifications
  Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Notification permission granted');
        
        // Re-enable auto-init
        await _messaging.setAutoInitEnabled(true);
        
        // Get FCM token
        String? token = await _messaging.getToken();
        debugPrint('📱 FCM Token: $token');
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      } else {
        debugPrint('Notification permission denied');
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Send in-app notification (creates DB record only, no email/SMS)
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationCategory category,
    String? bookingId,
    String? carId,
  }) async {
    try {
      // Check for duplicate notification (same title, message, bookingId within last 5 seconds)
      final now = DateTime.now();
      final fiveSecondsAgo = now.subtract(const Duration(seconds: 5));
      
      final duplicateCheck = await _firestore
          .collection('user_notifications')
          .where('userId', isEqualTo: userId)
          .where('title', isEqualTo: title)
          .where('message', isEqualTo: message)
          .where('sentAt', isGreaterThan: Timestamp.fromDate(fiveSecondsAgo))
          .limit(1)
          .get();
      
      if (duplicateCheck.docs.isNotEmpty) {
        debugPrint('Duplicate notification prevented: $title');
        return; // Don't send duplicate
      }

      // Create notification record
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: NotificationType.inApp,
        category: category,
        title: title,
        message: message,
        sentAt: now,
        bookingId: bookingId,
        carId: carId,
        metadata: {
          'createdAt': now.toIso8601String(),
        },
      );

      // Save to Firestore
      await _firestore
          .collection('user_notifications')
          .add(notification.toFirestore());

      debugPrint('Notification sent to user $userId: $title');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // Send booking confirmation notification
  Future<void> sendBookingConfirmation({
    required String userId,
    required String bookingId,
    required String carInfo,
    required DateTime scheduledDate,
    required String timeSlot,
  }) async {
    final message = '''Your booking has been confirmed!

Car: $carInfo
Date: ${scheduledDate.toString().split(' ')[0]}
Time: $timeSlot

Booking ID: ${bookingId.substring(0, 8)}

We look forward to serving you!''';

    await sendNotification(
      userId: userId,
      title: 'Booking Confirmed',
      message: message,
      category: NotificationCategory.booking,
      bookingId: bookingId,
    );
  }

  // Send appointment reminder (24 hours before)
  Future<void> sendAppointmentReminder({
    required String userId,
    required String bookingId,
    required String carInfo,
    required DateTime scheduledDate,
    required String timeSlot,
  }) async {
    final message = '''Reminder: Your service appointment is tomorrow!

Car: $carInfo
Date: ${scheduledDate.toString().split(' ')[0]}
Time: $timeSlot

See you soon!''';

    await sendNotification(
      userId: userId,
      title: '⏰ Appointment Reminder',
      message: message,
      category: NotificationCategory.reminder,
      bookingId: bookingId,
    );
  }

  // Send service completed notification
  Future<void> sendServiceCompleted({
    required String userId,
    required String bookingId,
    required String carInfo,
    required double totalCost,
  }) async {
    final message = '''Your service has been completed!

Car: $carInfo
Total: \$${totalCost.toStringAsFixed(2)}

Please proceed to payment.''';

    await sendNotification(
      userId: userId,
      title: 'Service Completed',
      message: message,
      category: NotificationCategory.booking,
      bookingId: bookingId,
    );
  }

  // Send payment completed notification
  Future<void> sendPaymentCompleted({
    required String userId,
    required String bookingId,
    required double amount,
  }) async {
    final message = '''Payment received successfully!

Amount: \$${amount.toStringAsFixed(2)}
Booking ID: ${bookingId.substring(0, 8)}

Thank you for your business!''';

    await sendNotification(
      userId: userId,
      title: 'Payment Completed',
      message: message,
      category: NotificationCategory.payment,
      bookingId: bookingId,
    );
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground message: ${message.notification?.title}');
    // Show in-app notification snackbar or dialog
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('user_notifications')
          .doc(notificationId)
          .update({'read': true});
      debugPrint('Marked notification as read: $notificationId');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
      debugPrint('Marked all notifications as read for user $userId');
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  // Get user notifications stream
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    // Query without orderBy to avoid composite index requirement
    return _firestore
        .collection('user_notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc.data(), doc.id))
              .toList();
          // Sort in memory
          notifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));
          return notifications.take(50).toList();
        });
  }

  // Get unread count
  Stream<int> getUnreadCount(String userId) {
    // Simple query without composite index
    return _firestore
        .collection('user_notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => (doc.data()['read'] ?? false) == false)
            .length);
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('user_notifications')
          .doc(notificationId)
          .delete();
      debugPrint('Deleted notification: $notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('📬 Background message: ${message.notification?.title}');
}
