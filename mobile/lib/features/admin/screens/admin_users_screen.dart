import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/admin_user_model.dart';
import '../services/admin_user_service.dart';
import '../widgets/admin_dashboard_error.dart';
import '../widgets/admin_dashboard_header.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final AdminUserService _service;
  final Set<String> _suspendingUserIds = {};
  List<AdminUserModel> _users = [];
  int _page = 1;
  int _totalPages = 0;
  int _total = 0;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = AdminUserService(apiClient: context.read<ApiClient>());
    _loadFirstPage();
  }

  Future<void> _loadFirstPage({bool refresh = false}) async {
    if (_isLoading || _isRefreshing || _isLoadingMore) return;
    setState(() {
      _isLoading = !refresh && _users.isEmpty;
      _isRefreshing = refresh;
      _errorMessage = null;
    });

    try {
      final result = await _service.getUsers(page: 1);
      if (!mounted) return;
      setState(() {
        _users = result.users;
        _total = result.total;
        _page = result.page;
        _totalPages = result.totalPages;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on FormatException {
      if (mounted) {
        setState(() => _errorMessage = 'استجابة قائمة المستخدمين غير صالحة');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isRefreshing || _isLoadingMore || _page >= _totalPages) {
      return;
    }
    final nextPage = _page + 1;
    setState(() {
      _isLoadingMore = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.getUsers(page: nextPage);
      if (!mounted) return;
      setState(() {
        _users = [..._users, ...result.users];
        _total = result.total;
        _page = result.page;
        _totalPages = result.totalPages;
      });
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } on FormatException {
      if (mounted) _showError('استجابة قائمة المستخدمين غير صالحة');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _confirmSuspend(AdminUserModel user) async {
    final shouldSuspend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.person_off_outlined, color: AppColors.error),
        title: const Text('إيقاف الحساب'),
        content: Text(
          'سيتم إيقاف حساب ${user.name}. هل تريد المتابعة؟',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إيقاف الحساب'),
          ),
        ],
      ),
    );
    if (shouldSuspend != true || !mounted) return;

    setState(() => _suspendingUserIds.add(user.id));
    try {
      await _service.suspendUser(userId: user.id);
      if (!mounted) return;
      setState(() {
        _users = [
          for (final item in _users)
            if (item.id == user.id)
              item.copyWith(status: AdminUserStatus.suspended)
            else
              item,
        ];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إيقاف الحساب بنجاح')));
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } on FormatException {
      if (mounted) _showError('استجابة إيقاف الحساب من الخادم غير صالحة');
    } finally {
      if (mounted) setState(() => _suspendingUserIds.remove(user.id));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminName = context.watch<AuthController>().currentUser?.name;
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Column(
        children: [
          AdminDashboardHeader(adminName: adminName),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadFirstPage(refresh: true),
              color: AppColors.primary,
              child: _buildUserList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        _buildListHeading(),
        if (_errorMessage != null && _users.isNotEmpty) _buildInlineError(),
        if (_isLoading && _users.isEmpty)
          const SizedBox(
            height: 280,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_errorMessage != null && _users.isEmpty)
          AdminDashboardError(message: _errorMessage!, onRetry: _loadFirstPage)
        else if (_users.isEmpty)
          _buildEmptyState()
        else ...[
          for (final user in _users) ...[
            _buildUserCard(user),
            const SizedBox(height: AppSpacing.cardGap),
          ],
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_page < _totalPages)
            Button(
              text: 'تحميل المزيد',
              variant: AppButtonVariant.outline,
              onTap: _loadMore,
            ),
        ],
      ],
    );
  }

  Widget _buildListHeading() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text('المستخدمون', style: AppTypography.titleMedium)),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_total حساب',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AdminUserModel user) {
    final isSuspending = _suspendingUserIds.contains(user.id);
    final date = DateFormat('yyyy/MM/dd').format(user.createdAt.toLocal());
    final initials = user.name.trim().isEmpty ? '?' : user.name.trim()[0];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  initials,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: ui.TextDirection.ltr,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildBadge(
                user.role.label,
                AppColors.primaryLight,
                AppColors.primary,
              ),
              _buildStatusBadge(user.status),
              Text(
                'انضم في $date',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (user.status != AdminUserStatus.suspended) ...[
            const SizedBox(height: AppSpacing.sm),
            Button(
              text: isSuspending ? 'جارٍ إيقاف الحساب...' : 'إيقاف الحساب',
              icon: Icons.block_rounded,
              variant: AppButtonVariant.outline,
              foregroundColor: AppColors.error,
              borderColor: AppColors.error,
              isLoading: isSuspending,
              onTap: isSuspending ? null : () => _confirmSuspend(user),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AdminUserStatus status) {
    final (backgroundColor, foregroundColor) = switch (status) {
      AdminUserStatus.active => (AppColors.successLight, AppColors.success),
      AdminUserStatus.pending => (AppColors.warningLight, AppColors.warning),
      AdminUserStatus.suspended => (AppColors.errorLight, AppColors.error),
    };
    return _buildBadge(status.label, backgroundColor, foregroundColor);
  }

  Widget _buildBadge(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildInlineError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => _loadFirstPage(refresh: true),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 52,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('لا يوجد مستخدمون حالياً', style: AppTypography.titleSmall),
          ],
        ),
      ),
    );
  }
}
