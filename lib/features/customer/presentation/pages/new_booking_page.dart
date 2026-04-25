import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/core/models/offer_model.dart';
import 'package:car_maintenance_system_new/core/utils/discount_validator.dart';

// ─────────────────────────────────────────────────────────────
// Multi-step booking page (3 steps)
// Step 1 → Car + maintenance type
// Step 2 → Service + date & time
// Step 3 → Summary + discount + confirm
// ─────────────────────────────────────────────────────────────
class NewBookingPage extends ConsumerStatefulWidget {
  const NewBookingPage({super.key});

  @override
  ConsumerState<NewBookingPage> createState() => _NewBookingPageState();
}

class _NewBookingPageState extends ConsumerState<NewBookingPage> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1
  String? _selectedCarId;
  MaintenanceType? _selectedMaintenanceType;

  // Step 2
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _descriptionController = TextEditingController();

  // Step 3
  final _discountCodeController = TextEditingController();
  OfferModel? _appliedOffer;
  bool _isValidatingCode = false;

  static const Map<MaintenanceType, _TypeMeta> _typeMeta = {
    MaintenanceType.regular: _TypeMeta(
      label: 'Regular Maintenance',
      icon: Icons.build_circle,
      color: Color(0xFF2196F3),
      hint: 'Oil change, filters, fluids…',
    ),
    MaintenanceType.inspection: _TypeMeta(
      label: 'Inspection',
      icon: Icons.search,
      color: Color(0xFF4CAF50),
      hint: 'Safety check, computer scan…',
    ),
    MaintenanceType.repair: _TypeMeta(
      label: 'Repair',
      icon: Icons.build,
      color: Color(0xFFFF9800),
      hint: 'Brakes, engine, transmission…',
    ),
    MaintenanceType.emergency: _TypeMeta(
      label: 'Emergency',
      icon: Icons.warning_rounded,
      color: Color(0xFFF44336),
      hint: 'Urgent — off-road assistance…',
    ),
  };

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
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _discountCodeController.dispose();
    super.dispose();
  }

  // ── Navigation helpers ──────────────────────────────────────

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  bool get _step1Valid => _selectedCarId != null;

  bool get _step2Valid =>
      _selectedMaintenanceType != null &&
      _selectedDate != null &&
      _selectedTime != null;

  // ── Date & Time pickers ─────────────────────────────────────

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = now.add(const Duration(days: 90));

    bool notFriday(DateTime d) => d.weekday != DateTime.friday;
    DateTime initial = today;
    while (!notFriday(initial) && initial.isBefore(lastDate)) {
      initial = initial.add(const Duration(days: 1));
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: lastDate,
      selectableDayPredicate: notFriday,
      helpText: 'Select Appointment Date (Closed Fridays)',
    );

    if (picked != null && picked.weekday != DateTime.friday) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  Future<void> _selectTime() async {
    if (_selectedDate == null) {
      _showSnack('Please select a date first', Colors.orange);
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Working Hours: 8:00 AM – 6:00 PM',
    );
    if (picked == null) return;
    if (picked.hour < 8 || picked.hour > 18 ||
        (picked.hour == 18 && picked.minute > 0)) {
      if (!mounted) return;
      _showSnack('Please select a time between 8:00 AM and 6:00 PM', Colors.red);
      return;
    }
    setState(() => _selectedTime = picked);
  }

  // ── Discount code ───────────────────────────────────────────

  Future<void> _validateDiscountCode() async {
    final code = _discountCodeController.text.trim();
    if (code.isEmpty) {
      _showSnack('Please enter a discount code', Colors.orange);
      return;
    }
    setState(() => _isValidatingCode = true);
    try {
      final result = await DiscountValidator.validateDiscountCode(code);
      if (!mounted) return;
      setState(() => _isValidatingCode = false);
      if (result['valid'] == true) {
        setState(() => _appliedOffer = result['offer'] as OfferModel);
        _showSnack(result['message'] as String, Colors.green);
      } else {
        setState(() => _appliedOffer = null);
        _showSnack(result['message'] as String, Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isValidatingCode = false);
      _showSnack('Error: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ── Submit ──────────────────────────────────────────────────

  Future<void> _submitBooking() async {
    if (!_step1Valid || !_step2Valid) return;
    if (_selectedDate!.weekday == DateTime.friday) {
      _showSnack('We are closed on Fridays', Colors.red);
      return;
    }

    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final booking = BookingEntity(
      id: '',
      userId: user.id,
      carId: _selectedCarId!,
      serviceId: '',  // Service items are added by the technician after job starts
      maintenanceType: _selectedMaintenanceType!,
      scheduledDate: scheduledDateTime,
      timeSlot: _selectedTime!.format(context),
      status: BookingStatus.pending,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      offerCode: _appliedOffer?.code,
      offerTitle: _appliedOffer?.title,
      discountPercentage: _appliedOffer?.discountPercentage,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success =
        await ref.read(bookingViewModelProvider.notifier).createBooking(booking);

    if (!mounted) return;
    if (success) {
      _showSnack('✅ Booking confirmed!', Colors.green);
      context.pop();
    } else {
      _showSnack(
        ref.read(bookingViewModelProvider).error ?? 'Failed to create booking',
        Colors.red,
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final carState = ref.watch(carViewModelProvider);
    final bookingState = ref.watch(bookingViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Booking'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _StepBadge(index: 0, current: _currentStep, label: 'Your Car'),
                const Expanded(child: Divider()),
                _StepBadge(index: 1, current: _currentStep, label: 'Service'),
                const Expanded(child: Divider()),
                _StepBadge(index: 2, current: _currentStep, label: 'Confirm'),
              ],
            ),
          ),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1(
                  carState: carState,
                  selectedCarId: _selectedCarId,
                  onCarChanged: (v) => setState(() => _selectedCarId = v),
                ),
                _Step2(
                  selectedDate: _selectedDate,
                  selectedTime: _selectedTime,
                  selectedType: _selectedMaintenanceType,
                  typeMeta: _typeMeta,
                  descriptionController: _descriptionController,
                  onSelectDate: _selectDate,
                  onSelectTime: _selectTime,
                  onTypeChanged: (v) =>
                    setState(() => _selectedMaintenanceType = v),
                ),
                _Step3(
                  selectedCar: carState.cars
                      .where((c) => c.id == _selectedCarId)
                      .firstOrNull,
                  selectedDate: _selectedDate,
                  selectedTime: _selectedTime,
                  maintenanceType: _selectedMaintenanceType ?? MaintenanceType.regular,
                  typeMeta: _typeMeta,
                  discountController: _discountCodeController,
                  appliedOffer: _appliedOffer,
                  isValidatingCode: _isValidatingCode,
                  onValidateDiscount: _validateDiscountCode,
                  onRemoveDiscount: () => setState(() {
                    _appliedOffer = null;
                    _discountCodeController.clear();
                  }),
                ),
              ],
            ),
          ),

          // Navigation buttons
          _BottomNav(
            currentStep: _currentStep,
            onBack: _prevStep,
            onNext: () {
              if (_currentStep == 0) {
                if (_selectedCarId == null) {
                  _showSnack('Please select your car first', Colors.orange);
                  return;
                }
              }
              if (_currentStep == 1) {
                if (_selectedMaintenanceType == null) {
                  _showSnack('Please select a maintenance type', Colors.orange);
                  return;
                }
                if (!_step2Valid) {
                  _showSnack('Please select date and time', Colors.orange);
                  return;
                }
              }
              if (_currentStep < 2) {
                _nextStep();
              } else {
                _submitBooking();
              }
            },
            isLoading: bookingState.isLoading,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helper meta class (const allowed)
// ─────────────────────────────────────────────────────────────
class _TypeMeta {
  final String label;
  final IconData icon;
  final Color color;
  final String hint;
  const _TypeMeta(
      {required this.label,
      required this.icon,
      required this.color,
      required this.hint});
}

// ─────────────────────────────────────────────────────────────
// Step badge widget
// ─────────────────────────────────────────────────────────────
class _StepBadge extends StatelessWidget {
  final int index;
  final int current;
  final String label;
  const _StepBadge(
      {required this.index, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDone = index < current;
    final isActive = index == current;
    final color = isDone || isActive
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade400;

    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('${index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom navigation bar
// ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isLoading;
  const _BottomNav(
      {required this.currentStep,
      required this.onBack,
      required this.onNext,
      required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style:
                  OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onNext,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(currentStep < 2 ? Icons.arrow_forward : Icons.check),
            label: Text(currentStep < 2 ? 'Next' : 'Confirm Booking'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 1 — Car selection only
// ─────────────────────────────────────────────────────────────
class _Step1 extends ConsumerWidget {
  final dynamic carState;
  final String? selectedCarId;
  final ValueChanged<String?> onCarChanged;

  const _Step1({
    required this.carState,
    required this.selectedCarId,
    required this.onCarChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Your Car',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (carState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (carState.cars.isEmpty)
            _EmptyCarCard(onAdd: () => context.push('/customer/add-car'))
          else
            ...carState.cars.map<Widget>((car) {
              final isSelected = car.id == selectedCarId;
              return GestureDetector(
                onTap: () => onCarChanged(car.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.06)
                        : null,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade200,
                      child: Icon(Icons.directions_car,
                          color: isSelected ? Colors.white : Colors.grey),
                    ),
                    title: Text('${car.make} ${car.model}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${car.year}  •  ${car.color}  •  ${car.licensePlate}'),
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                ),
              );
            }),
          if (carState.cars.isNotEmpty)
            TextButton.icon(
              onPressed: () => context.push('/customer/add-car'),
              icon: const Icon(Icons.add),
              label: const Text('Add another car'),
            ),
        ],
      ),
    );
  }
}

class _EmptyCarCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCarCard({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.directions_car, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('No cars registered',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Add a car to continue',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add a Car'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 2 — Date & Time
// ─────────────────────────────────────────────────────────────
class _Step2 extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final MaintenanceType? selectedType;
  final Map<MaintenanceType, _TypeMeta> typeMeta;
  final TextEditingController descriptionController;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;
  final ValueChanged<MaintenanceType> onTypeChanged;

  const _Step2({
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedType,
    required this.typeMeta,
    required this.descriptionController,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Maintenance type
          Text('Maintenance Type',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (selectedType == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Please select a maintenance type to continue',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          ...typeMeta.entries.map((entry) {
            final meta = entry.value;
            final isSelected = selectedType == entry.key;
            return GestureDetector(
              onTap: () => onTypeChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? meta.color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? meta.color.withValues(alpha: 0.07) : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: meta.color.withValues(alpha: 0.15),
                      child: Icon(meta.icon, color: meta.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(meta.label,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected ? meta.color : null)),
                          Text(meta.hint,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: meta.color),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Date & Time
          Text('Appointment Date & Time',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Working hours: Sat – Thu, 8:00 AM – 6:00 PM',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateTimeTile(
                  icon: Icons.calendar_month,
                  label: selectedDate == null
                      ? 'Select Date'
                      : DateFormat('EEE, MMM d').format(selectedDate!),
                  onTap: onSelectDate,
                  isSet: selectedDate != null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTimeTile(
                  icon: Icons.access_time,
                  label: selectedTime == null
                      ? 'Select Time'
                      : selectedTime!.format(context),
                  onTap: onSelectTime,
                  isSet: selectedTime != null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Optional description
          Text('Additional Notes (Optional)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Describe your issue or any additional details…',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSet;
  const _DateTimeTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.isSet});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(
              color: isSet ? primary : Colors.grey.shade300,
              width: isSet ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
          color: isSet ? primary.withValues(alpha: 0.06) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSet ? primary : Colors.grey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSet ? FontWeight.w600 : FontWeight.normal,
                    color: isSet ? primary : Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 3 — Summary + Discount + Confirm
// ─────────────────────────────────────────────────────────────
class _Step3 extends StatelessWidget {
  final dynamic selectedCar;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final MaintenanceType maintenanceType;
  final Map<MaintenanceType, _TypeMeta> typeMeta;
  final TextEditingController discountController;
  final OfferModel? appliedOffer;
  final bool isValidatingCode;
  final VoidCallback onValidateDiscount;
  final VoidCallback onRemoveDiscount;

  const _Step3({
    required this.selectedCar,
    required this.selectedDate,
    required this.selectedTime,
    required this.maintenanceType,
    required this.typeMeta,
    required this.discountController,
    required this.appliedOffer,
    required this.isValidatingCode,
    required this.onValidateDiscount,
    required this.onRemoveDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final meta = typeMeta[maintenanceType]!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking Summary',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // Summary card
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow(
                    icon: Icons.directions_car,
                    label: 'Car',
                    value: selectedCar != null
                        ? '${selectedCar!.make} ${selectedCar!.model} (${selectedCar!.year})'
                        : '—',
                  ),
                  const Divider(height: 16),
                  _SummaryRow(
                    icon: meta.icon,
                    label: 'Type',
                    value: meta.label,
                    valueColor: meta.color,
                  ),
                  const Divider(height: 16),
                  _SummaryRow(
                    icon: Icons.build_circle_outlined,
                    label: 'Type',
                    value: meta.label,
                    valueColor: meta.color,
                  ),
                  const Divider(height: 16),
                  _SummaryRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: selectedDate != null
                        ? DateFormat('EEEE, MMMM d, y').format(selectedDate!)
                        : '—',
                  ),
                  const Divider(height: 16),
                  _SummaryRow(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: selectedTime?.format(context) ?? '—',
                  ),
                  const Divider(height: 16),
                  // Price not shown until technician adds invoice
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Final price will be calculated after the technician completes the service',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Discount code
          Text('Discount Code',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (appliedOffer == null) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: discountController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter code (optional)',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      isValidatingCode ? null : onValidateDiscount,
                  child: isValidatingCode
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Apply'),
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appliedOffer!.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(
                            '${appliedOffer!.discountPercentage}% discount applied',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRemoveDiscount,
                    icon: const Icon(Icons.close, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.go('/customer/offers'),
            icon: const Icon(Icons.local_offer, size: 16),
            label: const Text('View available offers'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: valueColor)),
        ),
      ],
    );
  }
}
