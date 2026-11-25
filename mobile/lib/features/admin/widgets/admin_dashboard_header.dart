import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../notifications/controllers/notification_controller.dart';

class AdminDashboardHeader extends StatelessWidget {
  const AdminDashboardHeader({
    super.key,
    this.adminName,
    this.title,
    this.onMenuTap,
  });
  final String? title;
  final String? adminName;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        context.watch<NotificationController>().unreadCount;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Builder(
                builder: (headerContext) => IconButton(
                  onPressed:
                      onMenuTap ??
                      () => Scaffold.of(headerContext).openDrawer(),
                  tooltip: 'القائمة',
                  color: AppColors.textOnPrimary,
                  icon: const Icon(Icons.menu),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
 Text(
  title ?? 'الرئيسية',
  style: GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
  ),
),
IconButton(
  tooltip: 'الإشعارات',
  color: AppColors.textOnPrimary,
  onPressed: () => context.push('/notifications'),
  icon: Stack(
    clipBehavior: Clip.none,
    children: [
      const Icon(Icons.notifications_outlined),
      if (unreadCount > 0)
        Positioned(
          top: -7,
          right: -7,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
              ),
            ),
          ),
        ),
    ],
  ),
),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
