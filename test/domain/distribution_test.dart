import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/distribution.dart';

void main() {
  test('round5 rounds to nearest 5, ties up', () {
    expect(round5(87), 85);
    expect(round5(88), 90);
    expect(round5(42), 40);
    expect(round5(42.5), 45);
    expect(round5(0), 0);
  });

  test('canonical spec fixture: W=500, easy Tue(1), peak Sat(5), seed 0', () {
    expect(
      distributeWeek(weeklyTarget: 500, easyDay: 1, peakDay: 5),
      [70, 40, 70, 75, 75, 100, 70], // Mon..Sun — the seed-0 reference
    );
    // seed 0 is the explicit reference: no shuffle applied.
    expect(distributeWeek(weeklyTarget: 500, easyDay: 1, peakDay: 5, weekSeed: 0),
        [70, 40, 70, 75, 75, 100, 70]);
  });

  test('hard invariants hold across the whole input space', () {
    for (var w = 0; w <= 2000; w += 5) {
      for (var easy = 0; easy < 7; easy++) {
        for (var peak = 0; peak < 7; peak++) {
          if (easy == peak) continue;
          final t = distributeWeek(weeklyTarget: w, easyDay: easy, peakDay: peak);
          expect(t.length, 7);
          expect(t.reduce((a, b) => a + b), w, reason: 'sum W=$w e=$easy p=$peak');
          for (final v in t) {
            expect(v >= 0, isTrue);
            expect(v % 5, 0);
          }
        }
      }
    }
  });

  test('soft goals hold for a comfortable target: peak is max, easy is min', () {
    final t = distributeWeek(weeklyTarget: 500, easyDay: 1, peakDay: 5);
    expect(t[5], t.reduce((a, b) => a > b ? a : b));
    expect(t[1], t.reduce((a, b) => a < b ? a : b));
  });

  test('tiny target: W=30 drops a day to 0 and still sums', () {
    final t = distributeWeek(weeklyTarget: 30, easyDay: 1, peakDay: 5);
    expect(t.reduce((a, b) => a + b), 30);
    expect(t.contains(0), isTrue);
  });

  test('peak on Monday: leftover wraps without crashing', () {
    final t = distributeWeek(weeklyTarget: 500, easyDay: 2, peakDay: 0);
    expect(t.reduce((a, b) => a + b), 500);
  });

  test('hard invariants survive per-week variation across seeds', () {
    for (final w in [30, 100, 355, 500, 505, 1000, 2000]) {
      for (var easy = 0; easy < 7; easy++) {
        for (var peak = 0; peak < 7; peak++) {
          if (easy == peak) continue;
          for (var seed = 1; seed <= 40; seed++) {
            final t = distributeWeek(
                weeklyTarget: w, easyDay: easy, peakDay: peak, weekSeed: seed);
            expect(t.reduce((a, b) => a + b), w,
                reason: 'sum W=$w e=$easy p=$peak seed=$seed');
            for (final v in t) {
              expect(v >= 0 && v % 5 == 0, isTrue,
                  reason: 'value $v W=$w e=$easy p=$peak seed=$seed');
            }
          }
        }
      }
    }
  });

  test('variation never disturbs the anchors or the soft goals (comfortable W)', () {
    final ref = distributeWeek(weeklyTarget: 500, easyDay: 1, peakDay: 5);
    for (var seed = 1; seed <= 60; seed++) {
      final t = distributeWeek(weeklyTarget: 500, easyDay: 1, peakDay: 5, weekSeed: seed);
      expect(t[1], ref[1], reason: 'easy day value is fixed');
      expect(t[5], ref[5], reason: 'peak day value is fixed');
      expect(t[5], t.reduce((a, b) => a > b ? a : b), reason: 'peak stays the max');
      expect(t[1], t.reduce((a, b) => a < b ? a : b), reason: 'easy stays the min');
    }
  });

  test('consecutive weeks actually move around', () {
    final shapes = {
      for (var seed = 1; seed <= 40; seed++)
        distributeWeek(weeklyTarget: 500, easyDay: 1, peakDay: 5, weekSeed: seed).join(',')
    };
    // Moderate variation should yield several distinct weekly shapes, not one.
    expect(shapes.length, greaterThan(3));
  });

  test('same seed is deterministic', () {
    for (final seed in [1, 7, 42, 1000, 999999]) {
      expect(
        distributeWeek(weeklyTarget: 500, easyDay: 1, peakDay: 5, weekSeed: seed),
        distributeWeek(weeklyTarget: 500, easyDay: 1, peakDay: 5, weekSeed: seed),
      );
    }
  });

  test('tiny target squeezes the band shut: variation is a no-op', () {
    final ref = distributeWeek(weeklyTarget: 30, easyDay: 1, peakDay: 5);
    for (var seed = 1; seed <= 20; seed++) {
      expect(distributeWeek(weeklyTarget: 30, easyDay: 1, peakDay: 5, weekSeed: seed), ref);
    }
  });

  test('invalid input throws', () {
    expect(() => distributeWeek(weeklyTarget: 87, easyDay: 1, peakDay: 5), throwsArgumentError);
    expect(() => distributeWeek(weeklyTarget: -5, easyDay: 1, peakDay: 5), throwsArgumentError);
    expect(() => distributeWeek(weeklyTarget: 500, easyDay: 3, peakDay: 3), throwsArgumentError);
  });
}
