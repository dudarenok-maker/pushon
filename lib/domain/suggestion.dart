class WeekResult {
  const WeekResult({required this.target, required this.logged});
  final int target;
  final int logged;
}

/// Upward-only target suggestion: shown only when the last 3 completed
/// weeks all hit target AND averaged >= 110% of it. Suggests the 3-week
/// average of logged reps rounded DOWN to a multiple of 5; null when that
/// wouldn't be an increase.
int? raiseSuggestion({
  required List<WeekResult> lastThreeCompleted,
  required int currentTarget,
}) {
  if (lastThreeCompleted.length < 3) return null;
  for (final w in lastThreeCompleted) {
    if (w.target <= 0 || w.logged < w.target) return null;
  }
  final avgRatio = lastThreeCompleted
          .map((w) => w.logged / w.target)
          .reduce((a, b) => a + b) /
      lastThreeCompleted.length;
  if (avgRatio < 1.10) return null;
  final avgLogged = lastThreeCompleted
          .map((w) => w.logged)
          .reduce((a, b) => a + b) /
      lastThreeCompleted.length;
  final suggested = (avgLogged / 5).floor() * 5;
  return suggested > currentTarget ? suggested : null;
}
