class SaudiDate {
  SaudiDate._();

  static const _saudiOffset = Duration(hours: 3);
  static final _dateOnlyPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static final _timezoneSuffixPattern = RegExp(r'(?:Z|[+-]\d{2}:?\d{2})$');

  static DateTime today() {
    final nowInSaudi = DateTime.now().toUtc().add(_saudiOffset);
    return DateTime(nowInSaudi.year, nowInSaudi.month, nowInSaudi.day);
  }

  static DateTime? parseCalendarDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return _calendarDateFromInstant(value);

    final text = value.toString().trim();
    final dateOnlyMatch = _dateOnlyPattern.firstMatch(text);
    if (dateOnlyMatch != null) {
      final year = int.parse(dateOnlyMatch.group(1)!);
      final month = int.parse(dateOnlyMatch.group(2)!);
      final day = int.parse(dateOnlyMatch.group(3)!);
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return date;
    }

    final hasTimezone = _timezoneSuffixPattern.hasMatch(text);
    final parsed = DateTime.tryParse(hasTimezone ? text : '$text+03:00');
    return parsed == null ? null : _calendarDateFromInstant(parsed);
  }

  static String toApiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static bool isTodayOrLater(DateTime date) {
    final calendarDate = DateTime(date.year, date.month, date.day);
    return !calendarDate.isBefore(today());
  }

  static DateTime _calendarDateFromInstant(DateTime instant) {
    final dateInSaudi = instant.toUtc().add(_saudiOffset);
    return DateTime(dateInSaudi.year, dateInSaudi.month, dateInSaudi.day);
  }
}
