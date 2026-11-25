import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/app_date_time_formatter.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../courses/controllers/reservation_controller.dart';
import '../../courses/services/course_service.dart';
import '../../reservations/controllers/institute_reservation_controller.dart';
import '../../reservations/models/reservation_model.dart';
import '../../reservations/screens/institute_reservation_details_screen.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationController>().fetch();
    });
  }

  Future<void> _openNotification(AppNotificationModel notification) async {
    try {
      await context.read<NotificationController>().markRead(notification);
    } catch (_) {
      if (mounted) {
        _showMessage('تعذر تحديث حالة الإشعار. يمكنك المحاولة مرة أخرى.');
      }
    }
    if (!mounted) return;

    final role = context.read<AuthController>().currentUser?.role.name;
    if (notification.entityType == 'course') {
      try {
        final course = await context.read<CourseService>().getCourseById(
          notification.entityId,
        );
        if (!mounted) return;
        context.push('/course-details', extra: course);
      } catch (_) {
        _showUnavailable();
      }
      return;
    }

    if (notification.entityType == 'reservation') {
      if (role == 'instituteOwner') {
        final controller = context.read<InstituteReservationController>();
        await controller.fetchReservations(forceRefresh: true);
        final matches = controller.reservations
            .where((item) => item.id == notification.entityId)
            .toList();
        final reservation = matches.isEmpty ? null : matches.first;
        if (!mounted) return;
        if (reservation == null) {
          _showUnavailable();
          return;
        }
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            builder: (_) => InstituteReservationDetailsScreen(
              reservation: reservation,
              onApprove: () => controller.approveReservation(reservation.id),
              onReject: () => _rejectReservation(controller, reservation),
            ),
          ),
        );
        return;
      }

      if (role == 'student') {
        final controller = context.read<ReservationController>();
        await controller.fetchMyReservations(forceRefresh: true);
        final matches = controller.myReservations
            .where((item) => item.id == notification.entityId)
            .toList();
        final reservation = matches.isEmpty ? null : matches.first;
        if (!mounted) return;
        if (reservation == null) {
          _showUnavailable();
          return;
        }
        context.push('/reservation-details', extra: reservation);
      }
    }
  }

  Future<void> _rejectReservation(
    InstituteReservationController controller,
    ReservationModel reservation,
  ) async {
    final reasonController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('رفض طلب الحجز'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('يرجى كتابة سبب الرفض لتوضيحه للطالب:'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: reasonController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'سبب الرفض',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('تأكيد الرفض'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || confirmed != true) return;

      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        _showMessage('يرجى كتابة سبب الرفض لتوضيحه للطالب.');
        return;
      }

      final success = await controller.rejectReservation(
        reservation.id,
        reason: reason,
      );
      if (!mounted) return;
      _showMessage(
        success
            ? 'تم رفض طلب الحجز.'
            : 'تعذر رفض الحجز: ${controller.errorMessage ?? 'حاول مرة أخرى.'}',
      );
    } finally {
      reasonController.dispose();
    }
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لم يعد العنصر مرتبطًا بإشعار قابل للفتح')),
    );
  }

  Future<void> _markAllRead(NotificationController controller) async {
    if (_isMarkingAllRead || controller.unreadCount == 0) return;
    setState(() => _isMarkingAllRead = true);
    try {
      await controller.markAllRead();
    } catch (_) {
      if (mounted) {
        _showMessage('تعذر تحديث الإشعارات. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('الإشعارات'),
          actions: [
            Consumer<NotificationController>(
              builder: (context, controller, _) => TextButton(
                onPressed: controller.unreadCount == 0 || _isMarkingAllRead
                    ? null
                    : () => _markAllRead(controller),
                child: _isMarkingAllRead
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('قراءة الكل'),
              ),
            ),
          ],
        ),
        body: Consumer<NotificationController>(
          builder: (context, controller, _) {
            return RefreshIndicator(
              onRefresh: controller.fetch,
              child: controller.items.isEmpty
                  ? _buildEmptyList(controller)
                  : _buildNotificationList(controller),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyList(NotificationController controller) {
    final isLoading = controller.isLoading;
    final hasError = controller.errorMessage != null;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.58,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const CircularProgressIndicator()
                else ...[
                  Icon(
                    hasError
                        ? Icons.cloud_off_outlined
                        : Icons.notifications_none_rounded,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    hasError
                        ? 'تعذر تحميل الإشعارات'
                        : 'لا توجد إشعارات حالياً',
                    style: AppTypography.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (hasError) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      controller.errorMessage!,
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: controller.fetch,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'اسحب الشاشة للأسفل للتحديث',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationList(NotificationController controller) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: controller.items.length + 1,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummary(controller.unreadCount),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildRefreshError(controller),
              ],
            ],
          );
        }
        return _buildNotificationCard(controller.items[index - 1]);
      },
    );
  }

  Widget _buildSummary(int unreadCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'كل إشعاراتك في مكان واحد',
              style: AppTypography.titleSmall,
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$unreadCount غير مقروء',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshError(NotificationController controller) {
    return Material(
      color: AppColors.errorLight,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.error),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'تعذر تحديث الإشعارات',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.isLoading ? null : controller.fetch,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationModel notification) {
    final icon = notification.entityType == 'course'
        ? Icons.school_outlined
        : Icons.event_note_outlined;
    final time = AppDateTimeFormatter.formatDateTime(
      notification.createdAt,
      dayFirst: true,
      use24HourClock: true,
      separator: ' - ',
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: notification.isRead ? 0 : 1,
      color: notification.isRead
          ? AppColors.surface
          : AppColors.primaryLight.withValues(alpha: 0.72),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openNotification(notification),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          time,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xs),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
