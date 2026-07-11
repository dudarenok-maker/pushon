import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'package:pushon/domain/day_status.dart';

void main() {
  const install = LocalDate(2026, 7, 1);
  const today = LocalDate(2026, 7, 11);
  DayStatus s(LocalDate date, {int logged = 0, int target = 70, bool rest = false}) =>
      dayStatus(date: date, today: today, installDate: install,
          logged: logged, target: target, rest: rest);

  test('the eight rules', () {
    expect(s(const LocalDate(2026, 6, 20)), DayStatus.preInstall);
    expect(s(const LocalDate(2026, 7, 5), rest: true, logged: 999), DayStatus.rest); // grey regardless
    expect(s(const LocalDate(2026, 7, 5), target: 0), DayStatus.rest);               // target-0 == rest
    expect(s(const LocalDate(2026, 7, 5), logged: 70), DayStatus.hit);
    expect(s(const LocalDate(2026, 7, 5), logged: 30), DayStatus.partial);
    expect(s(const LocalDate(2026, 7, 5)), DayStatus.missed);
    expect(s(today, logged: 30), DayStatus.pending);   // today pending until hit
    expect(s(today, logged: 70), DayStatus.hit);
    expect(s(const LocalDate(2026, 7, 12)), DayStatus.future);
  });

  group('isDayEditable', () {
    // Install mid-week: Wed 2026-07-08 (that week starts Mon 2026-07-06). Today Sat 07-11.
    const installMidWeek = LocalDate(2026, 7, 8);
    const now = LocalDate(2026, 7, 11);
    bool editable(LocalDate d) => isDayEditable(date: d, today: now, installDate: installMidWeek);

    test('days earlier in the install week are editable (back-fill)', () {
      expect(editable(const LocalDate(2026, 7, 6)), isTrue);  // Mon, before install, same week
      expect(editable(const LocalDate(2026, 7, 7)), isTrue);  // Tue, before install, same week
    });

    test('the install day and later this week are editable', () {
      expect(editable(installMidWeek), isTrue);
      expect(editable(const LocalDate(2026, 7, 11)), isTrue); // today
    });

    test('days in weeks before the install week stay locked', () {
      expect(editable(const LocalDate(2026, 7, 5)), isFalse);  // Sun, prior week
      expect(editable(const LocalDate(2026, 6, 30)), isFalse);
    });

    test('future days are never editable', () {
      expect(editable(const LocalDate(2026, 7, 12)), isFalse);
    });

    test('install on a Monday matches the old boundary (nothing before install)', () {
      const mon = LocalDate(2026, 7, 6);
      expect(isDayEditable(date: const LocalDate(2026, 7, 5), today: now, installDate: mon), isFalse);
      expect(isDayEditable(date: mon, today: now, installDate: mon), isTrue);
    });
  });
}
