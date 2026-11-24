import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/search.dart';
import '../../../core/utils/saudi_date.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/controllers/notification_controller.dart';

class HeaderHome extends StatelessWidget {
  const HeaderHome({
    super.key,
    required this.onMenuTap,
    this.onFilterTap,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onClear,
    this.searchController,
    this.hasActiveFilter = false,
  });

  final VoidCallback onMenuTap;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onClear;
  final TextEditingController? searchController;
  final bool hasActiveFilter;

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;
    final greeting = SaudiDate.currentHour() < 12 ? 'صباح الخير' : 'مساء الخير';
    final userName =
        user?.name ?? (authController.isGuest ? 'زائر' : 'طالبنا العزيز');

    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        36,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome and actions
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onMenuTap,
                      tooltip: 'القائمة',
                      icon: const Icon(Icons.menu, color: Colors.white),
                    ),
                    // _buildProfileIcon(),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '$greeting، $userName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.push('/favorites'),
                    icon: const Icon(
                      Icons.favorite_outline,
                      color: Colors.white,
                    ),
                  ),

                  _buildNotificationButton(context),
                ],
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Search field
          Search(
            hinText: 'ابحث عن دورة أو معهد',
            isBorder: false,
            onFilterTap: onFilterTap,
            onChanged: onSearchChanged,
            onSubmitted: onSearchSubmitted,
            onClear: onClear,
            controller: searchController,
            hasActiveFilter: hasActiveFilter,
          ),
        ],
      ),
    );
  }

  // Widget _buildProfileIcon() {
  //   return Container(
  //     width: 40,
  //     height: 40,
  //     decoration: const BoxDecoration(
  //       shape: BoxShape.circle,
  //       color: AppColors.surface,
  //     ),
  //     child: const Icon(Icons.person, size: 28, color: AppColors.textSecondary),
  //   );
  // }

  Widget _buildNotificationButton(BuildContext context) {
    final unreadCount = context.watch<NotificationController>().unreadCount;
    return IconButton(
      onPressed: () {
        context.push('/notifications');
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined, color: Colors.white),
          if (unreadCount > 0) Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
