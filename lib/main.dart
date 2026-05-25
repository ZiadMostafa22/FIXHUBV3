import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:car_maintenance_system_new/core/theme/app_theme.dart';
import 'package:car_maintenance_system_new/core/router/app_router.dart';
import 'package:car_maintenance_system_new/core/providers/theme_provider.dart';
import 'package:car_maintenance_system_new/firebase_options.dart';
import 'package:car_maintenance_system_new/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully!');

    // Initialize notification service
    try {
      await NotificationService().initialize();
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  
  runApp(
    const ProviderScope(
      child: CarMaintenanceApp(),
    ),
  );
}

class CarMaintenanceApp extends ConsumerWidget {
  const CarMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return ScreenUtilInit(
      // Design size based on standard mobile dimensions (adjust based on your design)
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Car Maintenance System',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}