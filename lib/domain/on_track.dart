/// "To stay on track: X/day" — informational only, never a target.
///
/// X = max(0, W - logged - sum(targets of rest-flagged days)) / remaining
/// non-rest, non-zero-target days (today included). Null = hide the line.
int? onTrackPerDay({
  required int weeklyTarget,
  required List<int> targets,
  required int loggedThisWeek,
  required Set<int> restDayIndexes,
  required int todayIndex,
}) {
  var restTargets = 0;
  for (final d in restDayIndexes) {
    restTargets += targets[d];
  }
  var remainingDays = 0;
  for (var d = todayIndex; d < 7; d++) {
    if (!restDayIndexes.contains(d) && targets[d] > 0) remainingDays++;
  }
  if (remainingDays == 0) return null;
  final remaining = weeklyTarget - loggedThisWeek - restTargets;
  if (remaining <= 0) return 0;
  return (remaining / remainingDays).ceil();
}
