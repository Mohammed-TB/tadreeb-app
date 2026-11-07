
class BookingSettingsModel {
  final int reviewDurationHours;
  final int resubmissionDurationHours;

  // null means unlimited attempts.
  final int? maxResubmissionAttempts;

  const BookingSettingsModel({
    this.reviewDurationHours = 2,
    this.resubmissionDurationHours = 2,
    this.maxResubmissionAttempts,
  }) : assert(reviewDurationHours > 0),
       assert(resubmissionDurationHours > 0),
       assert(
         maxResubmissionAttempts == null ||
             maxResubmissionAttempts > 0,
       );
}
