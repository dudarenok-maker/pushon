/// The rep count to pre-select in the logger — your "standard" set. It's the
/// most common of your recent sets ([recentCounts], **most-recent first**), so
/// if your last logs were all 15 the wheel opens on 15. Ties break toward the
/// more recent value, and with no history yet it falls back to [fallback].
int suggestedReps(List<int> recentCounts, {int fallback = 20}) {
  if (recentCounts.isEmpty) return fallback;
  final freq = <int, int>{};
  for (final c in recentCounts) {
    freq[c] = (freq[c] ?? 0) + 1;
  }
  // Walk most-recent first so a tie on frequency keeps the more recent value.
  var best = recentCounts.first;
  var bestFreq = 0;
  for (final c in recentCounts) {
    if (freq[c]! > bestFreq) {
      bestFreq = freq[c]!;
      best = c;
    }
  }
  return best;
}
