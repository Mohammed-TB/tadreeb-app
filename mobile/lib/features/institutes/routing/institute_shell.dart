
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/app_shell.dart';

class InstituteShell extends StatelessWidget {
  const InstituteShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navigationShell: navigationShell,
      drawer: const AppDrawer(),
      navigationItems: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'الدورات',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'الطلاب',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_note_outlined),
          activeIcon: Icon(Icons.event_note),
          label: 'الحجوزات',
        ),

      ],
    );
  }
}
