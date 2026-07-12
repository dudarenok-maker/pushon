import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/rep_default.dart';

void main() {
  test('no history falls back to the default', () {
    expect(suggestedReps(const []), 20);
    expect(suggestedReps(const [], fallback: 12), 12);
  });

  test('consistent recent sets become the standard', () {
    expect(suggestedReps(const [15, 15, 15]), 15);
    expect(suggestedReps(const [30, 30]), 30);
  });

  test('the most common value wins over a one-off outlier', () {
    // Most-recent first: one stray 40 doesn't beat a run of 15s.
    expect(suggestedReps(const [40, 15, 15, 15]), 15);
  });

  test('ties break toward the more recent value', () {
    // 20 and 15 each appear twice; 20 is more recent, so it wins.
    expect(suggestedReps(const [20, 20, 15, 15]), 20);
    expect(suggestedReps(const [15, 15, 20, 20]), 15);
  });

  test('a single set is its own standard', () {
    expect(suggestedReps(const [25]), 25);
  });
}
