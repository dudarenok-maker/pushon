import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';

void main() {
  test('value equality and iso round-trip', () {
    const d = LocalDate(2026, 7, 11);
    expect(d, const LocalDate(2026, 7, 11));
    expect(d.iso, '2026-07-11');
    expect(LocalDate.parse('2026-07-11'), d);
  });

  test('addDays rolls months and years', () {
    expect(const LocalDate(2026, 12, 31).addDays(1), const LocalDate(2027, 1, 1));
    expect(const LocalDate(2026, 3, 1).addDays(-1), const LocalDate(2026, 2, 28));
  });

  test('addDays is DST-safe (date component math, never wall-clock)', () {
    // 2026-10-04 is an AEDT DST-start Sunday in Australia; component math must not skip/repeat a day.
    expect(const LocalDate(2026, 10, 3).addDays(1), const LocalDate(2026, 10, 4));
    expect(const LocalDate(2026, 10, 4).addDays(1), const LocalDate(2026, 10, 5));
  });

  test('weekStart is Monday, weekdayIndex 0=Mon..6=Sun', () {
    const sat = LocalDate(2026, 7, 11); // Saturday
    expect(sat.weekdayIndex, 5);
    expect(sat.weekStart, const LocalDate(2026, 7, 6)); // Monday
    expect(const LocalDate(2026, 7, 6).weekStart, const LocalDate(2026, 7, 6));
  });

  test('ordering', () {
    expect(const LocalDate(2026, 7, 10).isBefore(const LocalDate(2026, 7, 11)), isTrue);
    expect(const LocalDate(2026, 7, 12).isAfter(const LocalDate(2026, 7, 11)), isTrue);
  });
}
