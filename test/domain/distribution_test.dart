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

  test('canonical spec fixture: W=500, easy Tue(1), peak Sat(5)', () {
    expect(
      distributeWeek(weeklyTarget: 500, easyDay: 1, peakDay: 5),
      [70, 40, 70, 75, 75, 100, 70], // Mon..Sun — MUST match the spec example
    );
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

  test('invalid input throws', () {
    expect(() => distributeWeek(weeklyTarget: 87, easyDay: 1, peakDay: 5), throwsArgumentError);
    expect(() => distributeWeek(weeklyTarget: -5, easyDay: 1, peakDay: 5), throwsArgumentError);
    expect(() => distributeWeek(weeklyTarget: 500, easyDay: 3, peakDay: 3), throwsArgumentError);
  });
}
