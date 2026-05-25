import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:car_maintenance_system_new/features/auth/domain/di/auth_usecases_di.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';
import 'package:car_maintenance_system_new/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:car_maintenance_system_new/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:car_maintenance_system_new/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:car_maintenance_system_new/features/auth/domain/usecases/sign_out_usecase.dart';

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final checkAuthStatusUseCase = ref.watch(checkAuthStatusUseCaseProvider);
  final signInUseCase = ref.watch(signInUseCaseProvider);
  final signUpUseCase = ref.watch(signUpUseCaseProvider);
  final signOutUseCase = ref.watch(signOutUseCaseProvider);
  return AuthViewModel(
    checkAuthStatusUseCase,
    signInUseCase,
    signUpUseCase,
    signOutUseCase,
  );
});

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
  });
}

class AuthState {
  final String? userRole;
  final String? userName;
  final bool isLoading;
  final String? error;
  final String? userEmail;
  final String? userPhone;
  final String? userId;

  AuthState({
    this.userRole,
    this.userName,
    this.isLoading = false,
    this.error,
    this.userEmail,
    this.userPhone,
    this.userId,
  });

  User? get user {
    if (userName != null && userRole != null) {
      return User(
        id: userId ?? '',
        name: userName!,
        email: userEmail ?? '',
        role: userRole!,
        phone: userPhone ?? '',
      );
    }
    return null;
  }

  bool get isAuthenticated => userId != null;

  AuthState copyWith({
    String? userRole,
    String? userName,
    bool? isLoading,
    String? error,
    String? userEmail,
    String? userPhone,
    String? userId,
    bool clearError = false,
  }) {
    return AuthState(
      userRole: userRole ?? this.userRole,
      userName: userName ?? this.userName,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userId: userId ?? this.userId,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;

  AuthViewModel(
    this.checkAuthStatusUseCase,
    this.signInUseCase,
    this.signUpUseCase,
    this.signOutUseCase,
  ) : super(AuthState(isLoading: true)) {
    // Check if user is already signed in
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final userEntity = await checkAuthStatusUseCase();
      if (userEntity != null) {
        state = state.copyWith(
          userRole: userEntity.role.toString().split('.').last,
          userName: userEntity.name,
          userEmail: userEntity.email,
          userPhone: userEntity.phone,
          userId: userEntity.id,
          isLoading: false,
        );
        return;
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> signIn(String email, String password, String role) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      if (kDebugMode) {
        debugPrint('🔐 Attempting login with email: $email, role: $role');
      }

      final userEntity = await signInUseCase(
        email: email,
        password: password,
      );

      if (userEntity == null) {
        throw Exception('Login failed: No user returned');
      }

      if (kDebugMode) {
        debugPrint('Login successful: ${userEntity.name}');
      }

      final userRoleString = userEntity.role.toString().split('.').last;

      // Verify role matches (or auto-login if role doesn't match but exists)
      if (userRoleString != role) {
        if (kDebugMode) {
          debugPrint('Role mismatch: Selected $role, but user is $userRoleString');
          debugPrint('🔄 Logging in with correct role: $userRoleString');
        }
      }

      // Update state with user info (use role from Firestore, not selected role)
      state = AuthState(
        userRole: userRoleString,
        userName: userEntity.name,
        userEmail: userEntity.email,
        userPhone: userEntity.phone,
        userId: userEntity.id,
        isLoading: false,
        error: null,
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Login error: $e');
      }

      // Clean error message
      String errorMessage = e.toString();
      if (errorMessage.contains('invalid-credential')) {
        errorMessage = 'Invalid email or password. Please check your credentials and try again.';
      } else if (errorMessage.contains('user-not-found')) {
        errorMessage = 'No account found with this email. Please register first.';
      } else if (errorMessage.contains('wrong-password')) {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (errorMessage.contains('invalid-email')) {
        errorMessage = 'Invalid email format. Please check your email address.';
      } else if (errorMessage.contains('user-disabled')) {
        errorMessage = 'This account has been disabled. Please contact support.';
      } else if (errorMessage.contains('too-many-requests')) {
        errorMessage = 'Too many failed attempts. Please try again later.';
      } else {
        // Remove Firebase error codes
        errorMessage = errorMessage.replaceAll(RegExp(r'\[.*?\]'), '').trim();
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? inviteCode,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════');
        debugPrint('🔐 REGISTRATION START');
        debugPrint('Email: $email');
        debugPrint('Name: $name');
        debugPrint('Phone: $phone');
        debugPrint('Role: $role');
        debugPrint('Invite Code: ${inviteCode != null ? "PROVIDED" : "NONE"}');
        debugPrint('Password length: ${password.length}');
        debugPrint('═══════════════════════════════════════════════');
      }

      // Parse role string to UserRole enum
      UserRole userRole;
      switch (role) {
        case 'customer':
          userRole = UserRole.customer;
          break;
        case 'technician':
          userRole = UserRole.technician;
          break;
        case 'admin':
          userRole = UserRole.admin;
          break;
        case 'cashier':
          userRole = UserRole.cashier;
          break;
        default:
          userRole = UserRole.customer;
      }

      final userEntity = await signUpUseCase(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: userRole,
        inviteCode: inviteCode,
      );

      if (kDebugMode) {
        debugPrint('✓ State updated!');
        debugPrint('═══════════════════════════════════════════════');
        debugPrint('REGISTRATION SUCCESSFUL!');
        debugPrint('User: $name ($email)');
        debugPrint('Role: $role');
        debugPrint('UID: ${userEntity.id}');
        debugPrint('═══════════════════════════════════════════════');
      }

      // Update state with user info
      state = AuthState(
        userRole: role,
        userName: name,
        userEmail: email,
        userPhone: phone,
        userId: userEntity.id,
        isLoading: false,
        error: null,
      );

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════');
        debugPrint('REGISTRATION FAILED!');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $stackTrace');
        debugPrint('═══════════════════════════════════════════════');
      }

      // Clean error message
      String errorMessage = e.toString();
      if (errorMessage.contains('email-already-in-use')) {
        errorMessage = 'This email is already registered. Please login instead.';
      } else if (errorMessage.contains('invalid-email')) {
        errorMessage = 'Invalid email format. Please check your email address.';
      } else if (errorMessage.contains('weak-password')) {
        errorMessage = 'Password is too weak. Please use at least 6 characters.';
      } else if (errorMessage.contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        // Remove Firebase error codes
        errorMessage = errorMessage.replaceAll(RegExp(r'\[.*?\]'), '').trim();
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await signOutUseCase();
      state = AuthState(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

