/// Nearest multiple of 5. Dart's `round()` breaks ties away from zero, so a
/// non-negative half rounds up (e.g. 12.5 → 15); every call site here passes a
/// non-negative value, so that is the only case that arises.
int round5(num x) => 5 * (x / 5).round();

/// Distributes [weeklyTarget] across the 7 days (0=Mon..6=Sun).
///
/// Spec: docs/specs/2026-07-11-pushon-v1-design.md "The distribution
/// algorithm". Hard invariant: multiples of 5, >= 0, sum == weeklyTarget.
///
/// [weekSeed] varies the whole week's shape week to week so consecutive weeks
/// don't look identical: all seven days (the easy and peak anchors included)
/// drift within per-day bands, while the easy day stays the smallest and the
/// peak day the largest. It is deterministic in the seed (same seed → same
/// plan), so the calendar's preview of a future week matches the plan
/// eventually stored for it. `weekSeed == 0` is the unshuffled reference
/// distribution (the spec's worked example); callers pass a per-week value.
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

  if (weekSeed != 0) _vary(targets, base, easyDay, peakDay, weekSeed);
  return targets;
}

/// Per-week variation bands as fractions of `base` (= round5(W/7)): the easy
/// day may swing across [40%, 70%] of base and the peak across [130%, 160%].
/// Normal days occupy the strict gap between the two anchor bands, so the easy
/// day is always the week's smallest value and the peak the largest — for any
/// seed. Bold spread (issue: weekly-plan variation).
const _easyLoPct = 0.4, _easyHiPct = 0.7;
const _peakLoPct = 1.3, _peakHiPct = 1.6;

/// Redistributes the reference plan by a seeded walk of sum-preserving ±5
/// transfers between any two days. Each transfer is applied only when both
/// ends stay inside their own `[lo, hi]` band, so the sum, the multiples-of-5
/// rule, and the band ordering (easy < normals < peak) are invariant for every
/// seed. Targets too small to honour the bands fall back to the reference.
void _vary(List<int> targets, int base, int easyDay, int peakDay, int seed) {
  final easyHi = round5(_easyHiPct * base);
  final peakLo = round5(_peakLoPct * base);
  final normLo = easyHi + 5, normHi = peakLo - 5;
  if (normHi < normLo) return; // anchor bands would meet (tiny target) — bail

  final lo = List<int>.filled(7, normLo);
  final hi = List<int>.filled(7, normHi);
  lo[easyDay] = round5(_easyLoPct * base);
  hi[easyDay] = easyHi;
  lo[peakDay] = peakLo;
  hi[peakDay] = round5(_peakHiPct * base);

  // The reference must start inside every band, or we leave it untouched
  // (defensive: only trips for targets small enough that the even split can't
  // sit within the bands).
  for (var d = 0; d < 7; d++) {
    if (targets[d] < lo[d] || targets[d] > hi[d]) return;
  }

  var rng = seed & 0x7fffffff;
  int next() => rng = (rng * 1103515245 + 12345) & 0x7fffffff;
  for (var step = 0; step < 24; step++) {
    final a = next() % 7;
    final b = next() % 7;
    if (a == b) continue;
    if (targets[a] - 5 >= lo[a] && targets[b] + 5 <= hi[b]) {
      targets[a] -= 5;
      targets[b] += 5;
    }
  }
}
