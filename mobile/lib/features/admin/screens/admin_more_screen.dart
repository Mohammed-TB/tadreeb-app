
import 'package:flutter/material.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                      'المزيد',
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
        const Expanded(
          child: Center(
            child: Text('المزيد من خيارات المنصة'),
          ),
        ),
      ],
    );
  }
}
