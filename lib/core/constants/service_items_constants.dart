import 'package:car_maintenance_system_new/core/models/service_item_model.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

/// Predefined service catalog for an Egyptian car maintenance center.
/// Prices are in Egyptian Pounds (EGP).
class ServiceItemsConstants {
  ServiceItemsConstants._();

  // ────────────────────────────────────────────────────────────
  // REGULAR MAINTENANCE (صيانة دورية)
  // ────────────────────────────────────────────────────────────
  static final List<ServiceItemEntity> regularMaintenanceItems = [
    ServiceItemEntity(
      id: 'oil_change',
      name: 'تغيير الزيت',
      type: ServiceItemType.service,
      price: 150,
      category: 'regular',
      description: 'تغيير زيت المحرك مع الفلتر',
    ),
    ServiceItemEntity(
      id: 'oil_filter',
      name: 'فلتر الزيت',
      type: ServiceItemType.part,
      price: 60,
      category: 'regular',
      description: 'استبدال فلتر الزيت',
    ),
    ServiceItemEntity(
      id: 'air_filter',
      name: 'فلتر الهواء',
      type: ServiceItemType.part,
      price: 80,
      category: 'regular',
      description: 'استبدال فلتر الهواء',
    ),
    ServiceItemEntity(
      id: 'ac_filter',
      name: 'فلتر التكييف (كابينة)',
      type: ServiceItemType.part,
      price: 100,
      category: 'regular',
      description: 'فلتر هواء المقصورة',
    ),
    ServiceItemEntity(
      id: 'spark_plugs',
      name: 'بواجي (طقم)',
      type: ServiceItemType.part,
      price: 200,
      category: 'regular',
      description: 'طقم بواجي للمحرك',
    ),
    ServiceItemEntity(
      id: 'tire_rotation',
      name: 'تبديل الكفرات',
      type: ServiceItemType.service,
      price: 80,
      category: 'regular',
      description: 'تبديل وتوازن الكفرات الأربع',
    ),
    ServiceItemEntity(
      id: 'fluid_check',
      name: 'تعبئة السوائل',
      type: ServiceItemType.service,
      price: 50,
      category: 'regular',
      description: 'فحص وتعبئة السوائل (تبريد، فرامل، تروس)',
    ),
    ServiceItemEntity(
      id: 'coolant_flush',
      name: 'تغيير سائل التبريد',
      type: ServiceItemType.service,
      price: 180,
      category: 'regular',
      description: 'صرف وتعبئة سائل التبريد',
    ),
  ];

  // ────────────────────────────────────────────────────────────
  // INSPECTION (فحص وكشف)
  // ────────────────────────────────────────────────────────────
  static final List<ServiceItemEntity> inspectionItems = [
    ServiceItemEntity(
      id: 'computer_scan',
      name: 'فحص كمبيوتر (سكانر)',
      type: ServiceItemType.service,
      price: 150,
      category: 'inspection',
      description: 'قراءة أعطال الكمبيوتر OBD-II',
    ),
    ServiceItemEntity(
      id: 'full_inspection',
      name: 'كشف شامل',
      type: ServiceItemType.service,
      price: 300,
      category: 'inspection',
      description: 'فحص شامل لجميع أجزاء السيارة',
    ),
    ServiceItemEntity(
      id: 'brake_inspection',
      name: 'فحص الفرامل',
      type: ServiceItemType.service,
      price: 100,
      category: 'inspection',
      description: 'فحص تيل، أقراص، وسائل الفرامل',
    ),
    ServiceItemEntity(
      id: 'battery_test',
      name: 'فحص البطارية',
      type: ServiceItemType.service,
      price: 50,
      category: 'inspection',
      description: 'اختبار حالة البطارية والشحن',
    ),
    ServiceItemEntity(
      id: 'suspension_check',
      name: 'فحص السوسبنشن',
      type: ServiceItemType.service,
      price: 120,
      category: 'inspection',
      description: 'فحص الهوادي والمساعدين والأرمات',
    ),
    ServiceItemEntity(
      id: 'ac_check',
      name: 'فحص التكييف',
      type: ServiceItemType.service,
      price: 100,
      category: 'inspection',
      description: 'فحص ضغط الفريون وكفاءة التكييف',
    ),
  ];

  // ────────────────────────────────────────────────────────────
  // REPAIR (إصلاح)
  // ────────────────────────────────────────────────────────────
  static final List<ServiceItemEntity> repairItems = [
    // فرامل
    ServiceItemEntity(
      id: 'brake_pads_front',
      name: 'تيل فرامل أمامي',
      type: ServiceItemType.part,
      price: 350,
      category: 'repair',
      description: 'طقم تيل فرامل أمامي',
    ),
    ServiceItemEntity(
      id: 'brake_pads_rear',
      name: 'تيل فرامل خلفي',
      type: ServiceItemType.part,
      price: 300,
      category: 'repair',
      description: 'طقم تيل فرامل خلفي',
    ),
    ServiceItemEntity(
      id: 'brake_disc',
      name: 'قرص فرامل',
      type: ServiceItemType.part,
      price: 500,
      category: 'repair',
      description: 'قرص فرامل (الواحد)',
    ),
    ServiceItemEntity(
      id: 'brake_labor',
      name: 'أجرة تركيب الفرامل',
      type: ServiceItemType.labor,
      price: 200,
      category: 'repair',
      description: 'أجرة تركيب وضبط منظومة الفرامل',
    ),
    // بطارية وكهرباء
    ServiceItemEntity(
      id: 'battery',
      name: 'بطارية سيارة',
      type: ServiceItemType.part,
      price: 1200,
      category: 'repair',
      description: 'بطارية سيارة جديدة',
    ),
    ServiceItemEntity(
      id: 'alternator',
      name: 'دينامو (أولترنيتور)',
      type: ServiceItemType.part,
      price: 2500,
      category: 'repair',
      description: 'استبدال الدينامو',
    ),
    ServiceItemEntity(
      id: 'starter_motor',
      name: 'ماتور تشغيل (ستارتر)',
      type: ServiceItemType.part,
      price: 1800,
      category: 'repair',
      description: 'استبدال ماتور التشغيل',
    ),
    // تعليق وتوجيه
    ServiceItemEntity(
      id: 'shock_absorber',
      name: 'مساعد (الواحد)',
      type: ServiceItemType.part,
      price: 800,
      category: 'repair',
      description: 'استبدال مساعد تعليق',
    ),
    ServiceItemEntity(
      id: 'control_arm',
      name: 'ذراع معلق',
      type: ServiceItemType.part,
      price: 600,
      category: 'repair',
      description: 'استبدال ذراع معلق (لوبريكة)',
    ),
    ServiceItemEntity(
      id: 'wheel_alignment',
      name: 'ضبط زوايا الكفرات',
      type: ServiceItemType.service,
      price: 200,
      category: 'repair',
      description: 'ضبط زوايا الإطارات الأربع',
    ),
    // تبريد
    ServiceItemEntity(
      id: 'radiator',
      name: 'رادياتير',
      type: ServiceItemType.part,
      price: 2000,
      category: 'repair',
      description: 'استبدال رادياتير التبريد',
    ),
    ServiceItemEntity(
      id: 'water_pump',
      name: 'طلمبة مياه',
      type: ServiceItemType.part,
      price: 900,
      category: 'repair',
      description: 'استبدال طلمبة تبريد المحرك',
    ),
    ServiceItemEntity(
      id: 'timing_belt',
      name: 'تايمنج بلت',
      type: ServiceItemType.part,
      price: 500,
      category: 'repair',
      description: 'استبدال سير التايمنج',
    ),
    ServiceItemEntity(
      id: 'serpentine_belt',
      name: 'سير الماكينة',
      type: ServiceItemType.part,
      price: 250,
      category: 'repair',
      description: 'استبدال سير الأكسسوارات',
    ),
    // عام
    ServiceItemEntity(
      id: 'repair_labor',
      name: 'أجرة إصلاح',
      type: ServiceItemType.labor,
      price: 300,
      category: 'repair',
      description: 'أجرة عمالة إصلاح',
    ),
  ];

  // ────────────────────────────────────────────────────────────
  // EMERGENCY (طوارئ)
  // ────────────────────────────────────────────────────────────
  static final List<ServiceItemEntity> emergencyItems = [
    ServiceItemEntity(
      id: 'towing',
      name: 'سطحة (نقل السيارة)',
      type: ServiceItemType.service,
      price: 300,
      category: 'emergency',
      description: 'نقل السيارة للمركز بالسطحة',
    ),
    ServiceItemEntity(
      id: 'jump_start',
      name: 'تشغيل بالبوستر',
      type: ServiceItemType.service,
      price: 80,
      category: 'emergency',
      description: 'تشغيل السيارة عن طريق البوستر',
    ),
    ServiceItemEntity(
      id: 'flat_tire',
      name: 'تغيير كفر مثقوب',
      type: ServiceItemType.service,
      price: 50,
      category: 'emergency',
      description: 'تركيب كفر الاستبيد أو تلحيم',
    ),
    ServiceItemEntity(
      id: 'emergency_diagnostic',
      name: 'كشف طوارئ',
      type: ServiceItemType.service,
      price: 200,
      category: 'emergency',
      description: 'تشخيص سريع لعطل مفاجئ',
    ),
    ServiceItemEntity(
      id: 'fuel_delivery',
      name: 'توصيل بنزين',
      type: ServiceItemType.service,
      price: 100,
      category: 'emergency',
      description: 'توصيل بنزين للسيارة المتوقفة',
    ),
  ];

  // ────────────────────────────────────────────────────────────
  // Default labor costs (EGP)
  // ────────────────────────────────────────────────────────────
  static const Map<MaintenanceType, double> defaultLaborCosts = {
    MaintenanceType.regular: 150.0,
    MaintenanceType.inspection: 100.0,
    MaintenanceType.repair: 300.0,
    MaintenanceType.emergency: 200.0,
  };

  static List<ServiceItemEntity> getItemsForType(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.regular:
        return regularMaintenanceItems;
      case MaintenanceType.inspection:
        return inspectionItems;
      case MaintenanceType.repair:
        return repairItems;
      case MaintenanceType.emergency:
        return emergencyItems;
    }
  }

  static double getDefaultLaborCost(MaintenanceType type) {
    return defaultLaborCosts[type] ?? 150.0;
  }

  /// All services flattened — for full migration to Firestore
  static List<ServiceItemEntity> get all => [
        ...regularMaintenanceItems,
        ...inspectionItems,
        ...repairItems,
        ...emergencyItems,
      ];
}
