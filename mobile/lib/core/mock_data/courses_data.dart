import '../../features/courses/models/course_model.dart';

final List<CourseModel> courses = [
  CourseModel(
    id: 'course1',
    instituteID: 'inst1',
    name: 'Flutter Development',
    description: 'تعلم Flutter من الأساسيات إلى بناء المشاريع',
    price: 10000,
    category: 'برمجة',
    capacity: 20,
    enrolled: 15,
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
    id: 'course2',
    instituteID: 'inst1',
    name: 'صيانة الجوالات',
    description: 'احترف صيانة الجوالات من الصفر إلى مستوى متقدم',
    price: 7000,
    depositPercentage: 50,
    category: 'صيانة',
    capacity: 25,
    enrolled: 15,
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
    id: 'course3',
    instituteID: 'inst1',
    name: 'تعلم الإكسل',
    description: 'تعلم أساسيات الإكسل إلى مستوى متقدم',
    price: 5000,
    category: 'محاسبة',
    capacity: 30,
    enrolled: 25,
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

