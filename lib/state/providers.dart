import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../data/notification_scheduler.dart';
import '../data/repository.dart';
import '../domain/dates.dart';
import '../domain/notification_planner.dart';
import '../domain/streak.dart';

final databaseProvider =
    Provider<AppDatabase>((ref) => throw UnimplementedError('override in main/tests'));

final repositoryProvider =
    Provider<PushOnRepository>((ref) => PushOnRepository(ref.watch(databaseProvider)));

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final schedulerProvider = Provider<NotificationScheduler?>((ref) => null);

final settingsProvider =
    StreamProvider<AppSettings>((ref) => ref.watch(repositoryProvider).watchSettings());

final todayProvider = Provider<LocalDate>((ref) => LocalDate.from(ref.watch(clockProvider)()));

final weekPlanProvider = FutureProvider<WeekPlanData>((ref) =>
    ref.watch(repositoryProvider).ensureWeekPlan(ref.watch(todayProvider).weekStart));

final weekTotalsProvider = StreamProvider<Map<String, int>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(repositoryProvider)
      .watchDayTotals(today.weekStart, today.weekStart.addDays(6));
});

final weekRestDaysProvider = StreamProvider<Set<String>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(repositoryProvider)
      .watchRestDays(today.weekStart, today.weekStart.addDays(6));
});

final daySetsProvider = StreamProvider.family<List<SetEntry>, LocalDate>(
    (ref, date) => ref.watch(repositoryProvider).watchSetsForDay(date));

final summaryDueProvider = FutureProvider<LocalDate?>((ref) async {
  final s = await ref.watch(settingsProvider.future);
  final today = ref.watch(todayProvider);
  final currentWeek = today.weekStart;
  final install = s.installDate;
  if (install == null || !install.isBefore(currentWeek)) return null; // no completed week yet
  if (s.lastSummaryShownWeek != null && !s.lastSummaryShownWeek!.isBefore(currentWeek)) return null;
  return currentWeek.addDays(-7); // most recent completed week only — never queue
});

final firstOpenTodayProvider = Provider<DateTime>((ref) => ref.watch(clockProvider)());

/// Recomputes the rest-of-today notification plan on every relevant change
/// (new set, plan/settings/rest-day edits) and pushes it to the scheduler.
/// Activated by `ref.watch` from `PushOnApp.build` once onboarding is done.
final notificationSyncProvider = Provider<void>((ref) {
  final scheduler = ref.watch(schedulerProvider);
  if (scheduler == null) return;
  final today = ref.watch(todayProvider);
  final plan = ref.watch(weekPlanProvider).value;
  final settings = ref.watch(settingsProvider).value;
  final totals = ref.watch(weekTotalsProvider).value;
  final rest = ref.watch(weekRestDaysProvider).value;
  final sets = ref.watch(daySetsProvider(today)).value;
  if (plan == null || settings == null || totals == null || rest == null || sets == null) return;

  final idx = today.weekdayIndex;
  final target = plan.targets[idx];
  final logged = totals[today.iso] ?? 0;
  final planOut = planNotifications(
    now: ref.watch(clockProvider)(),
    remainingToday: target - logged,
    restOrZeroTarget: rest.contains(today.iso) || target == 0,
    lastSetAt: sets.isEmpty ? null : sets.last.createdAt,
    firstOpenToday: ref.watch(firstOpenTodayProvider),
    wakingStartMinutes: settings.wakingStartMinutes,
    wakingEndMinutes: settings.wakingEndMinutes,
    nudgeEnabled: settings.nudgeEnabled,
    reminderEnabled: settings.reminderEnabled,
  );
  scheduler.applyPlan(planOut);
});

final streakProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(repositoryProvider);
  final today = ref.watch(todayProvider);
  final install = ref.watch(settingsProvider).value?.installDate;
  if (install == null) return Stream.value(0);
  // Combine logged + transparent so a rest/sick toggle that bridges a gap
  // refreshes the streak immediately, not just on the next log (issue #4).
  return repo.watchStreakInputs(install, today).map((d) => computeStreak(
        today: today,
        installDate: install,
        loggedDays: d.logged.map(LocalDate.parse).toSet(),
        transparentDays: d.transparent.map(LocalDate.parse).toSet(),
      ));
});
