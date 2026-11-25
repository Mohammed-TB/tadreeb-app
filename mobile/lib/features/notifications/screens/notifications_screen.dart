import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../courses/controllers/reservation_controller.dart';
import '../../courses/services/course_service.dart';
import '../../reservations/controllers/institute_reservation_controller.dart';
import '../../reservations/screens/institute_reservation_details_screen.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationController>().fetch();
    });
  }

  Future<void> _openNotification(AppNotificationModel notification) async {
    await context.read<NotificationController>().markRead(notification);
    if (!mounted) return;

    final role = context.read<AuthController>().currentUser?.role.name;
    if (notification.entityType == 'course') {
      try {
        final course =
            await context.read<CourseService>().getCourseById(notification.entityId);
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
              onApprove: () =>
                  controller.approveReservation(reservation.id),
              onReject: () {},
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

  void _showUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لم يعد العنصر مرتبطًا بإشعار قابل للفتح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإشعارات'),
          actions: [
            TextButton(
              onPressed: context.read<NotificationController>().markAllRead,
              child: const Text('قراءة الكل'),
            ),
          ],
        ),
        body: Consumer<NotificationController>(
          builder: (context, controller, _) {
            if (controller.isLoading && controller.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.errorMessage != null &&
                controller.items.isEmpty) {
              return Center(child: Text(controller.errorMessage!));
            }
            if (controller.items.isEmpty) {
              return const Center(child: Text('لا توجد إشعارات'));
            }
            return RefreshIndicator(
              onRefresh: controller.fetch,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notification = controller.items[index];
                  return Card(
                    color: notification.isRead
                        ? Colors.white
                        : AppColors.primary.withValues(alpha: 0.06),
                    child: ListTile(
                      leading: Icon(
                        notification.entityType == 'course'
                            ? Icons.school_outlined
                            : Icons.assignment_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        notification.title,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        notification.body,
                        style: AppTypography.bodySmall,
                      ),
                      trailing: !notification.isRead
                          ? const Icon(Icons.circle,
                              size: 10, color: AppColors.primary)
                          : null,
                      onTap: () => _openNotification(notification),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
