import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import '../domain/suggestion.dart';
import '../state/providers.dart';
import 'theme.dart';
import 'widgets/badges_section.dart';

/// (plan, logged-per-day, best, best-set trend) for the most recent completed
/// week, plus the 3-week WeekResult history for the suggestion rule.
final summaryDataProvider = FutureProvider<
    ({WeekPlanData plan, List<int> logged, int best, List<int> bestTrend, int? suggestion})?>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final today = ref.watch(todayProvider);
  final lastWeek = today.weekStart.addDays(-7);
  final s = await ref.watch(settingsProvider.future);
  if (s.installDate == null || !s.installDate!.isBefore(today.weekStart)) return null;
  final plan = await repo.ensureWeekPlan(lastWeek);
  final totals = await repo.watchDayTotals(lastWeek, lastWeek.addDays(6)).first;
  final logged = [for (var d = 0; d < 7; d++) totals[lastWeek.addDays(d).iso] ?? 0];
  final best = await repo.watchBestSet(lastWeek, lastWeek.addDays(6)).first;

  final history = <WeekResult>[];
  for (var back = 1; back <= 3; back++) {
    final w = today.weekStart.addDays(-7 * back);
    if (w.isBefore(s.installDate!.weekStart)) break;
    final p = await repo.getWeekPlan(w);
    if (p == null) break;
    final t = await repo.watchDayTotals(w, w.addDays(6)).first;
    history.add(WeekResult(
        target: p.weeklyTarget, logged: t.values.fold(0, (a, b) => a + b)));
  }
  final suggestion = history.length == 3
      ? raiseSuggestion(lastThreeCompleted: history, currentTarget: s.weeklyTarget)
      : null;

  // Best-set trend: the spec's "see if your max is improving" — last 8
  // completed weeks (oldest first), clipped to post-install weeks.
  final bestTrend = <int>[];
  for (var back = 8; back >= 1; back--) {
    final w = today.weekStart.addDays(-7 * back);
    if (w.isBefore(s.installDate!.weekStart)) continue;
    bestTrend.add(await repo.watchBestSet(w, w.addDays(6)).first);
  }

  return (plan: plan, logged: logged, best: best, bestTrend: bestTrend, suggestion: suggestion);
});

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(summaryDataProvider).value;
    final streak = ref.watch(streakProvider).value ?? 0;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Summary')),
        body: ListView(padding: const EdgeInsets.all(16), children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Your first summary arrives on Monday.', textAlign: TextAlign.center),
          ),
          BadgesSection(),
        ]),
      );
    }
    final total = data.logged.fold(0, (a, b) => a + b);
    final target = data.plan.weeklyTarget;
    final maxBar = [
      ...data.logged, ...data.plan.targets
    ].reduce((a, b) => a > b ? a : b).clamp(1, 1 << 31);
    return Scaffold(
      appBar: AppBar(title: const Text('Last week')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('$total / $target',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800,
                color: total >= target ? kCoral : kInk)),
        Text(total >= target ? 'Target hit — nice work!' : 'Under target — this week is a fresh start.',
            textAlign: TextAlign.center, style: const TextStyle(color: kInk)),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var d = 0; d < 7; d++)
                Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                    width: 22,
                    height: 100.0 * data.logged[d] / maxBar,
                    decoration: BoxDecoration(
                      color: data.logged[d] >= data.plan.targets[d] ? kCoral : kInk.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][d],
                      style: const TextStyle(fontSize: 11, color: kInk)),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Best set: ${data.best}   ·   🔥 $streak day streak',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, color: kInk)),
        if (data.bestTrend.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Best set trend',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(data.bestTrend.join('  →  '),
                textAlign: TextAlign.center,
                style: TextStyle(color: kInk.withValues(alpha: 0.7))),
          ),
        ],
        if (data.suggestion != null)
          Card(
            color: kSunshine,
            margin: const EdgeInsets.only(top: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Text('Three strong weeks in a row — ready for more?',
                    style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  FilledButton(
                    onPressed: () async {
                      await ref.read(repositoryProvider)
                          .patchSettings({'weeklyTarget': '${data.suggestion}'});
                      ref.invalidate(summaryDataProvider);
                    },
                    child: Text('Raise to ${data.suggestion}'),
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Keep current')),
                ]),
              ]),
            ),
          ),
        const Divider(height: 32),
        const BadgesSection(),
      ]),
    );
  }
}
