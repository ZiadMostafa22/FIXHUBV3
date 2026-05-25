import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/settings_page.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/notifications_page.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class AppDrawer extends ConsumerWidget {
  final String role;
  
  const AppDrawer({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            accountName: Text(
              user?.name ?? 'User',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: TextStyle(fontSize: 12.sp),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: Text('dashboard'.tr(ref)),
                  onTap: () {
                    Navigator.pop(context);
                    if (role == 'admin') context.go('/admin');
                    else if (role == 'cashier') context.go('/cashier');
                    else if (role == 'technician') context.go('/technician');
                    else context.go('/customer');
                  },
                ),
                
                if (role == 'admin') ...[
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: Text('users'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/admin/users');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.work),
                    title: Text('technicians_nav'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/admin/technicians');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.book_online),
                    title: Text('bookings'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/admin/bookings');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics),
                    title: Text('analytics'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/admin/analytics');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_offer),
                    title: Text('manage_offers'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/offers');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.vpn_key),
                    title: Text('invite_codes'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/invite-codes');
                    },
                  ),
                ],

                if (role == 'cashier') ...[
                  ListTile(
                    leading: const Icon(Icons.payment),
                    title: Text('payments_nav'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/cashier/payments');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('refunds'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/cashier/refunds');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: Text('reports'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/cashier/reports');
                    },
                  ),
                ],

                if (role == 'technician') ...[
                  ListTile(
                    leading: const Icon(Icons.work),
                    title: Text('jobs'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/technician/jobs');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.smart_toy),
                    title: Text('ai_chat'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/technician/chatbot');
                    },
                  ),
                ],

                if (role == 'customer') ...[
                  ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text('my_cars'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/customer/cars');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.book_online),
                    title: Text('my_bookings'.tr(ref)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/customer/bookings');
                    },
                  ),
                ],
                
                const Divider(),
                
                Consumer(
                  builder: (context, ref, child) {
                    final unreadAsync = ref.watch(unreadCountProvider);
                    return ListTile(
                      leading: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4, right: 4),
                            child: Icon(Icons.notifications),
                          ),
                          unreadAsync.when(
                            data: (count) => count > 0
                                ? Container(
                                    padding: EdgeInsets.all(2.w),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 14.w,
                                      minHeight: 14.w,
                                    ),
                                    child: Text(
                                      count > 9 ? '9+' : '$count',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      title: Text('notifications'.tr(ref)),
                      onTap: () {
                        Navigator.pop(context);
                        if (role == 'admin') {
                          context.push('/admin/notifications');
                        } else if (role == 'cashier') {
                          context.push('/cashier/notifications');
                        } else if (role == 'technician') {
                          context.push('/technician/notifications');
                        } else if (role == 'customer') {
                          context.push('/customer/notifications');
                        }
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text('settings_and_profile'.tr(ref)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'sign_out'.tr(ref),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('sign_out'.tr(ref)),
                        content: Text('are_you_sure_signout'.tr(ref)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('cancel'.tr(ref)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(authViewModelProvider.notifier).signOut();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: Text('sign_out'.tr(ref)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
