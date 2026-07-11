import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'package:pushon/domain/streak.dart';

void main() {
  const install = LocalDate(2026, 1, 1);
  const today = LocalDate(2026, 7, 11);
  LocalDate d(int daysAgo) => today.addDays(-daysAgo);

  test('unlogged today is pending, not a break', () {
    expect(
      computeStreak(today: today, installDate: install,
        loggedDays: {d(1), d(2), d(3)}, transparentDays: {}),
      3,
    );
  });

  test('logged today extends the streak', () {
    expect(
      computeStreak(today: today, installDate: install,
        loggedDays: {today, d(1), d(2)}, transparentDays: {}),
      3,
    );
  });

  test('rest day mid-gap is transparent — bridges, does not count', () {
    expect(
      computeStreak(today: today, installDate: install,
        loggedDays: {d(1), d(3)}, transparentDays: {d(2)}),
      2,
    );
  });

  test('a plain missed day breaks it', () {
    expect(
      computeStreak(today: today, installDate: install,
        loggedDays: {d(1), d(3)}, transparentDays: {}),
      1,
    );
  });

  test('catch-up heal: adding an old day retroactively restores the run', () {
    final without = computeStreak(today: today, installDate: install,
        loggedDays: {d(1), d(3), d(4)}, transparentDays: {});
    final with_ = computeStreak(today: today, installDate: install,
        loggedDays: {d(1), d(2), d(3), d(4)}, transparentDays: {});
    expect(without, 1);
    expect(with_, 4);
  });

  test('walk stops at installDate (pre-install days neither count nor break)', () {
    const installed = LocalDate(2026, 7, 9);
    expect(
      computeStreak(today: today, installDate: installed,
        loggedDays: {d(1), d(2)}, transparentDays: {}),
      2, // d(2) == installDate; the walk must not run past it
    );
  });

  test('zero when nothing logged and yesterday missed', () {
    expect(
      computeStreak(today: today, installDate: install,
        loggedDays: {}, transparentDays: {}),
      0,
    );
  });
}
