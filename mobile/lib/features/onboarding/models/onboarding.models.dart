import 'package:flutter/material.dart';

class OnBoarding {
  final String title;
  final String description;
  final String imageUrl;
  final IconData icon;
  final Color color;

  OnBoarding({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.icon,
    required this.color,
  });
}

List<OnBoarding> onBoardingList = [
  OnBoarding(
    title: 'اكتشف الدورات التدريبية',
    description: 'اكتشف دورات متنوعة تساعدك على تطوير مهاراتك.',
       imageUrl: 'assets/images/onboarding_1.svg',

    

    // imageUrl:
    //     'https://images.unsplash.com/photo-1513258496099-48168024aec0?auto=format&fit=crop&w=1200&q=85',
    icon: Icons.school_outlined,
    color: const Color(0xFFF3F0FF),
  ),
  OnBoarding(
    title: 'تعلّم مع الأفضل',
    description: 'طوّر مهاراتك مع أفضل المعاهد التدريبية.',
           imageUrl: 'assets/images/onboarding_2.svg',


    // imageUrl:
    //     'https://images.pexels.com/photos/5212345/pexels-photo-5212345.jpeg?auto=compress&cs=tinysrgb&w=1200',
    icon: Icons.menu_book_outlined,
    color: const Color(0xFFF3F0FF),
  ),
  OnBoarding(
    title: 'ابدأ رحلتك الآن',
    description: 'اختر دورتك القادمة وابدأ رحلة التعلم.',
               imageUrl: 'assets/images/onboarding_3.svg',


    // imageUrl:
    //     'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?auto=format&fit=crop&w=1200&q=85',
    icon: Icons.rocket_launch_outlined,
    color: const Color(0xFFF3F0FF),
  ),
];
