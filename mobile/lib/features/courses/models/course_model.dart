class CourseModel {
  // معلومات الدورة
  final String id;
  final String instituteID;

  final String name;
  final String description;
  final double price;
  final String category;

  final String? courseImageUrl;

  // المقاعد
  final int capacity;
  final int enrolled;

  // نسبة العربون
  final int depositPercentage;

  // محتوى الدورة
  final List<String> whatWillLearn;
  final List<String> features;

  // معلومات إضافية
  final String? duration;
  final DateTime? startDate;

  // المفضلة
  final bool isFavourite;

  CourseModel({
    required this.id,
    required this.instituteID,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.capacity,
    required this.enrolled,
    this.depositPercentage = 30,
    this.courseImageUrl,
    this.whatWillLearn = const [],
    this.features = const [],
    this.duration,
    this.startDate,
    this.isFavourite = false,
  }) : assert(
          depositPercentage >= 0 &&
              depositPercentage <= 100,
          'نسبة العربون يجب أن تكون بين 0 و100',
        );

  // عدد المقاعد المتاحة
  int get availableSeats {
    return (capacity - enrolled).clamp(0, capacity);
  }

  // هل الدورة مكتملة؟
  bool get isFull {
    return enrolled >= capacity;
  }

  // مبلغ العربون
  double get depositAmount {
    return (price * depositPercentage / 100).roundToDouble();
  }

  // المبلغ المتبقي
  double get remainingAmount {
    return price - depositAmount;
  }
}