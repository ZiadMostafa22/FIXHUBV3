import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/core/providers/theme_provider.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }
  
  void _loadUserData() {
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authViewModelProvider).user;
      if (user == null) throw 'User not found';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_updated_success'.tr(ref)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_updating_profile'.tr(ref)}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final locale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'settings_and_profile'.tr(ref),
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section (Editable)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30.r,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'personal_information'.tr(ref),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (user?.role ?? 'user').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isEditing)
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 18),
                              label: Text('edit_information'.tr(ref)),
                              onPressed: () {
                                setState(() => _isEditing = true);
                              },
                            )
                          else
                            TextButton.icon(
                              icon: const Icon(Icons.close, size: 18),
                              label: Text('cancel'.tr(ref)),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _loadUserData();
                                });
                              },
                            ),
                        ],
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'full_name'.tr(ref),
                          prefixIcon: const Icon(Icons.person),
                          border: const OutlineInputBorder(),
                        ),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: _isEditing ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'name_required'.tr(ref);
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      
                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'phone_number'.tr(ref),
                          prefixIcon: const Icon(Icons.phone),
                          border: const OutlineInputBorder(),
                        ),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: _isEditing ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'phone_required'.tr(ref);
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      
                      // Email Field (Read-only)
                      TextFormField(
                        initialValue: user?.email ?? '',
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'email'.tr(ref),
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                        ),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      
                      if (_isEditing) ...[
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveProfile,
                            icon: _isLoading 
                                ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save),
                            label: Text(_isLoading ? 'saving'.tr(ref) : 'save_profile'.tr(ref)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Appearance Section
              Text(
                'appearance'.tr(ref),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              
              Card(
                child: Column(
                  children: [
                    // Theme Mode
                    ListTile(
                      leading: Icon(
                        themeMode == ThemeMode.light
                            ? Icons.light_mode
                            : themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : Icons.brightness_auto,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text('theme_mode'.tr(ref)),
                      trailing: DropdownButton<ThemeMode>(
                        value: themeMode,
                        onChanged: (ThemeMode? newValue) {
                          if (newValue != null) {
                            themeNotifier.setThemeMode(newValue);
                          }
                        },
                        items: ThemeMode.values.map<DropdownMenuItem<ThemeMode>>(
                          (ThemeMode value) {
                            return DropdownMenuItem<ThemeMode>(
                              value: value,
                              child: Text(_getThemeModeName(value, ref)),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Language Section
              Text(
                'language'.tr(ref),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('app_language'.tr(ref)),
                  trailing: DropdownButton<String>(
                    value: locale.languageCode,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        if (newValue == 'ar') {
                          localeNotifier.setLocale(const Locale('ar', 'EG'));
                        } else {
                          localeNotifier.setLocale(const Locale('en', 'US'));
                        }
                      }
                    },
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'en',
                        child: Text('English'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'ar',
                        child: Text('العربية (مصر)'),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Notifications Section
              Text(
                'notifications'.tr(ref),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              
              Card(
                child: SwitchListTile(
                  secondary: Icon(
                    Icons.notifications,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('notifications'.tr(ref)),
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // App Info Section
              Text(
                'app_information'.tr(ref),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.info,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text('app_information'.tr(ref)),
                      subtitle: const Text('1.0.0'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    
                    const Divider(height: 1),
                    
                    ListTile(
                      leading: Icon(
                        Icons.help,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text('help_support'.tr(ref)),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    
                    const Divider(height: 1),
                    
                    ListTile(
                      leading: Icon(
                        Icons.privacy_tip,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text('privacy_policy'.tr(ref)),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32.h),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text('sign_out'.tr(ref)),
                        content: Text('are_you_sure_signout'.tr(ref)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text('cancel'.tr(ref)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              await Future.delayed(const Duration(milliseconds: 100));
                              if (mounted) {
                                await ref.read(authViewModelProvider.notifier).signOut();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text('sign_out'.tr(ref)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: Text('sign_out'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(16.w),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode, WidgetRef ref) {
    switch (mode) {
      case ThemeMode.light:
        return 'light'.tr(ref);
      case ThemeMode.dark:
        return 'dark'.tr(ref);
      case ThemeMode.system:
        return 'system'.tr(ref);
    }
  }
}