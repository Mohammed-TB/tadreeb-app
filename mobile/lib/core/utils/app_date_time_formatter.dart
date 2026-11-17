abstract final class AppDateTimeFormatter {
  static String formatDate(DateTime? value, {bool dayFirst = false}) {
    if (value == null) return '';

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return dayFirst ? '$day/$month/$year' : '$year/$month/$day';
  }

  static String formatDateTime(
    DateTime? value, {
    bool dayFirst = false,
    bool use24HourClock = false,
    String separator = ' ',
  }) {
    if (value == null) return '';

    final localDate = value.toLocal();
    return '${formatDate(localDate, dayFirst: dayFirst)}$separator'
        '${formatTime(localDate, use24HourClock: use24HourClock)}';
  }

  static String formatTime(DateTime? value, {bool use24HourClock = false}) {
    if (value == null) return '';

    final date = value.toLocal();
    final minute = date.minute.toString().padLeft(2, '0');
    if (use24HourClock) {
      return '${date.hour.toString().padLeft(2, '0')}:$minute';
    }

    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }
}
