import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/customer_bottom_nav_bar.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class CustomerCarsPage extends ConsumerStatefulWidget {
  const CustomerCarsPage({super.key});

  @override
  ConsumerState<CustomerCarsPage> createState() => _CustomerCarsPageState();
}

class _CustomerCarsPageState extends ConsumerState<CustomerCarsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        ref.read(carViewModelProvider.notifier).loadCars(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final carState = ref.watch(carViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('my_cars'.tr(ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/customer/add-car');
            },
          ),
        ],
      ),
      body: carState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : carState.cars.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_car,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_cars_registered'.tr(ref),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'add_first_car'.tr(ref),
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/customer/add-car'),
                        icon: const Icon(Icons.add),
                        label: Text('add_car'.tr(ref)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: carState.cars.length,
                  itemBuilder: (context, index) {
                    final car = carState.cars[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.directions_car, size: 30),
                        ),
                        title: Text(
                          '${car.make} ${car.model}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('${'year'.tr(ref)}${car.year}'),
                            Text('${'color'.tr(ref)}${car.color}'),
                            Text('${'license_plate'.tr(ref)}${car.licensePlate}'),
                            if (car.vin != null) Text('${'vin'.tr(ref)}${car.vin}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text('delete'.tr(ref)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'delete') {
                              // Capture the ScaffoldMessenger before showing dialog
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text('delete_car'.tr(ref)),
                                  content: Text(
                                    'delete_car_confirm'.tr(ref),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, false),
                                      child: Text('cancel'.tr(ref)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, true),
                                      child: Text(
                                        'delete'.tr(ref),
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final success = await ref
                                    .read(carViewModelProvider.notifier)
                                    .deleteCar(car.id);
                                
                                // Use the captured ScaffoldMessenger instead of context
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'car_deleted_successfully'.tr(ref)
                                          : 'failed_delete_car'.tr(ref),
                                    ),
                                    backgroundColor:
                                        success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: CustomerBottomNavBar(context: context),
    );
  }
}
