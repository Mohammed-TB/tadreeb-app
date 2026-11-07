
import 'package:flutter/material.dart';

class AdminInstitutesScreen extends StatelessWidget {
  const AdminInstitutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminPage(
      title: 'إدارة المعاهد',
      content: 'عرض وإدارة المعاهد المسجلة في المنصة',
    );
  }
}

class _AdminPage extends StatelessWidget {
  const _AdminPage({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminHeader(title: title),
        Expanded(
          child: Center(
            child: Text(content),
          ),
        ),
      ],
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
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
    );
  }
}
