
enum CourseStatus {
  draft,
  published,
  closed,
  completed;

  static CourseStatus fromJson(dynamic value) {
    return CourseStatus.values.firstWhere(
      (status) => status.name == value?.toString().toLowerCase(),
      orElse: () => CourseStatus.draft,
    );
  }
}

class CourseModel {
  final String? id;
  final String title;
  final String description;
  final String? image;
  final String category;

  final double price;
  final double depositAmount;

  final int capacity;
  final int enrolledCount;
  final int reservedCount;

  final DateTime startDate;
  final DateTime endDate;

  final String location;
  final CourseStatus status;
  final List<String> whatWillLearn;
  final List<String> features;

  final String instituteId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourseModel({
    this.id,
    required this.title,
    required this.description,
    this.image,
    required this.category,
    required this.price,
    required this.depositAmount,
    required this.capacity,
    this.enrolledCount = 0,
    this.reservedCount = 0,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.status = CourseStatus.draft,
    this.whatWillLearn = const [],
    this.features = const [],
    required this.instituteId,
    this.createdAt,
    this.updatedAt, 
  });

  // المقاعد المتاحة فعليًا.
  int get availableSeats {
    final available = capacity - enrolledCount - reservedCount;
    return available < 0 ? 0 : available;
  }

  bool get isFull => availableSeats == 0;

  // نسبة العربون للعرض فقط.
  double get depositPercentage {
    if (price <= 0) return 0;
    return (depositAmount / price) * 100;
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final institute = json['instituteId'];

    return CourseModel(
      id: (json['_id'] ?? json['id'])?.toString(),

      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString(),
      category: json['category']?.toString() ?? '',

      price: _toDouble(json['price']),
      depositAmount: _toDouble(json['depositAmount']),

      capacity: _toInt(json['capacity']),
      enrolledCount: _toInt(json['enrolledCount']),
      reservedCount: _toInt(json['reservedCount']),

      startDate: _parseDate(json['startDate']) ??
          DateTime.fromMillisecondsSinceEpoch(0),

      endDate: _parseDate(json['endDate']) ??
          DateTime.fromMillisecondsSinceEpoch(0),

      location: json['location']?.toString() ?? '',

      status: CourseStatus.fromJson(json['status']),
      whatWillLearn: _toStringList(json['whatWillLearn']),
      features: _toStringList(json['features']),

      instituteId: institute is Map
          ? (institute['_id'] ?? institute['id'] ?? '').toString()
          : (institute?.toString() ?? ''),

      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  // بيانات إنشاء الدورة المتوافقة مع CreateCourseInput.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (image != null && image!.isNotEmpty) 'image': image,
      'category': category,
      'price': price,
      'depositAmount': depositAmount,
      'capacity': capacity,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'location': location,
      'whatWillLearn': whatWillLearn,
      'features': features,
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? image,
    String? category,
    double? price,
    double? depositAmount,
    int? capacity,
    int? enrolledCount,
    int? reservedCount,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    CourseStatus? status,
    List<String>? whatWillLearn,
    List<String>? features,
    String? instituteId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      category: category ?? this.category,
      price: price ?? this.price,
      depositAmount: depositAmount ?? this.depositAmount,
      capacity: capacity ?? this.capacity,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      reservedCount: reservedCount ?? this.reservedCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      status: status ?? this.status,
      whatWillLearn: whatWillLearn ?? this.whatWillLearn,
      features: features ?? this.features,
      instituteId: instituteId ?? this.instituteId,
      
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
