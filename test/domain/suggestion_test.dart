import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/suggestion.dart';

void main() {
  test('suggests 3-week average of logged, rounded DOWN to 5, when all hit and avg ratio >= 110%', () {
    expect(
      raiseSuggestion(currentTarget: 500, lastThreeCompleted: const [
        WeekResult(target: 500, logged: 560),
        WeekResult(target: 500, logged: 550),
        WeekResult(target: 500, logged: 542),
      ]),
      550, // avg 550.67 -> floor5 550
    );
  });

  test('null when any week missed target, even with a huge average', () {
    expect(
      raiseSuggestion(currentTarget: 500, lastThreeCompleted: const [
        WeekResult(target: 500, logged: 900),
        WeekResult(target: 500, logged: 900),
        WeekResult(target: 500, logged: 495),
      ]),
      isNull,
    );
  });

  test('null when average ratio below 110%', () {
    expect(
      raiseSuggestion(currentTarget: 500, lastThreeCompleted: const [
        WeekResult(target: 500, logged: 520),
        WeekResult(target: 500, logged: 530),
        WeekResult(target: 500, logged: 525),
      ]),
      isNull,
    );
  });

  test('null with fewer than 3 completed weeks', () {
    expect(
      raiseSuggestion(currentTarget: 500, lastThreeCompleted: const [
        WeekResult(target: 500, logged: 600),
        WeekResult(target: 500, logged: 600),
      ]),
      isNull,
    );
  });

  test('never suggests downward or sideways', () {
    expect(
      raiseSuggestion(currentTarget: 600, lastThreeCompleted: const [
        WeekResult(target: 500, logged: 560),
        WeekResult(target: 500, logged: 555),
        WeekResult(target: 500, logged: 560),
      ]),
      isNull, // floor5(avg 558.3)=555 < 600
    );
  });
}
