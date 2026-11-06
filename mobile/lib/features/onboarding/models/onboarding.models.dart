import 'package:flutter/material.dart';

class OnBoarding {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnBoarding({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

List<OnBoarding> onBoardingList = [
  OnBoarding(
    title: 'اكتشف الدورات التدريبية',
    description: 'اكتشف دورات متنوعة تساعدك على تطوير مهاراتك.',
    icon: Icons.school_outlined,
    color: const Color(0xFFF3F0FF),
  ),
  OnBoarding(
    title: 'تعلّم مع الأفضل',
    description: 'طوّر مهاراتك مع أفضل المعاهد التدريبية.',
    icon: Icons.menu_book_outlined,
    color: const Color(0xFFF3F0FF),
  ),
  OnBoarding(
    title: 'ابدأ رحلتك الآن',
    description: 'اختر دورتك القادمة وابدأ رحلة التعلم.',
    icon: Icons.rocket_launch_outlined,
    color: const Color(0xFFF3F0FF),
  ),
];
