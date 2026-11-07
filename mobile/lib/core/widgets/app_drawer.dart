
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../features/auth/controllers/auth_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    final role = user?.role.name;

    final roleLabel = switch (role) {
      'student' => 'حساب الطالب',
      'instituteOwner' => 'حساب صاحب المعهد',
      'admin' => 'مدير المنصة',
      _ => 'حساب المستخدم',
    };

    final menuItems = switch (role) {
      'student' => [
        _DrawerItem(
          icon: Icons.person_outline,
          title: 'الملف الشخصي',
        ),
        _DrawerItem(
          icon: Icons.notifications_outlined,
          title: 'الإشعارات',
        ),
        _DrawerItem(
          icon: Icons.settings_outlined,
          title: 'الإعدادات',
        ),
        _DrawerItem(
          icon: Icons.support_agent_outlined,
          title: 'المساعدة والتواصل',
        ),
      ],
      'instituteOwner' => [
        _DrawerItem(
          icon: Icons.business_outlined,
          title: 'بيانات المعهد',
        ),
        _DrawerItem(
          icon: Icons.payments_outlined,
          title: 'إعدادات الحجز والدفع',
        ),
        _DrawerItem(
          icon: Icons.bar_chart_outlined,
          title: 'التقارير',
        ),
        _DrawerItem(
          icon: Icons.person_outline,
          title: 'الملف الشخصي',
        ),
        _DrawerItem(
          icon: Icons.settings_outlined,
          title: 'الإعدادات',
        ),
      ],
      'admin' => [
        _DrawerItem(
          icon: Icons.business_outlined,
          title: 'إدارة المعاهد',
        ),
        _DrawerItem(
          icon: Icons.people_outline,
          title: 'إدارة المستخدمين',
        ),
        _DrawerItem(
          icon: Icons.bar_chart_outlined,
          title: 'التقارير',
        ),
        _DrawerItem(
          icon: Icons.settings_outlined,
          title: 'إعدادات المنصة',
        ),
      ],
      _ => <_DrawerItem>[],
    };

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'المستخدم',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Role-specific menu
            ...menuItems.map(
                  (item) => ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                onTap: () {
                  _showComingSoon(context);
                  Navigator.pop(context);
                },
              ),
            ),

            const Spacer(),

            const Divider(height: 1),

            // Logout
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                context.read<AuthController>().logout();
                context.go('/login');
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('هذه الميزة ستكون متاحة قريباً'),
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String title;

  const _DrawerItem({
    required this.icon,
    required this.title,
  });
}
