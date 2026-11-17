import 'package:flutter/material.dart';

import '../../../core/utils/app_date_time_formatter.dart';
import '../models/student_reservation_model.dart';
import 'reservation_details_components.dart';

class ReservationCourseInfoSection extends StatelessWidget {
  const ReservationCourseInfoSection({super.key, required this.reservation});

  final StudentReservationModel reservation;

  @override
  Widget build(BuildContext context) {
    return ReservationSectionCard(
      title: 'معلومات الدورة والتدريب',
      icon: Icons.school_outlined,
      children: [
        ReservationDataRow(
          label: 'اسم الدورة:',
          value: reservation.courseTitle,
        ),
        ReservationDataRow(
          label: 'المعهد التدريبي:',
          value: reservation.instituteName,
        ),
        if (reservation.courseStartDate != null)
          ReservationDataRow(
            label: 'تاريخ البدء:',
            value: AppDateTimeFormatter.formatDate(reservation.courseStartDate),
          ),
        if (reservation.courseEndDate != null)
          ReservationDataRow(
            label: 'تاريخ الانتهاء:',
            value: AppDateTimeFormatter.formatDate(reservation.courseEndDate),
          ),
        if (reservation.courseLocation?.isNotEmpty == true)
          ReservationDataRow(
            label: 'مكان الانعقاد:',
            value: reservation.courseLocation!,
          ),
        ReservationDataRow(
          label: 'نوع التسجيل:',
          value: reservation.bookingType == 'online'
              ? 'إلكتروني عبر المنصة'
              : 'حضوري',
        ),
      ],
    );
  }
}

class ReservationStudentInfoSection extends StatelessWidget {
  const ReservationStudentInfoSection({super.key, required this.reservation});

  final StudentReservationModel reservation;

  @override
  Widget build(BuildContext context) {
    return ReservationSectionCard(
      title: 'بيانات المتدرب المسجل',
      icon: Icons.person_outline_rounded,
      children: [
        ReservationDataRow(
          label: 'اسم الطالب:',
          value: reservation.studentName,
        ),
        ReservationDataRow(
          label: 'رقم الهاتف:',
          value: reservation.studentPhone,
        ),
        ReservationDataRow(
          label: 'تاريخ إنشاء الحجز:',
          value: AppDateTimeFormatter.formatDateTime(reservation.createdAt),
        ),
      ],
    );
  }
}
