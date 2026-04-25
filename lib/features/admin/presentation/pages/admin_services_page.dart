import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:car_maintenance_system_new/core/models/service_item_model.dart';
import 'package:car_maintenance_system_new/core/repositories/service_repository.dart';
import 'package:car_maintenance_system_new/core/constants/service_items_constants.dart';

final serviceRepositoryProvider = Provider((ref) => ServiceRepository());

final servicesStreamProvider = StreamProvider<List<ServiceItemEntity>>((ref) {
  final repo = ref.watch(serviceRepositoryProvider);
  return repo.getServices();
});

class AdminServicesPage extends ConsumerStatefulWidget {
  const AdminServicesPage({super.key});

  @override
  ConsumerState<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends ConsumerState<AdminServicesPage> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Migrate Services',
            onPressed: () => _showMigrateDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Padding(
            padding: EdgeInsets.all(16.w),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('all', 'All'),
                  SizedBox(width: 8.w),
                  _buildCategoryChip('regular', 'Regular'),
                  SizedBox(width: 8.w),
                  _buildCategoryChip('inspection', 'Inspection'),
                  SizedBox(width: 8.w),
                  _buildCategoryChip('repair', 'Repair'),
                  SizedBox(width: 8.w),
                  _buildCategoryChip('emergency', 'Emergency'),
                ],
              ),
            ),
          ),
          // Service list
          Expanded(
            child: servicesAsync.when(
              data: (services) {
                final filteredServices = _selectedCategory == 'all'
                    ? services
                    : services.where((s) => s.category == _selectedCategory).toList();

                if (filteredServices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_circle_outlined, size: 64.sp, color: Colors.grey),
                        SizedBox(height: 16.h),
                        Text('No services found', style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
                        SizedBox(height: 8.h),
                        ElevatedButton.icon(
                          onPressed: () => _showAddServiceDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Service'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) {
                    final service = filteredServices[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(service.type).withOpacity(0.2),
                          child: Icon(
                            _getTypeIcon(service.type),
                            color: _getTypeColor(service.type),
                          ),
                        ),
                        title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${service.type.toString().split('.').last} • ${service.category ?? 'N/A'}'),
                            Text(
                              '${service.price.toStringAsFixed(0)} EGP',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            switch (value) {
                              case 'edit':
                                _showEditServiceDialog(context, service);
                                break;
                              case 'delete':
                                await _deleteService(service);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServiceDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedCategory == value,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? value : 'all';
        });
      },
    );
  }

  IconData _getTypeIcon(ServiceItemType type) {
    switch (type) {
      case ServiceItemType.part:
        return Icons.settings;
      case ServiceItemType.labor:
        return Icons.engineering;
      case ServiceItemType.service:
        return Icons.build;
    }
  }

  Color _getTypeColor(ServiceItemType type) {
    switch (type) {
      case ServiceItemType.part:
        return Colors.blue;
      case ServiceItemType.labor:
        return Colors.orange;
      case ServiceItemType.service:
        return Colors.green;
    }
  }

  Future<void> _deleteService(ServiceItemEntity service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(serviceRepositoryProvider).deleteService(service.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting service: $e')),
          );
        }
      }
    }
  }

  void _showAddServiceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    ServiceItemType selectedType = ServiceItemType.service;
    String selectedCategory = 'regular';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Service Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (EGP)',
                    suffixText: 'EGP',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<ServiceItemType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ServiceItemType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  )).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
                  },
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ['regular', 'inspection', 'repair', 'emergency'].map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat[0].toUpperCase() + cat.substring(1)),
                  )).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceController.text);
                if (nameController.text.isEmpty || price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in required fields')),
                  );
                  return;
                }

                final service = ServiceItemEntity(
                  id: '',
                  name: nameController.text,
                  type: selectedType,
                  price: price,
                  category: selectedCategory,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                );

                try {
                  await ref.read(serviceRepositoryProvider).createService(service);
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Service added successfully')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding service: $e')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, ServiceItemEntity service) {
    final nameController = TextEditingController(text: service.name);
    final priceController = TextEditingController(text: service.price.toString());
    final descriptionController = TextEditingController(text: service.description ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (EGP)',
                  suffixText: 'EGP',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text);
              if (nameController.text.isEmpty || price == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in required fields')),
                );
                return;
              }

              try {
                await ref.read(serviceRepositoryProvider).updateService(service.id, {
                  'name': nameController.text,
                  'price': price,
                  'description': descriptionController.text.isEmpty ? null : descriptionController.text,
                });
                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service updated successfully')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating service: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMigrateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Migrate Services'),
        content: const Text(
          'This will import all services from the hardcoded constants to Firestore. '
          'This is a one-time operation. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _migrateServices();
            },
            child: const Text('Migrate'),
          ),
        ],
      ),
    );
  }

  Future<void> _migrateServices() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري استيراد الخدمات...')),
      );

      // Seed all services from constants (Arabic names, EGP prices)
      final allServices = ServiceItemsConstants.all
          .map((s) => ServiceItemEntity(
                id: '',
                name: s.name,
                type: s.type,
                price: s.price,
                category: s.category,
                description: s.description,
              ))
          .toList();

      await ref.read(serviceRepositoryProvider).bulkCreateServices(allServices);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم استيراد ${allServices.length} خدمة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الاستيراد: $e')),
        );
      }
    }
  }
}
