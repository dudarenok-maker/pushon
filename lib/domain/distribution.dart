/// Nearest multiple of 5; ties round up (Dart's round() is half-away-from-zero).
int round5(num x) => 5 * (x / 5).round();

/// Distributes [weeklyTarget] across the 7 days (0=Mon..6=Sun).
///
/// Spec: docs/specs/2026-07-11-pushon-v1-design.md "The distribution
/// algorithm". Hard invariant: multiples of 5, >= 0, sum == weeklyTarget.
///
/// [weekSeed] varies the five normal days week to week so consecutive weeks
/// don't look identical, while the easy day stays the smallest and the peak
/// day the largest. It is deterministic in the seed (same seed → same plan),
/// so the calendar's preview of a future week matches the plan eventually
/// stored for it. `weekSeed == 0` is the unshuffled reference distribution
/// (the spec's worked example); callers pass a per-week value.
List<int> distributeWeek({
  required int weeklyTarget,
  required int easyDay,
  required int peakDay,
  int weekSeed = 0,
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

  if (weekSeed != 0) _varyNormals(targets, easyDay, peakDay, weekSeed);
  return targets;
}

/// Shuffles the five normal days within a moderate band around their shared
/// base, using a walk of sum-preserving ±5 transfers between two normal days.
/// Every transfer is applied only when it keeps both ends inside `[lo, hi]`,
/// so the sum and the easy/peak anchors are invariant for any seed. Degenerate
/// configs (tiny targets that squeeze the band shut) fall back to the
/// reference split untouched.
void _varyNormals(List<int> targets, int easyDay, int peakDay, int seed) {
  final normals = [
    for (var d = 0; d < 7; d++)
      if (d != easyDay && d != peakDay) d
  ];
  if (normals.length != 5) return;

  final base = round5(normals.map((d) => targets[d]).reduce((a, b) => a + b) / 5);
  final lo = [targets[easyDay] + 5, base - 15, 0].reduce((a, b) => a > b ? a : b);
  final hi = [targets[peakDay] - 5, base + 15].reduce((a, b) => a < b ? a : b);
  if (hi < lo) return; // no room between the anchors — keep the reference
  for (final d in normals) {
    if (targets[d] < lo || targets[d] > hi) return; // squeezed; don't risk it
  }

  var rng = seed & 0x7fffffff;
  int next() => rng = (rng * 1103515245 + 12345) & 0x7fffffff;
  for (var step = 0; step < 12; step++) {
    final s = normals[next() % 5];
    final t = normals[next() % 5];
    if (s == t) continue;
    if (targets[s] - 5 >= lo && targets[t] + 5 <= hi) {
      targets[s] -= 5;
      targets[t] += 5;
    }
  }
}
