// Gamification, derived entirely from history — nothing here is stored
// (product invariant: stats come from `sets`/`week_plans`, never a column).
// Badges are threshold milestones across four tracks; personal bests are
// transient "you beat your record" moments surfaced when a set is logged.

enum BadgeCategory { lifetimeReps, streak, bestSet, perfectWeeks }

class BadgeDef {
  const BadgeDef({
    required this.category,
    required this.threshold,
    required this.emoji,
    required this.label,
  });
  final BadgeCategory category;
  final int threshold;
  final String emoji;
  final String label;

  String get id => '${category.name}_$threshold';
}

/// The full catalog, ascending threshold within each category.
const badgeCatalog = <BadgeDef>[
  BadgeDef(category: BadgeCategory.lifetimeReps, threshold: 1000, emoji: '🥉', label: '1,000 lifetime reps'),
  BadgeDef(category: BadgeCategory.lifetimeReps, threshold: 5000, emoji: '🥈', label: '5,000 lifetime reps'),
  BadgeDef(category: BadgeCategory.lifetimeReps, threshold: 10000, emoji: '🥇', label: '10,000 lifetime reps'),
  BadgeDef(category: BadgeCategory.lifetimeReps, threshold: 25000, emoji: '🏅', label: '25,000 lifetime reps'),
  BadgeDef(category: BadgeCategory.lifetimeReps, threshold: 50000, emoji: '💎', label: '50,000 lifetime reps'),
  BadgeDef(category: BadgeCategory.lifetimeReps, threshold: 100000, emoji: '👑', label: '100,000 lifetime reps'),
  BadgeDef(category: BadgeCategory.streak, threshold: 7, emoji: '🔥', label: '7-day streak'),
  BadgeDef(category: BadgeCategory.streak, threshold: 14, emoji: '⚡', label: '14-day streak'),
  BadgeDef(category: BadgeCategory.streak, threshold: 30, emoji: '🌟', label: '30-day streak'),
  BadgeDef(category: BadgeCategory.streak, threshold: 100, emoji: '💯', label: '100-day streak'),
  BadgeDef(category: BadgeCategory.bestSet, threshold: 25, emoji: '💪', label: 'A set of 25'),
  BadgeDef(category: BadgeCategory.bestSet, threshold: 50, emoji: '🦾', label: 'A set of 50'),
  BadgeDef(category: BadgeCategory.bestSet, threshold: 75, emoji: '🚀', label: 'A set of 75'),
  BadgeDef(category: BadgeCategory.bestSet, threshold: 100, emoji: '🏆', label: 'A set of 100'),
  BadgeDef(category: BadgeCategory.perfectWeeks, threshold: 1, emoji: '✅', label: '1 perfect week'),
  BadgeDef(category: BadgeCategory.perfectWeeks, threshold: 4, emoji: '📅', label: '4 perfect weeks'),
  BadgeDef(category: BadgeCategory.perfectWeeks, threshold: 12, emoji: '🗓️', label: '12 perfect weeks'),
  BadgeDef(category: BadgeCategory.perfectWeeks, threshold: 52, emoji: '🎯', label: '52 perfect weeks'),
];

/// Lifetime tallies the catalog is evaluated against.
class MilestoneStats {
  const MilestoneStats({
    this.lifetimeReps = 0,
    this.longestStreak = 0,
    this.bestSet = 0,
    this.perfectWeeks = 0,
  });
  final int lifetimeReps;
  final int longestStreak;
  final int bestSet;
  final int perfectWeeks;

  int valueFor(BadgeCategory c) => switch (c) {
        BadgeCategory.lifetimeReps => lifetimeReps,
        BadgeCategory.streak => longestStreak,
        BadgeCategory.bestSet => bestSet,
        BadgeCategory.perfectWeeks => perfectWeeks,
      };
}

bool isEarned(BadgeDef b, MilestoneStats s) => s.valueFor(b.category) >= b.threshold;

/// Every earned badge, in catalog order.
List<BadgeDef> earnedBadges(MilestoneStats s) =>
    [for (final b in badgeCatalog) if (isEarned(b, s)) b];

/// The next unearned badge in [c] (lowest threshold above the current value),
/// or null when the category is maxed out — for a "3,200 / 5,000" progress hint.
BadgeDef? nextLocked(BadgeCategory c, MilestoneStats s) {
  for (final b in badgeCatalog) {
    if (b.category == c && !isEarned(b, s)) return b;
  }
  return null;
}

/// Completed weeks whose logged total met the weekly target.
int countPerfectWeeks(Iterable<({int target, int logged})> weeks) =>
    weeks.where((w) => w.logged >= w.target).length;

/// The celebratory moment a just-logged set earns, if any. Priority: finishing
/// the week outranks finishing the day, which outranks a new personal best.
/// Pure so the trigger is unit-testable; the UI decides how to render each.
enum Celebration { none, personalBest, dayComplete, weekComplete }

Celebration celebrationFor({
  required int setCount,
  required int priorBestEver,
  required int dayBefore,
  required int dayTarget,
  required int weekBefore,
  required int weeklyTarget,
}) {
  final dayAfter = dayBefore + setCount;
  final weekAfter = weekBefore + setCount;
  final crossedWeek = weekBefore < weeklyTarget && weekAfter >= weeklyTarget && weeklyTarget > 0;
  final crossedDay = dayBefore < dayTarget && dayAfter >= dayTarget && dayTarget > 0;
  // A genuine "beat your record" — the very first set ever isn't beating one.
  final newBest = setCount > priorBestEver && priorBestEver > 0;
  if (crossedWeek) return Celebration.weekComplete;
  if (crossedDay) return Celebration.dayComplete;
  if (newBest) return Celebration.personalBest;
  return Celebration.none;
}
