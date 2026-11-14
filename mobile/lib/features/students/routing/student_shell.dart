
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/app_shell.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({
    super.key,
    required this.navigationShell,
    required this.showBottomNavigationBar,
  });

  final StatefulNavigationShell navigationShell;
  final bool showBottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navigationShell: navigationShell,
      drawer: const AppDrawer(),
      showBottomNavigationBar: showBottomNavigationBar,
      navigationItems: const [
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
          icon: Icon(Icons.apartment_outlined),
          activeIcon: Icon(Icons.apartment_rounded),
          label: 'المعاهد',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long_rounded),
          label: 'حجوزاتي',
        ),

      ],
    );
  }
}
