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
}
