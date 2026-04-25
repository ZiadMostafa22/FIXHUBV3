import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';
import 'package:car_maintenance_system_new/core/constants/egyptian_cars.dart';

class AddCarPage extends ConsumerStatefulWidget {
  const AddCarPage({super.key});

  @override
  ConsumerState<AddCarPage> createState() => _AddCarPageState();
}

class _AddCarPageState extends ConsumerState<AddCarPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;
  String? _selectedColor;
  CarType _selectedType = CarType.sedan;
  final _plateController = TextEditingController();

  List<String> get _availableModels =>
      _selectedMake != null ? EgyptianCars.modelsFor(_selectedMake!) : [];

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _submitCar() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authViewModelProvider).user;
      if (user == null) return;

      final car = CarEntity(
        id: '',
        userId: user.id,
        make: _selectedMake!,
        model: _selectedModel!,
        year: _selectedYear!,
        color: _selectedColor!,
        licensePlate: _plateController.text.trim(),
        type: _selectedType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await ref.read(carViewModelProvider.notifier).addCar(car);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Car added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  ref.read(carViewModelProvider).error ?? 'Failed to add car'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carState = ref.watch(carViewModelProvider);
    final theme = Theme.of(context);

    const inputDecoration = InputDecoration(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Car'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_car,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Make ───────────────────────────────────────
              Text('Car Make', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedMake,
                decoration:
                    inputDecoration.copyWith(hintText: 'Select car brand'),
                isExpanded: true,
                items: EgyptianCars.makes
                    .map((make) =>
                        DropdownMenuItem(value: make, child: Text(make)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMake = value;
                    _selectedModel = null; // Reset model when make changes
                  });
                },
                validator: (v) => v == null ? 'Please select the car brand' : null,
              ),

              const SizedBox(height: 16),

              // ─── Model ──────────────────────────────────────
              Text('Model', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedModel,
                decoration: inputDecoration.copyWith(
                  hintText: _selectedMake == null
                      ? 'Select brand first'
                      : 'Select model',
                ),
                isExpanded: true,
                items: _availableModels
                    .map((model) =>
                        DropdownMenuItem(value: model, child: Text(model)))
                    .toList(),
                onChanged:
                    _selectedMake == null ? null : (v) => setState(() => _selectedModel = v),
                validator: (v) => v == null ? 'Please select the model' : null,
              ),

              const SizedBox(height: 16),

              // ─── Year ───────────────────────────────────────
              Text('Year', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: inputDecoration.copyWith(hintText: 'Select year'),
                isExpanded: true,
                menuMaxHeight: 250,
                items: EgyptianCars.years
                    .map((y) =>
                        DropdownMenuItem(value: y, child: Text(y.toString())))
                    .toList(),
                onChanged: (v) => setState(() => _selectedYear = v),
                validator: (v) => v == null ? 'Please select the year' : null,
              ),

              const SizedBox(height: 16),

              // ─── Color ──────────────────────────────────────
              Text('Color', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedColor,
                decoration: inputDecoration.copyWith(hintText: 'Select color'),
                isExpanded: true,
                items: EgyptianCars.colors
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedColor = v),
                validator: (v) => v == null ? 'Please select the color' : null,
              ),

              const SizedBox(height: 16),

              // ─── Type ───────────────────────────────────────
              Text('Car Type', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<CarType>(
                value: _selectedType,
                decoration: inputDecoration.copyWith(hintText: 'Select type'),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: CarType.sedan, child: Text('Sedan')),
                  DropdownMenuItem(value: CarType.suv, child: Text('SUV')),
                  DropdownMenuItem(value: CarType.truck, child: Text('Truck / Pickup')),
                  DropdownMenuItem(value: CarType.hatchback, child: Text('Hatchback')),
                  DropdownMenuItem(value: CarType.coupe, child: Text('Coupe')),
                  DropdownMenuItem(value: CarType.van, child: Text('Van / Minivan')),
                ],
                onChanged: (v) => setState(() => _selectedType = v!),
              ),

              const SizedBox(height: 16),

              // ─── Plate Number ───────────────────────────────
              Text('Plate Number *', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _plateController,
                decoration: inputDecoration.copyWith(
                  hintText: 'e.g., 123 أ ب ج',
                  prefixIcon: const Icon(Icons.credit_card),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter plate number' : null,
              ),

              const SizedBox(height: 24),

              // ─── Submit ─────────────────────────────────────
              ElevatedButton.icon(
                onPressed: carState.isLoading ? null : _submitCar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: carState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Add Car', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
