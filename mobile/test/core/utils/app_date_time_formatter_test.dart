import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/core/utils/app_date_time_formatter.dart';

void main() {
  test('formats calendar dates without shifting their day', () {
    expect(
      AppDateTimeFormatter.formatDate(DateTime(2026, 11, 17)),
      '2026/11/17',
    );
    expect(
      AppDateTimeFormatter.formatDate(DateTime(2026, 11, 17), dayFirst: true),
      '17/11/2026',
    );
  });

  test('formats local date and time in reusable 12 and 24-hour styles', () {
    final morning = DateTime(2026, 11, 17, 9, 5);
    final afternoon = DateTime(2026, 11, 17, 15, 5);

    expect(AppDateTimeFormatter.formatDateTime(morning), '2026/11/17 9:05 ص');
    expect(
      AppDateTimeFormatter.formatDateTime(
        afternoon,
        dayFirst: true,
        use24HourClock: true,
        separator: ' - ',
      ),
      '17/11/2026 - 15:05',
    );
  });
}
