import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/notification_planner.dart';

void main() {
  final nineAm = DateTime(2026, 7, 11, 9);
  List<PlannedNotification> plan({
    DateTime? now, int remaining = 50, bool rest = false, DateTime? lastSetAt,
    DateTime? firstOpen, bool nudge = true, bool reminder = true,
  }) =>
      planNotifications(
        now: now ?? nineAm, remainingToday: remaining, restOrZeroTarget: rest,
        lastSetAt: lastSetAt, firstOpenToday: firstOpen ?? nineAm.subtract(const Duration(hours: 1)),
        wakingStartMinutes: 480, wakingEndMinutes: 1260,
        nudgeEnabled: nudge, reminderEnabled: reminder,
      );

  test('rest day or met target: nothing at all', () {
    expect(plan(rest: true), isEmpty);
    expect(plan(remaining: 0), isEmpty);
  });

  test('nudge fires 4h after last set, reminder at 20:00, bodies carry the count', () {
    final p = plan(lastSetAt: nineAm);
    expect(p, hasLength(2));
    final nudge = p.singleWhere((n) => n.kind == PlannedKind.inactivityNudge);
    expect(nudge.fireAt, DateTime(2026, 7, 11, 13));
    expect(nudge.body, contains('50'));
    final reminder = p.singleWhere((n) => n.kind == PlannedKind.eveningReminder);
    expect(reminder.fireAt, DateTime(2026, 7, 11, 20));
    expect(reminder.body, contains('50'));
  });

  test('no set yet: nudge anchors to first open of the day', () {
    final p = plan(lastSetAt: null, firstOpen: nineAm);
    expect(p.singleWhere((n) => n.kind == PlannedKind.inactivityNudge).fireAt,
        DateTime(2026, 7, 11, 13));
  });

  test('nudge clamps to waking start, drops past waking end', () {
    final early = plan(now: DateTime(2026, 7, 11, 5), firstOpen: DateTime(2026, 7, 11, 3));
    expect(early.singleWhere((n) => n.kind == PlannedKind.inactivityNudge).fireAt,
        DateTime(2026, 7, 11, 8));
    final late_ = plan(now: DateTime(2026, 7, 11, 18, 30), lastSetAt: DateTime(2026, 7, 11, 18));
    expect(late_.where((n) => n.kind == PlannedKind.inactivityNudge), isEmpty); // 22:00 > 21:00
  });

  test('reminder dropped once 20:00 has passed', () {
    final p = plan(now: DateTime(2026, 7, 11, 20, 30), lastSetAt: DateTime(2026, 7, 11, 20, 15));
    expect(p.where((n) => n.kind == PlannedKind.eveningReminder), isEmpty);
  });

  test('toggles disable each kind independently', () {
    expect(plan(nudge: false).map((n) => n.kind), [PlannedKind.eveningReminder]);
    expect(plan(reminder: false).map((n) => n.kind), [PlannedKind.inactivityNudge]);
  });
}
