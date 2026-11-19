import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:project_1/core/widgets/app_shell.dart';

void main() {
  testWidgets('hides the bottom navigation on scroll down and shows it on up', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShell(
            navigationShell: navigationShell,
            drawer: const SizedBox.shrink(),
            navigationItems: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'الرئيسية',
              ),
            ],
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => ListView.builder(
                    key: const Key('scroll-page'),
                    itemCount: 40,
                    itemBuilder: (context, index) =>
                        SizedBox(height: 80, child: Text('Item $index')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('bottom-navigation-visible')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const Key('scroll-page')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('bottom-navigation-visible')),
      findsNothing,
    );

    await tester.drag(
      find.byKey(const Key('scroll-page')),
      const Offset(0, 250),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('bottom-navigation-visible')),
      findsOneWidget,
    );
  });
}
