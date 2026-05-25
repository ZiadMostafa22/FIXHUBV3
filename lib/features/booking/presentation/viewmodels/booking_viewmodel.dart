import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/booking/domain/di/booking_usecases_di.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/get_bookings_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/watch_bookings_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/create_booking_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/update_booking_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/cancel_booking_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/rate_booking_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/process_payment_usecase.dart';
import 'package:car_maintenance_system_new/core/services/notification_service.dart';

final bookingViewModelProvider =
    StateNotifierProvider<BookingViewModel, BookingState>((ref) {
  final getBookingsUseCase = ref.watch(getBookingsUseCaseProvider);
  final watchBookingsUseCase = ref.watch(watchBookingsUseCaseProvider);
  final createBookingUseCase = ref.watch(createBookingUseCaseProvider);
  final updateBookingUseCase = ref.watch(updateBookingUseCaseProvider);
  final cancelBookingUseCase = ref.watch(cancelBookingUseCaseProvider);
  final rateBookingUseCase = ref.watch(rateBookingUseCaseProvider);
  final processPaymentUseCase = ref.watch(processPaymentUseCaseProvider);
  return BookingViewModel(
    getBookingsUseCase,
    watchBookingsUseCase,
    createBookingUseCase,
    updateBookingUseCase,
    cancelBookingUseCase,
    rateBookingUseCase,
    processPaymentUseCase,
  );
});

// Type alias for convenience
typedef Booking = BookingEntity;

class BookingState {
  final List<Booking> bookings;
  final bool isLoading;
  final String? error;

  BookingState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  BookingState copyWith({
    List<Booking>? bookings,
    bool? isLoading,
    String? error,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BookingViewModel extends StateNotifier<BookingState> {
  final GetBookingsUseCase getBookingsUseCase;
  final WatchBookingsUseCase watchBookingsUseCase;
  final CreateBookingUseCase createBookingUseCase;
  final UpdateBookingUseCase updateBookingUseCase;
  final CancelBookingUseCase cancelBookingUseCase;
  final RateBookingUseCase rateBookingUseCase;
  final ProcessPaymentUseCase processPaymentUseCase;
  final NotificationService _notificationService = NotificationService();

  StreamSubscription<List<BookingEntity>>? _bookingsSubscription;
  bool _isFirstUpdate = true;

  BookingViewModel(
    this.getBookingsUseCase,
    this.watchBookingsUseCase,
    this.createBookingUseCase,
    this.updateBookingUseCase,
    this.cancelBookingUseCase,
    this.rateBookingUseCase,
    this.processPaymentUseCase,
  ) : super(BookingState());

  Future<void> loadBookings(String userId, {String? role}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final bookings = await getBookingsUseCase(
        userId: userId,
        role: role,
      );

      if (kDebugMode) {
        print('Loaded ${bookings.length} bookings');
        for (var booking in bookings) {
          print('  - ${booking.id}: ${booking.status}');
        }
      }

      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading bookings: $e');
      }
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Start listening to real-time updates
  void startListening(String userId, {String? role}) {
    // Cancel any existing subscription
    _bookingsSubscription?.cancel();
    
    // Reset first update flag when starting a new listener
    _isFirstUpdate = true;

    _bookingsSubscription = watchBookingsUseCase(
      userId: userId,
      role: role,
    ).listen(
      (bookings) {
        if (kDebugMode) {
          print('🔄 Real-time update: ${bookings.length} bookings');
          for (var booking in bookings.take(3)) {
            print('  - ${booking.id}: ${booking.status}');
          }
          // Debug: Check for bookings with discount info
          for (var booking in bookings) {
            if (booking.offerCode != null || booking.discountPercentage != null) {
              print('Found booking with discount: ${booking.id}');
              print('   - Code: ${booking.offerCode}');
              print('   - Title: ${booking.offerTitle}');
              print('   - %: ${booking.discountPercentage}');
            }
          }
        }

        // On first update, just set the state silently (no notifications)
        // This prevents false notifications when dashboard first opens
        if (_isFirstUpdate) {
          _isFirstUpdate = false;
          state = state.copyWith(bookings: bookings, isLoading: false);
          return;
        }

        // Only update if we have meaningful changes to prevent UI flicker
        if (bookings.length != state.bookings.length ||
            bookings.any((booking) => !state.bookings
                .any((b) => b.id == booking.id && b.status == booking.status))) {
          state = state.copyWith(bookings: bookings, isLoading: false);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error in real-time listener: $error');
        }
        state = state.copyWith(error: error.toString());
      },
    );
  }

  // Stop listening to real-time updates
  void stopListening() {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  Future<bool> createBooking(Booking booking, {String? carInfo}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Debug: Print booking data before saving
      if (kDebugMode) {
        print('📤 Creating booking with data:');
        print('  - ID: ${booking.id}');
        print('  - User ID: ${booking.userId}');
        print('  - Offer Code: ${booking.offerCode}');
        print('  - Offer Title: ${booking.offerTitle}');
        print('  - Discount %: ${booking.discountPercentage}');
      }

      // Add to Firestore - the real-time listener will automatically add it to state
      await createBookingUseCase(booking);

      // Send booking confirmation notification
      try {
        await _notificationService.sendBookingConfirmation(
          userId: booking.userId,
          bookingId: booking.id,
          carInfo: carInfo ?? 'Your vehicle',
          scheduledDate: booking.scheduledDate,
          timeSlot: booking.timeSlot,
        );
        if (kDebugMode) {
          print('📬 Booking confirmation notification sent');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to send notification: $e');
        }
        // Don't fail the booking if notification fails
      }

      if (kDebugMode) {
        print('Booking created successfully - real-time listener will update state');
      }

      state = state.copyWith(isLoading: false);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating booking: $e');
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateBooking(String bookingId, Map<String, dynamic> updates) async {
    try {
      if (kDebugMode) {
        print('📝 Updating booking $bookingId with: $updates');
      }

      // Simple update to Firestore - let real-time listener handle state update
      await updateBookingUseCase(bookingId, updates);

      if (kDebugMode) {
        print('Booking updated successfully - real-time listener will update state');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating booking: $e');
      }
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      if (kDebugMode) {
        print('🚫 Cancelling booking $bookingId');
      }

      // Check if booking exists
      final bookingExists = state.bookings.any((b) => b.id == bookingId);
      if (!bookingExists) {
        if (kDebugMode) {
          print('Booking not found: $bookingId');
        }
        return false;
      }

      // Immediately update local state first to prevent loading issues
      final updatedBookings = state.bookings.map((booking) {
        if (booking.id == bookingId) {
          return booking.copyWith(
            status: BookingStatus.cancelled,
            updatedAt: DateTime.now(),
          );
        }
        return booking;
      }).toList();

      state = state.copyWith(
        bookings: updatedBookings,
        isLoading: false, // Set to false immediately after local update
      );

      // Update Firestore (non-blocking, don't wait for it)
      cancelBookingUseCase(bookingId).then((_) {
        if (kDebugMode) {
          print('Firestore updated successfully for booking: $bookingId');
        }
      }).catchError((error) {
        if (kDebugMode) {
          print('Firestore update error: $error');
        }
        // Don't fail the operation if Firestore update fails
        // The local state is already updated
      });

      if (kDebugMode) {
        print('Booking $bookingId cancelled successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling booking $bookingId: $e');
      }
      // Ensure loading is stopped even on error
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    DateTime? completedAt,
  }) async {
    try {
      // This will be handled by the repository's updateBookingStatus method
      // For now, we'll use updateBooking with status
      // updateBooking will automatically send notifications
      final updates = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      };

      if (completedAt != null) {
        updates['completedAt'] = Timestamp.fromDate(completedAt);
      }

      return await updateBooking(bookingId, updates);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating booking status: $e');
      }
      return false;
    }
  }

  List<Booking> get upcomingBookings {
    return state.bookings
        .where((b) =>
            b.status == BookingStatus.pending ||
            b.status == BookingStatus.confirmed)
        .toList();
  }

  List<Booking> get completedBookings {
    return state.bookings
        .where((b) => b.status == BookingStatus.completed)
        .toList();
  }

  Future<bool> rateBooking(String bookingId, double rating, String comment) async {
    try {
      await rateBookingUseCase(
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );

      // Reload bookings
      if (state.bookings.isNotEmpty) {
        final firstBooking = state.bookings.first;
        await loadBookings(firstBooking.userId);
      }

      return true;
    } catch (e) {
      debugPrint('Error rating booking: $e');
      return false;
    }
  }

  Future<bool> processPayment({
    required String bookingId,
    required String cashierId,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      // Get booking to calculate total cost
      final booking = state.bookings.firstWhere(
        (b) => b.id == bookingId,
        orElse: () => state.bookings.first,
      );
      
      await processPaymentUseCase(
        bookingId: bookingId,
        cashierId: cashierId,
        paymentMethod: paymentMethod,
        totalCost: booking.totalCost, // Save totalCost for reports
      );

      // Send payment completed notification to customer
      try {
        await _notificationService.sendPaymentCompleted(
          userId: booking.userId,
          bookingId: bookingId,
          amount: booking.totalCost,
        );
        if (kDebugMode) {
          print('📬 Payment notification sent to customer');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to send payment notification: $e');
        }
      }

      // Reload bookings using cashier ID with cashier role
      await loadBookings(cashierId, role: 'cashier');

      return true;
    } catch (e) {
      debugPrint('Error processing payment: $e');
      return false;
    }
  }
}
