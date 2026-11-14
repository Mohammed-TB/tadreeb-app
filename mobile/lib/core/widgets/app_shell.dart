
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.drawer,
    required this.navigationItems,
    this.showBottomNavigationBar = true,
  });

  final StatefulNavigationShell navigationShell;
  final Widget drawer;
  final List<BottomNavigationBarItem> navigationItems;
  final bool showBottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,

      body: navigationShell,

      bottomNavigationBar: showBottomNavigationBar
          ? BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.navBackground,
              selectedItemColor: AppColors.navSelected,
              unselectedItemColor: AppColors.navUnselected,
              items: navigationItems,
            )
          : null,
    );
  }
}
