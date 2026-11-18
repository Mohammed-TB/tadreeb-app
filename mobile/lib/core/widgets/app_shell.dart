import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

const _activeNavigationColor = AppColors.primary;

class AppShell extends StatefulWidget {
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
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: widget.drawer,
      body: AppShellDrawerScope(
        openDrawer: _openDrawer,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: widget.showBottomNavigationBar
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Container(
                  padding: EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration( 
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.75),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _activeNavigationColor.withValues(alpha: 0.10),
                        blurRadius: 22,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 76,
                    child: Row(
                      children: [
                        for (
                          var index = 0;
                          index < widget.navigationItems.length;
                          index++
                        )
                          Expanded(
                            child: _NavigationDestination(
                              item: widget.navigationItems[index],
                              selected:
                                  index == widget.navigationShell.currentIndex,
                              onTap: () {
                                widget.navigationShell.goBranch(
                                  index,
                                  initialLocation:
                                      index ==
                                      widget.navigationShell.currentIndex,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class AppShellDrawerScope extends InheritedWidget {
  const AppShellDrawerScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static AppShellDrawerScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellDrawerScope>();

  @override
  bool updateShouldNotify(AppShellDrawerScope oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}

class _NavigationDestination extends StatelessWidget {
  const _NavigationDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomNavigationBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? item.activeIcon : item.icon;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                top: selected ? -22 : 8,
                left: 0,
                right: 0,
                height: selected ? 64 : 44,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: selected ? 64 : 44,
                    height: selected ? 64 : 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? _activeNavigationColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: AppColors.surface, width: 4)
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: _activeNavigationColor.withValues(
                                  alpha: 0.26,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: IconTheme(
                          key: ValueKey(selected),
                          data: IconThemeData(
                            color: selected
                                ? Colors.white
                                : AppColors.navUnselected,
                            size: selected ? 27 : 25,
                          ),
                          child: icon,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 2,
                right: 2,
                bottom: 5,
                child: Text(
                  item.label ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.navUnselected,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
