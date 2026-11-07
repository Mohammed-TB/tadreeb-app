
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Column(
      children: [
        // Page Header
        SafeArea(
          bottom: false,
          child: Container(
            height: 56,
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              children: [
                Builder(
                  builder: (headerContext) {
                    return IconButton(
                      onPressed: () {
                        Scaffold.of(headerContext).openDrawer();
                      },
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'إدارة المنصة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),

        // Page Content
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 70,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  'مرحباً ${user?.name ?? ''}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('أهلاً بك في لوحة إدارة المنصة'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
