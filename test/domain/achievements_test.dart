import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/achievements.dart';

void main() {
  test('catalog is ascending within each category and ids are unique', () {
    final ids = <String>{};
    final lastPerCat = <BadgeCategory, int>{};
    for (final b in badgeCatalog) {
      expect(ids.add(b.id), isTrue, reason: 'duplicate ${b.id}');
      final last = lastPerCat[b.category];
      if (last != null) expect(b.threshold, greaterThan(last), reason: '${b.category} not ascending');
      lastPerCat[b.category] = b.threshold;
      expect(b.emoji, isNotEmpty);
      expect(b.label, isNotEmpty);
    }
  });

  test('a badge is earned exactly when its track meets the threshold', () {
    const s = MilestoneStats(lifetimeReps: 5000, longestStreak: 10, bestSet: 50, perfectWeeks: 0);
    const b5k = BadgeDef(category: BadgeCategory.lifetimeReps, threshold: 5000, emoji: '🥈', label: '');
    const b10k = BadgeDef(category: BadgeCategory.lifetimeReps, threshold: 10000, emoji: '🥇', label: '');
    expect(isEarned(b5k, s), isTrue, reason: 'exactly at threshold counts');
    expect(isEarned(b10k, s), isFalse);
  });

  test('earnedBadges reflects each track independently', () {
    const s = MilestoneStats(lifetimeReps: 12000, longestStreak: 7, bestSet: 30, perfectWeeks: 4);
    final earned = earnedBadges(s).map((b) => b.id).toSet();
    expect(earned, contains('lifetimeReps_10000'));
    expect(earned, isNot(contains('lifetimeReps_25000')));
    expect(earned, contains('streak_7'));
    expect(earned, isNot(contains('streak_14')));
    expect(earned, contains('bestSet_25'));
    expect(earned, isNot(contains('bestSet_50')));
    expect(earned, containsAll(['perfectWeeks_1', 'perfectWeeks_4']));
    expect(earned, isNot(contains('perfectWeeks_12')));
  });

  test('nextLocked points at the lowest unearned threshold, null when maxed', () {
    const s = MilestoneStats(bestSet: 60);
    expect(nextLocked(BadgeCategory.bestSet, s)?.threshold, 75);
    const maxed = MilestoneStats(bestSet: 100);
    expect(nextLocked(BadgeCategory.bestSet, maxed), isNull);
    const none = MilestoneStats(bestSet: 0);
    expect(nextLocked(BadgeCategory.bestSet, none)?.threshold, 25);
  });

  test('countPerfectWeeks counts weeks that met target (>=)', () {
    expect(
      countPerfectWeeks([
        (target: 500, logged: 500), // exactly met — counts
        (target: 500, logged: 620), // over — counts
        (target: 500, logged: 480), // short — no
        (target: 300, logged: 300),
      ]),
      3,
    );
    expect(countPerfectWeeks(const []), 0);
  });

  group('celebrationFor', () {
    Celebration cel({int setCount = 20, int priorBestEver = 30, int dayBefore = 0,
            int dayTarget = 100, int weekBefore = 0, int weeklyTarget = 500}) =>
        celebrationFor(setCount: setCount, priorBestEver: priorBestEver, dayBefore: dayBefore,
            dayTarget: dayTarget, weekBefore: weekBefore, weeklyTarget: weeklyTarget);

    test('nothing special → none', () {
      expect(cel(), Celebration.none);
    });

    test('crossing the daily target → dayComplete', () {
      expect(cel(setCount: 90, dayBefore: 20, dayTarget: 100), Celebration.dayComplete);
    });

    test('crossing the weekly target outranks the day', () {
      // This set finishes both the day and the week; week wins.
      expect(cel(setCount: 100, dayBefore: 0, dayTarget: 90, weekBefore: 450, weeklyTarget: 500),
          Celebration.weekComplete);
    });

    test('a new personal best when nothing else crosses', () {
      expect(cel(setCount: 40, priorBestEver: 30, dayBefore: 0, dayTarget: 500), Celebration.personalBest);
    });

    test('the very first set ever is not a personal best', () {
      expect(cel(setCount: 20, priorBestEver: 0, dayTarget: 500, weeklyTarget: 5000), Celebration.none);
    });

    test('already past the target → no repeat celebration', () {
      expect(cel(setCount: 10, dayBefore: 100, dayTarget: 100, priorBestEver: 50), Celebration.none);
    });

    test('rest/zero-target day never fires dayComplete', () {
      expect(cel(setCount: 20, dayBefore: 0, dayTarget: 0, priorBestEver: 50, weeklyTarget: 5000),
          Celebration.none);
    });
  });
}
