import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/achievements.dart';
import '../domain/on_track.dart';
import '../state/providers.dart';
import 'settings_screen.dart' show requestBatteryExemption;
import 'theme.dart';
import 'widgets/celebration.dart';
import 'widgets/progress_ring.dart';
import 'widgets/week_strip.dart';
import 'widgets/wheel_log_sheet.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final plan = ref.watch(weekPlanProvider).value;
    final sets = ref.watch(daySetsProvider(today)).value ?? const [];
    final totals = ref.watch(weekTotalsProvider).value ?? const {};
    final restDays = ref.watch(weekRestDaysProvider).value ?? const {};
    final streak = ref.watch(streakProvider).value ?? 0;

    final todayIdx = today.weekdayIndex;
    final target = plan?.targets[todayIdx] ?? 0;
    final logged = totals[today.iso] ?? 0;
    final best = sets.isEmpty ? 0 : sets.map((s) => s.count).reduce((a, b) => a > b ? a : b);
    final weekLogged = totals.values.fold(0, (a, b) => a + b);
    final restIdx = <int>{
      for (var d = 0; d < 7; d++)
        if (restDays.contains(today.weekStart.addDays(d).iso)) d
    };
    final onTrack = plan == null
        ? null
        : onTrackPerDay(
            weeklyTarget: plan.weeklyTarget, targets: plan.targets,
            loggedThisWeek: weekLogged, restDayIndexes: restIdx, todayIndex: todayIdx);

    Future<void> log() async {
      final last = sets.isEmpty ? 20 : sets.last.count;
      final count = await showWheelPicker(context, title: 'How many?', initial: last);
      if (count == null) return;
      final priorBest = ref.read(milestoneStatsProvider).bestSet; // before this set lands
      final now = ref.read(clockProvider)();
      await ref.read(repositoryProvider).logSet(date: today, count: count, now: now);
      if (context.mounted) {
        showCelebration(context, celebrationFor(
          setCount: count,
          priorBestEver: priorBest,
          dayBefore: logged,
          dayTarget: target,
          weekBefore: weekLogged,
          weeklyTarget: plan?.weeklyTarget ?? 0,
        ));
      }
      final settings = ref.read(settingsProvider).value;
      if (settings != null && !settings.batteryPromptShown && context.mounted) {
        await requestBatteryExemption(context);
        await ref.read(repositoryProvider).patchSettings({'batteryPromptShown': 'true'});
      }
    }

    ref.listen(summaryDueProvider, (prev, next) {
      final due = next.value;
      if (due != null) {
        ref.read(repositoryProvider).patchSettings(
            {'lastSummaryShownWeek': ref.read(todayProvider).weekStart.iso});
        context.push('/weekly-summary'); // top-level takeover route, NOT the shell branch
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('PushOn'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/settings')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const WeekStrip(),
          const SizedBox(height: 16),
          Center(child: ProgressRing(logged: logged, target: target)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Chip(
                backgroundColor: kSunshine,
                label: Text('🔥 $streak day streak',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
              ),
              const SizedBox(width: 8),
              Text('Best set: $best', style: const TextStyle(color: kInk)),
            ],
          ),
          if (onTrack != null && onTrack > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('$onTrack/day to stay on track this week',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kInk.withValues(alpha: 0.6))),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: log,
              icon: const Icon(Icons.add),
              label: const Text('Log'),
            ),
          ),
          const SizedBox(height: 16),
          for (final s in sets)
            ListTile(
              key: ValueKey(s.id),
              title: Text('${s.count} reps'),
              subtitle: Text(TimeOfDay.fromDateTime(s.createdAt).format(context)),
              onTap: () async {
                final count = await showWheelPicker(context, title: 'Edit set', initial: s.count);
                if (count == null) return;
                await ref.read(repositoryProvider)
                    .editSet(id: s.id, count: count, now: ref.read(clockProvider)());
              },
              onLongPress: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete this set?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(repositoryProvider)
                      .deleteSet(id: s.id, now: ref.read(clockProvider)());
                }
              },
            ),
        ],
      ),
    );
  }
}
