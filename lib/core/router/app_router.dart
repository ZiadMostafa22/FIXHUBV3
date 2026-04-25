import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/pages/login_page.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/pages/register_page.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/pages/customer_dashboard.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/pages/customer_cars_page.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/pages/customer_bookings_page.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/pages/customer_history_page.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/pages/customer_profile_page.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/pages/customer_offers_page.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/pages/new_booking_page.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/pages/add_car_page.dart';
import 'package:car_maintenance_system_new/features/technician/presentation/pages/technician_dashboard.dart';
import 'package:car_maintenance_system_new/features/technician/presentation/pages/technician_jobs_page.dart';
import 'package:car_maintenance_system_new/features/technician/presentation/pages/technician_profile_page.dart';
import 'package:car_maintenance_system_new/features/technician/presentation/pages/job_details_page.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/pages/admin_dashboard.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/pages/admin_users_page.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/pages/admin_technicians_page.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/pages/admin_bookings_page.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/pages/admin_offers_page.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/pages/admin_analytics_page.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/pages/admin_invite_codes_page.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/pages/admin_services_page.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/pages/admin_refunds_page.dart';
import 'package:car_maintenance_system_new/features/admin/presentation/pages/admin_reports_page.dart';
import 'package:car_maintenance_system_new/features/cashier/presentation/pages/cashier_dashboard.dart';
import 'package:car_maintenance_system_new/features/cashier/presentation/pages/cashier_payments_page.dart';
import 'package:car_maintenance_system_new/features/cashier/presentation/pages/cashier_payment_details_page.dart';
import 'package:car_maintenance_system_new/features/cashier/presentation/pages/cashier_profile_page.dart';
import 'package:car_maintenance_system_new/features/cashier/presentation/pages/cashier_reports_page.dart';
import 'package:car_maintenance_system_new/features/cashier/presentation/pages/cashier_refunds_page.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/notifications_page.dart';
import 'package:car_maintenance_system_new/features/splash/presentation/pages/splash_page.dart';
import 'package:car_maintenance_system_new/features/chatbot/presentation/pages/chatbot_page.dart';

// Create a listenable for auth state changes
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier(this._ref) {
    _ref.listen<AuthState>(
      authViewModelProvider,
      (previous, next) {
        // Notify listeners whenever auth state changes
        if (previous?.userRole != next.userRole ||
            previous?.userId != next.userId ||
            previous?.isLoading != next.isLoading) {
          notifyListeners();
        }
      },
    );
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = AuthStateNotifier(ref);
  
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);
      final isLoading = authState.isLoading;
      final userId = authState.userId;
      final userRole = authState.userRole;
      final isLoggedIn = userId != null && userRole != null;
      
      final currentPath = state.uri.toString();
      
      // Show splash while loading
      if (isLoading) {
        if (currentPath != '/splash') {
          return '/splash';
        }
        return null;
      }
      
      // Redirect to login if not authenticated
      if (!isLoggedIn) {
        if (currentPath == '/splash') {
          return '/login'; // Go to login after splash
        }
        // If user is not logged in and trying to access protected routes, redirect to login
        if (currentPath != '/login' && currentPath != '/register') {
          if (kDebugMode) {
            debugPrint('🔒 User not authenticated, redirecting to login from: $currentPath');
          }
          return '/login';
        }
        return null;
      }
      
      // Redirect based on user role when authenticated
      if (isLoggedIn) {
        if (currentPath == '/splash' || currentPath == '/login' || currentPath == '/register') {
          if (kDebugMode) {
            debugPrint('✅ User authenticated as $userRole, redirecting from: $currentPath');
          }
          switch (userRole) {
            case 'customer':
              return '/customer';
            case 'technician':
              return '/technician';
            case 'admin':
              return '/admin';
            case 'cashier':
              return '/cashier';
            default:
              return '/customer';
          }
        }
        
        // Verify user is accessing correct role-based route
        if (userRole == 'customer' && !currentPath.startsWith('/customer')) {
          if (currentPath.startsWith('/technician') || currentPath.startsWith('/admin')) {
            if (kDebugMode) {
              debugPrint('⚠️ Customer trying to access non-customer route: $currentPath');
            }
            return '/customer';
          }
        } else if (userRole == 'technician' && !currentPath.startsWith('/technician')) {
          if (currentPath.startsWith('/customer') || currentPath.startsWith('/admin')) {
            if (kDebugMode) {
              debugPrint('⚠️ Technician trying to access non-technician route: $currentPath');
            }
            return '/technician';
          }
        } else if (userRole == 'admin' && !currentPath.startsWith('/admin')) {
          if (currentPath.startsWith('/customer') || currentPath.startsWith('/technician') || currentPath.startsWith('/cashier')) {
            if (kDebugMode) {
              debugPrint('⚠️ Admin trying to access non-admin route: $currentPath');
            }
            return '/admin';
          }
        } else if (userRole == 'cashier' && !currentPath.startsWith('/cashier')) {
          if (currentPath.startsWith('/customer') || currentPath.startsWith('/technician') || currentPath.startsWith('/admin')) {
            if (kDebugMode) {
              debugPrint('⚠️ Cashier trying to access non-cashier route: $currentPath');
            }
            return '/cashier';
          }
        }
      }
      
      return null; // No redirect needed
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Authentication
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Customer Routes
      GoRoute(
        path: '/customer',
        builder: (context, state) => const CustomerDashboard(),
        routes: [
          GoRoute(
            path: 'cars',
            builder: (context, state) => const CustomerCarsPage(),
          ),
          GoRoute(
            path: 'add-car',
            builder: (context, state) => const AddCarPage(),
          ),
          GoRoute(
            path: 'bookings',
            builder: (context, state) => const CustomerBookingsPage(),
          ),
          GoRoute(
            path: 'new-booking',
            builder: (context, state) => const NewBookingPage(),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const CustomerHistoryPage(),
          ),
          GoRoute(
            path: 'offers',
            builder: (context, state) => const CustomerOffersPage(),
          ),
          GoRoute(
            path: 'chatbot',
            builder: (context, state) => const ChatbotPage(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const CustomerProfilePage(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
        ],
      ),
      
      // Technician Routes
      GoRoute(
        path: '/technician',
        builder: (context, state) => const TechnicianDashboard(),
        routes: [
          GoRoute(
            path: 'jobs',
            builder: (context, state) => const TechnicianJobsPage(),
          ),
          GoRoute(
            path: 'job-details/:bookingId',
            builder: (context, state) {
              final bookingId = state.pathParameters['bookingId']!;
              return JobDetailsPage(bookingId: bookingId);
            },
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const TechnicianProfilePage(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
        ],
      ),
      
      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const AdminUsersPage(),
          ),
          GoRoute(
            path: 'technicians',
            builder: (context, state) => const AdminTechniciansPage(),
          ),
          GoRoute(
            path: 'bookings',
            builder: (context, state) => const AdminBookingsPage(),
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AdminAnalyticsPage(),
          ),
          GoRoute(
            path: 'invite-codes',
            builder: (context, state) => const AdminInviteCodesPage(),
          ),
          GoRoute(
            path: 'offers',
            builder: (context, state) => const AdminOffersPage(),
          ),
          GoRoute(
            path: 'services',
            builder: (context, state) => const AdminServicesPage(),
          ),

          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: 'refunds',
            builder: (context, state) => const AdminRefundsPage(),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) => const AdminReportsPage(),
          ),
        ],
      ),
      
      // Cashier Routes
      GoRoute(
        path: '/cashier',
        builder: (context, state) => const CashierDashboard(),
        routes: [
          GoRoute(
            path: 'payments',
            builder: (context, state) => const CashierPaymentsPage(),
          ),
          GoRoute(
            path: 'payment/:bookingId',
            builder: (context, state) {
              final bookingId = state.pathParameters['bookingId']!;
              return CashierPaymentDetailsPage(bookingId: bookingId);
            },
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const CashierProfilePage(),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) => const CashierReportsPage(),
          ),
          GoRoute(
            path: 'refunds',
            builder: (context, state) => const CashierRefundsPage(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
        ],
      ),
    ],
  );
});
