import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class CustomerBottomNavBar extends ConsumerWidget {
  final BuildContext context;

  const CustomerBottomNavBar({
    super.key,
    required this.context,
  });

  int _getCurrentIndex(BuildContext ctx) {
    final location = GoRouterState.of(ctx).uri.toString();
    if (location == '/customer' || location == '/customer/') {
      return 0;
    } else if (location.startsWith('/customer/cars')) {
      return 1;
    } else if (location.startsWith('/customer/offers')) {
      return 2;
    } else if (location.startsWith('/customer/chatbot')) {
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext buildContext, WidgetRef ref) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(context),
      selectedFontSize: 12.sp,
      unselectedFontSize: 10.sp,
      iconSize: 24.sp,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/customer');
            break;
          case 1:
            context.go('/customer/cars');
            break;
          case 2:
            context.go('/customer/offers');
            break;
          case 3:
            context.go('/customer/chatbot');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: 'dashboard'.tr(ref),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.directions_car),
          label: 'my_cars'.tr(ref),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.local_offer),
          label: 'offers'.tr(ref),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.chat_bubble),
          label: 'chat'.tr(ref),
        ),
      ],
    );
  }
}

