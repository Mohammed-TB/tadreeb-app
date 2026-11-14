import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/admin_institute_controller.dart';
import '../models/admin_institute_model.dart';
import '../widgets/admin_dashboard_error.dart';
import '../widgets/admin_dashboard_header.dart';
import '../widgets/admin_institute_card.dart';
import '../widgets/admin_institute_filter.dart';

class AdminInstitutesScreen extends StatefulWidget {
  const AdminInstitutesScreen({super.key});

  @override
  State<AdminInstitutesScreen> createState() => _AdminInstitutesScreenState();
}

class _AdminInstitutesScreenState extends State<AdminInstitutesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminInstituteController>().loadInstitutes();
      }
    });
  }

  Future<void> _openAddInstitute() async {
    final created = await context.push<bool>('/admin_institutes/add');
    if (!mounted || created != true) return;

    final controller = context.read<AdminInstituteController>();
    controller.selectStatus(null);
    await controller.loadInstitutes(forceRefresh: true);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت إضافة المعهد بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    final institutesController = context.watch<AdminInstituteController>();
    final adminName = context.watch<AuthController>().currentUser?.name;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Builder(
        builder: (shellContext) => Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: SizedBox(
            width: 176,
            child: Button(
              text: 'إضافة معهد',
              icon: Icons.add_business_outlined,
              variant: AppButtonVariant.primary,
              height: 54,
              borderRadius: 28,
              fontSize: 15,
              onTap: _openAddInstitute,
            ),
          ),
          body: Column(
            children: [
              AdminDashboardHeader(
                adminName: adminName,
                onMenuTap: () => Scaffold.of(shellContext).openDrawer(),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.sm,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xs,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  children: [
                    _buildListHeader(institutesController),
                    const SizedBox(height: AppSpacing.sm),
                    AdminInstituteFilter(
                      selectedStatus: institutesController.selectedStatus,
                      onChanged: institutesController.selectStatus,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => institutesController.loadInstitutes(
                    forceRefresh: true,
                  ),
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                      AppSpacing.screenHorizontal,
                      100,
                    ),
                    children: [
                      if (institutesController.isLoading &&
                          institutesController.institutes.isEmpty)
                        const SizedBox(
                          height: 240,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (institutesController.errorMessage != null &&
                          institutesController.institutes.isEmpty)
                        AdminDashboardError(
                          message: institutesController.errorMessage!,
                          onRetry: () => institutesController.loadInstitutes(
                            forceRefresh: true,
                          ),
                        )
                      else if (institutesController.visibleInstitutes.isEmpty)
                        _buildEmptyState(institutesController.selectedStatus)
                      else ...[
                        if (institutesController.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Text(
                              institutesController.errorMessage!,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        for (final institute
                            in institutesController.visibleInstitutes) ...[
                          AdminInstituteCard(institute: institute),
                          const SizedBox(height: AppSpacing.cardGap),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListHeader(AdminInstituteController controller) {
    final label = controller.selectedStatus == null
        ? 'المعاهد المسجلة'
        : 'المعاهد ${controller.selectedStatus!.label}';
    final count = controller.selectedStatus == null
        ? controller.total
        : controller.visibleInstitutes.length;

    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.titleMedium)),
        Text(
          '$count معهد',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AdminInstituteStatus? selectedStatus) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.business_outlined,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              selectedStatus == null
                  ? 'لا توجد معاهد مسجلة'
                  : 'لا توجد معاهد بهذه الحالة',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

}
