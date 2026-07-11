import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/on_track.dart';

void main() {
  const targets = [70, 40, 70, 75, 75, 100, 70]; // canonical W=500 fixture

  test('midweek behind: ceil of remaining over remaining non-rest days', () {
    // Thursday (index 3), 180 logged, no rest days: (500-180)/4 days = 80.
    expect(
      onTrackPerDay(weeklyTarget: 500, targets: targets, loggedThisWeek: 180,
        restDayIndexes: {}, todayIndex: 3),
      80,
    );
  });

  test('rest-day targets are written off, not redistributed', () {
    // Thursday, 180 logged. No rest: (500-180)/4 = 80.
    // Fri (75) flagged, WITH the write-off: (500-180-75)/3 = 81.67 -> 82.
    // WITHOUT the write-off it would be (500-180)/3 = 107 — that jump is
    // what the spec forbids; the ±rounding from having fewer days is not.
    final flagged = onTrackPerDay(weeklyTarget: 500, targets: targets,
        loggedThisWeek: 180, restDayIndexes: {4}, todayIndex: 3)!;
    expect(flagged, 82);
  });

  test('already met: 0', () {
    expect(
      onTrackPerDay(weeklyTarget: 500, targets: targets, loggedThisWeek: 505,
        restDayIndexes: {}, todayIndex: 6),
      0,
    );
  });

  test('hidden when every remaining day is rest or target-0', () {
    expect(
      onTrackPerDay(weeklyTarget: 500, targets: targets, loggedThisWeek: 100,
        restDayIndexes: {6}, todayIndex: 6),
      isNull,
    );
  });
}
