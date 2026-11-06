
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/search.dart';

class HeaderHome extends StatelessWidget {
  const HeaderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 165,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        40,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الجزء العلوي: الترحيب والأيقونات
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildProfileIcon(),

                    const SizedBox(width: AppSpacing.sm),

                    Expanded(
                      child: Text(
                        'صباح الخير، محمد',
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

              const SizedBox(width: AppSpacing.xs),

              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // الانتقال إلى المفضلة
                    },
                    icon: const Icon(
                      Icons.favorite_outline,
                      color: Colors.white,
                    ),
                  ),

                  _buildNotificationButton(),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // حقل البحث
          Search(
            hinText: 'ابحث عن دورة أو معهد',
            isBorder: false,


          ),
        ],
      ),
    );
  }

  Widget _buildProfileIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
      ),
      child: const Icon(
        Icons.person,
        size: 28,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildNotificationButton() {
    return IconButton(
      onPressed: () {
        // فتح الإشعارات
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
          ),

          Positioned(
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
                '5',
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
