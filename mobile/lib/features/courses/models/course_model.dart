class CourseModel {
  final String id;
  final String instituteID;
  final String instituteName;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? courseImageUrl;
  final int capacity;
  final int enrolled;
  final bool? isFull;
  final bool? isFavourite;
  final List<String> whatWillLearn;
  final List<String> features;

  CourseModel({
    required this.id,
    required this.instituteID,
    required this.instituteName,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.capacity,
    required this.enrolled,
    this.isFull = false,
    this.isFavourite = false,
    this.courseImageUrl,
    this.whatWillLearn = const [],
    this.features = const [],
  });
}

List<CourseModel> courses = [
  CourseModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    instituteID: 'inst1',
    instituteName: 'معهد الراقي',
    name: 'Flutter Development',
    description: 'تعلم Flutter من الاساسيات إلى بناء المشاريع',
    price: 10000,
    category: 'Programming',
    capacity: 20,
    enrolled: 20,
    isFull: true,
    isFavourite: true,
    courseImageUrl: 'assets/images/english1_course.png',
    whatWillLearn: [
      'تعلم أساسيات Flutter',
      'بناء تطبيقات متنقلة',
    ],
    features: [
      'دورة شاملة',
      'محتوى محدث',
    ],
  ),
  CourseModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    instituteID: 'inst1',
    instituteName: 'معهد الراقي',
    name: 'صيانة الجوالات',
    description: 'احترف صيانة الجوالات من الصفر إلى مستوى متقدم',
    price: 7000,
    category: 'صيانة',
    capacity: 25,
    enrolled: 25,
    isFull: true,
    isFavourite: false,
    courseImageUrl: 'assets/images/english2_course.png',
    whatWillLearn: [
      'تعلم أساسيات صيانة الجوالات',
      'حل المشكلات التقنية',
    ],
    features: [
      'دورة عملية',
      'محتوى محدث',
    ],
  ),
  CourseModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    instituteID: 'inst1',
    instituteName: 'معهد الراقي',
    name: 'تعلم الإكسل',
    description: 'تعلم أساسيات الإكسل إلى مستوى متقدم',
    price: 5000,
    category: 'محاسبة',
    capacity: 30,
    enrolled: 25,
    isFull: false,
    isFavourite: false,
    courseImageUrl: 'assets/images/excel.course.png',
    whatWillLearn: [
      'تعلم أساسيات الإكسل',
      'تحليل البيانات',
    ],
    features: [
      'دورة شاملة',
      'محتوى محدث',
    ],
  ),

];
