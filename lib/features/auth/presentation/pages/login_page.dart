import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // Pass empty role - auth viewmodel will auto-detect from Firestore
      final success = await ref.read(authViewModelProvider.notifier).signIn(
        _emailController.text.trim(),
        _passwordController.text,
        '', // Empty role triggers auto-detection in auth_viewmodel
      );
      
      if (!success && mounted) {
        final errorMessage = ref.read(authViewModelProvider).error ?? 'login_failed'.tr(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      // If success, navigation is handled automatically by the router
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 1.sh - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40.h),
                  
                  // Logo and Title
                  Column(
                    children: [
                      Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                        child: Icon(
                          Icons.car_repair,
                          size: 50.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'app_title'.tr(ref),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 24.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'sign_in_to_account'.tr(ref),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Login Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(fontSize: 14.sp),
                          decoration: InputDecoration(
                            labelText: 'email'.tr(ref),
                            labelStyle: TextStyle(fontSize: 14.sp),
                            prefixIcon: Icon(Icons.email, size: 20.sp),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 16.h,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'enter_email_validation'.tr(ref);
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(fontSize: 14.sp),
                          decoration: InputDecoration(
                            labelText: 'password'.tr(ref),
                            labelStyle: TextStyle(fontSize: 14.sp),
                            prefixIcon: Icon(Icons.lock, size: 20.sp),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 16.h,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                size: 20.sp,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'enter_password_validation'.tr(ref);
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleLogin,
                            child: authState.isLoading
                                ? SizedBox(
                                    height: 20.w,
                                    width: 20.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text('sign_in'.tr(ref), style: TextStyle(fontSize: 16.sp)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Register Link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'dont_have_account'.tr(ref) + ' ',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.sp,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'sign_up'.tr(ref),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
