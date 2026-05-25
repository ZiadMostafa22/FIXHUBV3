import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';
import 'package:car_maintenance_system_new/core/models/user_model.dart' as app_models;

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
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

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isLoading: true)) {
    // Check if user is already signed in
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final firebaseUser = FirebaseService.auth.currentUser;
      if (firebaseUser != null) {
        // Load user profile from Firestore
        final doc = await FirebaseService.usersCollection.doc(firebaseUser.uid).get();
        if (doc.exists) {
          final userData = app_models.UserModel.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
          state = state.copyWith(
            userRole: userData.role.toString().split('.').last,
            userName: userData.name,
            userEmail: userData.email,
            userPhone: userData.phone,
            userId: firebaseUser.uid,
            isLoading: false,
          );
          return;
        }
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
      
      // Sign in with Firebase Auth
      final userCredential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (kDebugMode) {
        debugPrint('✓ Firebase Auth successful, UID: ${userCredential.user?.uid}');
      }
      
      if (userCredential.user == null) {
        throw 'Login failed: No user returned';
      }
      
      // Load user profile
      if (kDebugMode) {
        debugPrint('📄 Loading user profile from Firestore...');
      }
      
      final doc = await FirebaseService.usersCollection.doc(userCredential.user!.uid).get();
      
      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint('Firestore document not found!');
          debugPrint('User profile data has been deleted');
        }
        
        // User exists in Firebase Auth but not in Firestore
        // This happens when the Firestore users collection is deleted
        await FirebaseService.auth.signOut();
        state = state.copyWith(isLoading: false);
        
        throw 'Your account profile was not found. The user data may have been deleted. Please contact the administrator to restore your account or delete this account from Firebase Authentication and re-register.';
      }
      
      final userData = app_models.UserModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      
      final userRoleString = userData.role.toString().split('.').last;
      
      if (kDebugMode) {
        debugPrint('✓ Firestore profile loaded: ${userData.name}, role: $userRoleString');
        debugPrint('✓ Account active status: ${userData.isActive}');
      }
      
      // Check if account is active
      if (!userData.isActive) {
        await FirebaseService.auth.signOut();
        if (kDebugMode) {
          debugPrint('Account is disabled');
        }
        throw 'Your account has been disabled by the administrator. Please contact support for assistance.';
      }
      
      // Verify role matches (or auto-login if role doesn't match but exists)
      if (userRoleString != role) {
        if (kDebugMode) {
          debugPrint('Role mismatch: Selected $role, but user is $userRoleString');
          debugPrint('🔄 Logging in with correct role: $userRoleString');
        }
        
        // Don't fail - just use the correct role from Firestore
        // This prevents users from being locked out due to role selection
      }
      
      // Update state with user info (use role from Firestore, not selected role)
      state = AuthState(
        userRole: userRoleString,
        userName: userData.name,
        userEmail: userData.email,
        userPhone: userData.phone,
        userId: userCredential.user!.uid,
        isLoading: false,
        error: null,
      );
      
      if (kDebugMode) {
        debugPrint('Login successful: ${userData.name} as $userRoleString');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Login error: $e');
      }
      await FirebaseService.auth.signOut();
      
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
        errorMessage = errorMessage
            .replaceAll(RegExp(r'\[.*?\]'), '')
            .trim();
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
      
      // SECURITY: Validate role and invite code
      if (kDebugMode) {
        debugPrint('🔒 Step 1: Security validation...');
      }
      
      // Force customer role if no invite code provided (security measure)
      String validatedRole = role;
      if (role == 'technician' || role == 'admin' || role == 'cashier') {
        if (inviteCode == null || inviteCode.isEmpty) {
          if (kDebugMode) {
            debugPrint('Security: Attempted to register as $role without invite code. Forcing customer role.');
          }
          validatedRole = 'customer';
        } else {
          // Validate invite code from Firestore
          if (kDebugMode) {
            debugPrint('🔍 Validating invite code...');
          }
          
          final inviteSnapshot = await FirebaseService.firestore
              .collection('invite_codes')
              .where('code', isEqualTo: inviteCode)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();
          
          if (inviteSnapshot.docs.isEmpty) {
            throw 'Invalid or expired invite code. Please contact the administrator.';
          }
          
          final inviteData = inviteSnapshot.docs.first.data();
          final inviteRole = inviteData['role'] as String;
          
          // Verify role matches invite code
          if (inviteRole != role) {
            throw 'This invite code is for $inviteRole accounts, not $role accounts.';
          }
          
          // Check if invite code has usage limit
          final usedCount = (inviteData['usedCount'] ?? 0) as int;
          final maxUses = (inviteData['maxUses'] ?? 1) as int;
          
          if (usedCount >= maxUses) {
            throw 'This invite code has reached its usage limit. Please contact the administrator.';
          }
          
          if (kDebugMode) {
            debugPrint('✓ Invite code validated for $role role');
          }
        }
      }
      
      // Create user in Firebase Auth
      if (kDebugMode) {
        debugPrint('📝 Step 2: Creating Firebase Auth user...');
      }
      
      final userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (kDebugMode) {
        debugPrint('✓ Firebase Auth user created!');
        debugPrint('UID: ${userCredential.user?.uid}');
        debugPrint('Email: ${userCredential.user?.email}');
      }
      
      if (userCredential.user == null) {
        throw 'Registration failed: No user returned';
      }
      
      // Parse role string to UserRole enum (use validated role)
      if (kDebugMode) {
        debugPrint('📝 Step 3: Parsing role...');
      }
      
      app_models.UserRole userRole;
      switch (validatedRole) {
        case 'customer':
          userRole = app_models.UserRole.customer;
          break;
        case 'technician':
          userRole = app_models.UserRole.technician;
          break;
        case 'admin':
          userRole = app_models.UserRole.admin;
          break;
        case 'cashier':
          userRole = app_models.UserRole.cashier;
          break;
        default:
          userRole = app_models.UserRole.customer;
      }
      
      if (kDebugMode) {
        debugPrint('✓ Role parsed: $userRole');
      }
      
      // Mark invite code as used and get invite code ID (if technician or admin)
      String? inviteCodeDocId;
      if (validatedRole != 'customer' && inviteCode != null && inviteCode.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('📝 Step 4: Marking invite code as used...');
        }
        
        final inviteSnapshot = await FirebaseService.firestore
            .collection('invite_codes')
            .where('code', isEqualTo: inviteCode)
            .limit(1)
            .get();
        
        if (inviteSnapshot.docs.isNotEmpty) {
          final inviteDoc = inviteSnapshot.docs.first;
          inviteCodeDocId = inviteDoc.id; // Save the document ID for later reference
          final currentUsedCount = (inviteDoc.data()['usedCount'] ?? 0) as int;
          final maxUses = (inviteDoc.data()['maxUses'] ?? 1) as int;
          
          // Increment used count
          await inviteDoc.reference.update({
            'usedCount': currentUsedCount + 1,
            'isActive': (currentUsedCount + 1) < maxUses, // Deactivate if limit reached
            'lastUsedAt': FieldValue.serverTimestamp(),
            'usedBy': FieldValue.arrayUnion([userCredential.user!.uid]),
          });
          
          if (kDebugMode) {
            debugPrint('✓ Invite code marked as used (${currentUsedCount + 1}/$maxUses)');
            debugPrint('✓ Invite code ID: $inviteCodeDocId');
          }
        }
      }
      
      // Create user profile in Firestore
      if (kDebugMode) {
        debugPrint('📝 Step 5: Creating Firestore document...');
      }
      
      final userModel = app_models.UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: userRole,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        inviteCodeId: inviteCodeDocId, // Store reference to invite code
        inviteCode: inviteCode,        // Store the actual code string
      );
      
      if (kDebugMode) {
        debugPrint('User Model created: ${userModel.toFirestore()}');
      }
      
      await FirebaseService.usersCollection.doc(userCredential.user!.uid).set(userModel.toFirestore());
      
      if (kDebugMode) {
        debugPrint('✓ Firestore document created!');
      }
      
      // Update state with user info
      if (kDebugMode) {
        debugPrint('📝 Step 6: Updating app state...');
      }
      
      state = AuthState(
        userRole: role,
        userName: name,
        userEmail: email,
        userPhone: phone,
        userId: userCredential.user!.uid,
        isLoading: false,
        error: null,
      );
      
      if (kDebugMode) {
        debugPrint('✓ State updated!');
        debugPrint('═══════════════════════════════════════════════');
        debugPrint('REGISTRATION SUCCESSFUL!');
        debugPrint('User: $name ($email)');
        debugPrint('Role: $role');
        debugPrint('UID: ${userCredential.user!.uid}');
        debugPrint('═══════════════════════════════════════════════');
      }
      
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════');
        debugPrint('REGISTRATION FAILED!');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $stackTrace');
        debugPrint('═══════════════════════════════════════════════');
      }
      
      // Clean up if Firestore write failed
      try {
        await FirebaseService.auth.currentUser?.delete();
        if (kDebugMode) {
          debugPrint('🗑️ Cleaned up failed Firebase Auth user');
        }
      } catch (cleanupError) {
        if (kDebugMode) {
          debugPrint('Cleanup error: $cleanupError');
        }
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
        errorMessage = errorMessage
            .replaceAll(RegExp(r'\[.*?\]'), '')
            .trim();
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
      await FirebaseService.auth.signOut();
      state = AuthState(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
