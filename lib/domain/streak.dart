import 'dates.dart';

/// Consecutive-day streak per the spec's testable definition:
/// - an unlogged *today* is pending (doesn't break, doesn't count);
/// - transparent days (rest / target-0) are skipped, never breaking;
/// - the walk never crosses [installDate] (pre-install days are neutral);
/// - derived entirely from inputs, so catch-up logging heals retroactively.
int computeStreak({
  required LocalDate today,
  required LocalDate installDate,
  required Set<LocalDate> loggedDays,
  required Set<LocalDate> transparentDays,
}) {
  var streak = 0;
  if (loggedDays.contains(today)) streak++;
  var day = today.previous;
  while (!day.isBefore(installDate)) {
    if (loggedDays.contains(day)) {
      streak++;
    } else if (!transparentDays.contains(day)) {
      break;
    }
    day = day.previous;
  }
  return streak;
}
