enum PlannedKind { inactivityNudge, eveningReminder }

class PlannedNotification {
  const PlannedNotification({required this.kind, required this.fireAt, required this.title, required this.body});
  final PlannedKind kind;
  final DateTime fireAt;
  final String title;
  final String body;
}

/// Pure notification plan for the rest of *today*. Recomputed on every app
/// open and every log; the scheduler applies it (cancel-all, then schedule).
/// Best-effort by design — see the spec's "Reliability posture".
List<PlannedNotification> planNotifications({
  required DateTime now,
  required int remainingToday,
  required bool restOrZeroTarget,
  required DateTime? lastSetAt,
  required DateTime firstOpenToday,
  required int wakingStartMinutes,
  required int wakingEndMinutes,
  required bool nudgeEnabled,
  required bool reminderEnabled,
}) {
  if (remainingToday <= 0 || restOrZeroTarget) return const [];
  final out = <PlannedNotification>[];
  final dayStart = DateTime(now.year, now.month, now.day);

  if (nudgeEnabled) {
    var fire = (lastSetAt ?? firstOpenToday).add(const Duration(hours: 4));
    final wakeStart = dayStart.add(Duration(minutes: wakingStartMinutes));
    final wakeEnd = dayStart.add(Duration(minutes: wakingEndMinutes));
    if (fire.isBefore(wakeStart)) fire = wakeStart;
    if (fire.isAfter(now) && !fire.isAfter(wakeEnd)) {
      out.add(PlannedNotification(
        kind: PlannedKind.inactivityNudge,
        fireAt: fire,
        title: 'Time for a set?',
        body: '$remainingToday reps to go today.',
      ));
    }
  }

  if (reminderEnabled) {
    final eightPm = dayStart.add(const Duration(hours: 20));
    if (now.isBefore(eightPm)) {
      out.add(PlannedNotification(
        kind: PlannedKind.eveningReminder,
        fireAt: eightPm,
        title: "Today's push-ups",
        body: '$remainingToday to go — a couple of quick sets.',
      ));
    }
  }
  return out;
}
