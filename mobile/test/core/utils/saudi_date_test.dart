import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/core/utils/saudi_date.dart';

void main() {
  group('SaudiDate', () {
    test('parses a date-only value without shifting its calendar day', () {
      final date = SaudiDate.parseCalendarDate('2026-11-16');

      expect(date, DateTime(2026, 11, 16));
    });

    test('converts an instant at Saudi midnight to the Saudi calendar day', () {
      final date = SaudiDate.parseCalendarDate('2026-11-15T21:00:00.000Z');

      expect(date, DateTime(2026, 11, 16));
    });

    test('serializes selected calendar dates without a timezone', () {
      expect(SaudiDate.toApiDate(DateTime(2026, 11, 16)), '2026-11-16');
    });
  });
}
