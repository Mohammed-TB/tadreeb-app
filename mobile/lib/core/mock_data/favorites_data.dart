import '../../features/courses/models/course_model.dart';
import '../../features/institutes/models/institute_model.dart';

/// بيانات تجريبية للمفضلة - سيتم استبدالها بالبيانات الحقيقية لاحقاً
class FavoritesData {
  static final List<CourseModel> favoriteCourses = [
    CourseModel(
      id: 'c1',
      instituteId: 'inst1',
      title: 'دورة Flutter المتقدمة',
      description: 'تعلم بناء التطبيقات المتنقلة باستخدام Flutter من الصفر إلى الاحتراف',
      price: 15000,
      depositAmount: 5000,
      capacity: 30,
      enrolledCount: 20,
      startDate: DateTime.now().add(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 30)),
      location: 'المعهد الرئيسي',
      category: 'برمجة',
      status: CourseStatus.published,
      image: 'assets/images/flutter_course.png',
    ),
    CourseModel(
      id: 'c2',
      instituteId: 'inst2',
      title: 'دورة صيانة الجوالات',
      description: 'احترف تقنيات صيانة الأجهزة المحمولة من الأساسيات إلى المستوى المتقدم',
      price: 8000,
      depositAmount: 3000,
      capacity: 25,
      enrolledCount: 18,
      startDate: DateTime.now().add(const Duration(days: 14)),
      endDate: DateTime.now().add(const Duration(days: 45)),
      location: 'الفرع الثاني',
      category: 'صيانة',
      status: CourseStatus.published,
      image: 'assets/images/repair_course.png',
    ),
  ];

  static final List<InstituteModel> favoriteInstitutes = [
    InstituteModel(
      id: 'inst1',
      ownerUserId: 'user1',
      name: 'معهد الراقي للتقنية',
      address: 'حضرموت - الشحر',
      phone: '555-1234',
      imageUrl: 'assets/images/institute_alraqi.png',
    ),
    InstituteModel(
      id: 'inst2',
      ownerUserId: 'user2',
      name: 'معهد العلوم الرقمية',
      address: 'العدة - الحي العربي',
      phone: '555-5678',
      imageUrl: 'assets/images/institute_alscience.png',
    ),
  ];
}
