
import 'package:flutter/foundation.dart';

import '../../courses/controllers/course_controller.dart';
import '../../courses/models/course_model.dart';
import '../models/booking_settings_model.dart';
import '../models/enrollment_model.dart';
import '../models/payment_model.dart';
import '../repositories/enrollment_repository.dart';
import '../services/enrollment_service.dart';

class EnrollmentController extends ChangeNotifier {
  final EnrollmentService _enrollmentService;
  final EnrollmentRepository _enrollmentRepository;
  final CourseController _courseController;

  EnrollmentController(
    this._enrollmentService,
    this._enrollmentRepository,
    this._courseController,
  );

  List<EnrollmentModel> _studentEnrollments = [];
  List<EnrollmentModel> _instituteEnrollments = [];
  List<PaymentModel> _payments = [];

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<EnrollmentModel> get studentEnrollments => _studentEnrollments;
  List<EnrollmentModel> get instituteEnrollments => _instituteEnrollments;
  List<PaymentModel> get payments => _payments;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _finishLoading() {
    _isLoading = false;
    notifyListeners();
  }

  // Update enrollment in both lists.
  void _updateEnrollmentLists(EnrollmentModel enrollment) {
    _studentEnrollments = _studentEnrollments.map((item) {
      return item.id == enrollment.id ? enrollment : item;
    }).toList();

    _instituteEnrollments = _instituteEnrollments.map((item) {
      return item.id == enrollment.id ? enrollment : item;
    }).toList();
  }

  // Recalculate booking counts for all loaded courses.
  Future<void> _refreshCourseBookingCounts() async {
    final now = DateTime.now();
    final courses = List<CourseModel>.of(_courseController.courses);

    for (final course in courses) {
      final enrollments =
          await _enrollmentRepository.getCourseEnrollments(course.id);

      final confirmedBookings = enrollments.where((enrollment) {
        return enrollment.status == EnrollmentStatus.confirmed;
      }).length;

      final reservedSeats = enrollments.where((enrollment) {
        final isPending =
            enrollment.status == EnrollmentStatus.pendingReview ||
            enrollment.status == EnrollmentStatus.rejected;

        return isPending && enrollment.expiresAt.isAfter(now);
      }).length;

      await _courseController.updateBookingCounts(
        courseId: course.id,
        confirmedBookings: confirmedBookings,
        reservedSeats: reservedSeats,
      );
    }
  }

  // Expire overdue enrollments.
  Future<void> _expireOverdueEnrollments() async {
    final expiredEnrollments =
        await _enrollmentRepository.expireOverdueEnrollments();

    for (final enrollment in expiredEnrollments) {
      _updateEnrollmentLists(enrollment);
    }

    await _refreshCourseBookingCounts();
  }

  // Fetch student bookings.
  Future<void> getStudentEnrollments(String studentId) async {
    _startLoading();

    try {
      await _expireOverdueEnrollments();

      _studentEnrollments =
          await _enrollmentRepository.getStudentEnrollments(studentId);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _finishLoading();
    }
  }

  // Fetch institute bookings.
  Future<void> getInstituteEnrollments(String instituteId) async {
    _startLoading();

    try {
      await _expireOverdueEnrollments();

      _instituteEnrollments =
          await _enrollmentRepository.getInstituteEnrollments(instituteId);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _finishLoading();
    }
  }

  // Fetch payment history.
  Future<void> getEnrollmentPayments(String enrollmentId) async {
    _startLoading();

    try {
      _payments =
          await _enrollmentRepository.getEnrollmentPayments(enrollmentId);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _finishLoading();
    }
  }

  // Create a new booking.
  Future<bool> createEnrollment({
    required String studentId,
    required CourseModel course,
    required PaymentType paymentType,
    required String receiptUrl,
    required BookingSettingsModel settings,
  }) async {
    _startLoading();

    try {
      final enrollment = await _enrollmentService.createEnrollment(
        studentId: studentId,
        course: course,
        paymentType: paymentType,
        receiptUrl: receiptUrl,
        settings: settings,
      );

      _studentEnrollments = [
        ..._studentEnrollments,
        enrollment,
      ];

      _instituteEnrollments = [
        ..._instituteEnrollments,
        enrollment,
      ];

      await _refreshCourseBookingCounts();

      _successMessage = 'تم إرسال طلب الحجز بنجاح';
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _finishLoading();
    }
  }

  // Approve payment.
  Future<bool> approvePayment(String enrollmentId) async {
    _startLoading();

    try {
      final enrollment = await _enrollmentService.approvePayment(
        enrollmentId: enrollmentId,
      );

      _updateEnrollmentLists(enrollment);

      await _refreshCourseBookingCounts();

      _successMessage = 'تمت الموافقة على الدفع وتأكيد الحجز';
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _finishLoading();
    }
  }

  // Reject payment.
  Future<bool> rejectPayment({
    required String enrollmentId,
    required String reason,
    required BookingSettingsModel settings,
  }) async {
    _startLoading();

    try {
      final enrollment = await _enrollmentService.rejectPayment(
        enrollmentId: enrollmentId,
        reason: reason,
        settings: settings,
      );

      _updateEnrollmentLists(enrollment);

      await _refreshCourseBookingCounts();

      _successMessage = 'تم رفض السند وإرسال سبب الرفض';
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _finishLoading();
    }
  }

  // Resubmit payment receipt.
  Future<bool> resubmitPayment({
    required String enrollmentId,
    required String receiptUrl,
    required PaymentType paymentType,
    required BookingSettingsModel settings,
  }) async {
    _startLoading();

    try {
      final enrollment = await _enrollmentService.resubmitPayment(
        enrollmentId: enrollmentId,
        receiptUrl: receiptUrl,
        paymentType: paymentType,
        settings: settings,
      );

      _updateEnrollmentLists(enrollment);

      await _refreshCourseBookingCounts();

      _successMessage = 'تم إعادة إرسال سند الدفع بنجاح';
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _finishLoading();
    }
  }

  // Clear messages.
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
