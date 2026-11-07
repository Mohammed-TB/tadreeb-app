
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

  // عدد الطلاب المؤكد تسجيلهم
  final int enrolled;

  // عدد المقاعد المحجوزة مؤقتاً
  final int reservedSeats;

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
    this.reservedSeats = 0,
    this.depositPercentage = 30,
    this.courseImageUrl,
    this.whatWillLearn = const [],
    this.features = const [],
    this.duration,
    this.startDate,
    this.isFavourite = false,
  })  : assert(
          depositPercentage >= 0 && depositPercentage <= 100,
          'نسبة العربون يجب أن تكون بين 0 و100',
        ),
        assert(enrolled >= 0),
        assert(reservedSeats >= 0),
        assert(capacity >= 0);

  // المقاعد المتاحة فعلياً
  int get availableSeats {
    return (capacity - enrolled - reservedSeats).clamp(0, capacity);
  }

  // هل الدورة مكتملة؟
  bool get isFull {
    return availableSeats == 0;
  }

  // مبلغ العربون
  double get depositAmount {
    return (price * depositPercentage / 100).roundToDouble();
  }

  // المبلغ المتبقي
  double get remainingAmount {
    return price - depositAmount;
  }

  // إنشاء نسخة جديدة مع إمكانية تعديل بعض البيانات
  CourseModel copyWith({
    int? enrolled,
    int? reservedSeats,
  }) {
    return CourseModel(
      id: id,
      instituteID: instituteID,
      name: name,
      description: description,
      price: price,
      category: category,
      capacity: capacity,
      enrolled: enrolled ?? this.enrolled,
      reservedSeats: reservedSeats ?? this.reservedSeats,
      depositPercentage: depositPercentage,
      courseImageUrl: courseImageUrl,
      whatWillLearn: whatWillLearn,
      features: features,
      duration: duration,
      startDate: startDate,
      isFavourite: isFavourite,
    );
  }
}
