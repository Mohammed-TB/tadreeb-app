
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../widgets/app_drawer.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Drawer belongs to the main application shell.
      drawer: const AppDrawer(),

      // Current branch content.
      body: navigationShell,

      // Student bottom navigation.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation:
            index == navigationShell.currentIndex,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.navBackground,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'الدورات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'حجوزاتي',
          ),
        ],
      ),
    );
  }
}


/*
*
*
* الحساب	البريد	كلمة المرور	النتيجة المتوقعة
صاحب المعهد	john@example.com	password123	لوحة المعهد
الطالب	jane@example.com	password456	الصفحة الرئيسية
مدير المنصة	bob@example.com	password789	لوحة الإدارة
* */