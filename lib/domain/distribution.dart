/// Nearest multiple of 5; ties round up (Dart's round() is half-away-from-zero).
int round5(num x) => 5 * (x / 5).round();

/// Distributes [weeklyTarget] across the 7 days (0=Mon..6=Sun).
///
/// Spec: docs/specs/2026-07-11-pushon-v1-design.md "The distribution
/// algorithm". Hard invariant: multiples of 5, >= 0, sum == weeklyTarget.
List<int> distributeWeek({
  required int weeklyTarget,
  required int easyDay,
  required int peakDay,
}) {
  if (weeklyTarget < 0 || weeklyTarget % 5 != 0) {
    throw ArgumentError.value(weeklyTarget, 'weeklyTarget', 'must be a non-negative multiple of 5');
  }
  if (easyDay == peakDay) {
    throw ArgumentError('easyDay and peakDay must differ');
  }

  final base = round5(weeklyTarget / 7);
  final targets = List<int>.filled(7, 0);
  targets[easyDay] = round5(0.6 * base);
  targets[peakDay] = round5(1.4 * base);

  // The five normal days, ordered by proximity BEFORE the peak day,
  // wrapping past the week start to the days after it.
  final normal = <int>[];
  for (var k = 1; k <= 6; k++) {
    final d = (peakDay - k) % 7; // Dart % is non-negative for positive divisor
    if (d != easyDay) normal.add(d);
  }

  final per = round5((weeklyTarget - targets[easyDay] - targets[peakDay]) / 5);
  for (final d in normal) {
    targets[d] = per > 0 ? per : 0;
  }

  // Adjustment pass: +5 in `normal` order while short; -5 in reverse order
  // (then peak, then easy) while over, skipping days already at 0.
  var diff = weeklyTarget - targets.reduce((a, b) => a + b);
  var i = 0;
  while (diff > 0) {
    targets[normal[i % normal.length]] += 5;
    diff -= 5;
    i++;
  }
  final drain = [...normal.reversed, peakDay, easyDay];
  i = 0;
  while (diff < 0) {
    final d = drain[i % drain.length];
    if (targets[d] >= 5) {
      targets[d] -= 5;
      diff += 5;
    }
    i++;
  }
  return targets;
}
