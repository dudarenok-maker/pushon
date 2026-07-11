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

/// The longest streak ever achieved — same skip/break rules as [computeStreak]
/// but scanning the whole [installDate]..[today] span forward. An unlogged
/// *today* is pending: it ends the current run without breaking history.
/// Derived from inputs, so back-filling a forgotten day can raise it.
int longestStreak({
  required LocalDate today,
  required LocalDate installDate,
  required Set<LocalDate> loggedDays,
  required Set<LocalDate> transparentDays,
}) {
  var best = 0, run = 0;
  for (var day = installDate; !day.isAfter(today); day = day.addDays(1)) {
    if (loggedDays.contains(day)) {
      run++;
      if (run > best) best = run;
    } else if (transparentDays.contains(day)) {
      continue; // bridge — neither counts nor breaks
    } else if (day == today) {
      break; // pending today ends the run without breaking it
    } else {
      run = 0;
    }
  }
  return best;
}
