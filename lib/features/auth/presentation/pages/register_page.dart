import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showInviteCode = false;
  String _selectedRole = 'customer';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authViewModelProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        inviteCode: _showInviteCode ? _inviteCodeController.text.trim() : null,
      );
      
      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('account_created'.tr(ref)),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Navigation is handled automatically by the router
      } else if (mounted) {
        final errorMessage = ref.read(authViewModelProvider).error ?? 'registration_failed'.tr(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // Responsive sizing
    final logoSize = screenHeight * 0.08 < 60 ? 60.0 : (screenHeight * 0.08 > 80 ? 80.0 : screenHeight * 0.08);
    final horizontalPadding = screenWidth * 0.06 < 16 ? 16.0 : (screenWidth * 0.06 > 24 ? 24.0 : screenWidth * 0.06);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('create_account'.tr(ref)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, keyboardHeight + 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Column(
                  children: [
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(logoSize / 2),
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: logoSize * 0.5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Text(
                      'join_car_maintenance'.tr(ref),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.055 < 18 ? 18.0 : (screenWidth * 0.055 > 24 ? 24.0 : screenWidth * 0.055),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                      'create_account_subtitle'.tr(ref),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontSize: screenWidth * 0.038 < 13 ? 13.0 : (screenWidth * 0.038 > 15 ? 15.0 : screenWidth * 0.038),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
                SizedBox(height: screenHeight * 0.025),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'full_name'.tr(ref),
                    prefixIcon: const Icon(Icons.person),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'enter_name_validation'.tr(ref);
                    }
                    if (value.length < 2) {
                      return 'name_min_length'.tr(ref);
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.015),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'email'.tr(ref),
                    prefixIcon: const Icon(Icons.email),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'enter_email_validation'.tr(ref);
                    }
                    if (!value.contains('@')) {
                      return 'invalid_email'.tr(ref);
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.015),
                
                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'phone_number'.tr(ref),
                    prefixIcon: const Icon(Icons.phone),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'enter_phone_validation'.tr(ref);
                    }
                    if (value.length < 10) {
                      return 'invalid_phone'.tr(ref);
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.015),
                
                // Account Type Selection (Secure)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: Text('customer_account'.tr(ref)),
                        subtitle: Text('customer_account_desc'.tr(ref)),
                        value: 'customer',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = 'customer';
                            _showInviteCode = false;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: Text('technician_account'.tr(ref)),
                        subtitle: Text('technician_account_desc'.tr(ref)),
                        value: 'technician',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = 'technician';
                            _showInviteCode = true;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: Text('cashier_account'.tr(ref)),
                        subtitle: Text('cashier_account_desc'.tr(ref)),
                        value: 'cashier',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = 'cashier';
                            _showInviteCode = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                
                // Invite Code Field (Only for Technicians/Cashiers)
                if (_showInviteCode)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _inviteCodeController,
                        decoration: InputDecoration(
                          labelText: 'invite_code'.tr(ref),
                          prefixIcon: const Icon(Icons.vpn_key),
                          isDense: true,
                          helperText: 'invite_code_hint'.tr(ref),
                          helperMaxLines: 2,
                        ),
                        validator: (value) {
                          if (_showInviteCode && (value == null || value.isEmpty)) {
                            return 'invite_code_required'.tr(ref);
                          }
                          if (_showInviteCode && value!.length < 6) {
                            return 'invalid_invite_code'.tr(ref);
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.015),
                    ],
                  ),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'password'.tr(ref),
                    prefixIcon: const Icon(Icons.lock),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                    if (value.length < 6) {
                      return 'password_min_length'.tr(ref);
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.015),
                
                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'confirm_password'.tr(ref),
                    prefixIcon: const Icon(Icons.lock_outline),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'confirm_password_validation'.tr(ref);
                    }
                    if (value != _passwordController.text) {
                      return 'passwords_dont_match'.tr(ref);
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.025),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleRegister,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('create_account'.tr(ref)),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                
                // Login Link
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'already_have_account'.tr(ref),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: screenWidth * 0.035 < 13 ? 13.0 : (screenWidth * 0.035 > 15 ? 15.0 : screenWidth * 0.035),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'sign_in'.tr(ref),
                        style: TextStyle(
                          fontSize: screenWidth * 0.035 < 13 ? 13.0 : (screenWidth * 0.035 > 15 ? 15.0 : screenWidth * 0.035),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
