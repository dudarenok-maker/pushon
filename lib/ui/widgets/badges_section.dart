import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/achievements.dart';
import '../../state/providers.dart';
import '../theme.dart';

/// Earned badges plus the next milestone in each track. All derived from
/// history via [milestoneStatsProvider] — nothing stored.
class BadgesSection extends ConsumerWidget {
  const BadgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(milestoneStatsProvider);
    final earned = earnedBadges(stats);
    final upNext = [
      for (final c in BadgeCategory.values)
        if (nextLocked(c, stats) case final b?) (badge: b, value: stats.valueFor(c)),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 8),
        child: Text('Badges',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
      ),
      if (earned.isEmpty)
        Text('No badges yet — keep logging to earn your first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kInk.withValues(alpha: 0.6)))
      else
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [for (final b in earned) _EarnedChip(b)],
        ),
      if (upNext.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Up next', style: TextStyle(fontSize: 12, color: kInk.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        for (final n in upNext) _UpNextRow(badge: n.badge, value: n.value),
      ],
    ]);
  }
}

class _EarnedChip extends StatelessWidget {
  const _EarnedChip(this.badge);
  final BadgeDef badge;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: kSunshine,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 2),
          Text(badge.label, style: const TextStyle(fontSize: 10, color: kInk, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _UpNextRow extends StatelessWidget {
  const _UpNextRow({required this.badge, required this.value});
  final BadgeDef badge;
  final int value;

  @override
  Widget build(BuildContext context) {
    final progress = (value / badge.threshold).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Opacity(opacity: 0.4, child: Text(badge.emoji, style: const TextStyle(fontSize: 18))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(badge.label, style: const TextStyle(fontSize: 12, color: kInk)),
            const SizedBox(height: 2),
            // A static bar (not LinearProgressIndicator, which ticks an
            // animation controller forever and would stop pumpAndSettle from
            // ever settling on this screen).
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 5,
                color: kInk.withValues(alpha: 0.1),
                child: FractionallySizedBox(
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(color: kCoral),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Text('$value/${badge.threshold}',
            style: TextStyle(fontSize: 11, color: kInk.withValues(alpha: 0.6))),
      ]),
    );
  }
}
