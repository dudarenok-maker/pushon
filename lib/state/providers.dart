import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../data/notification_scheduler.dart';
import '../data/repository.dart';
import '../domain/dates.dart';
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

final streakProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(repositoryProvider);
  final today = ref.watch(todayProvider);
  final install = ref.watch(settingsProvider).value?.installDate;
  if (install == null) return Stream.value(0);
  final logged = repo.watchLoggedDays(install, today);
  final transparent = repo.watchTransparentDays(install, today);
  return logged.asyncMap((l) async => computeStreak(
        today: today,
        installDate: install,
        loggedDays: l.map(LocalDate.parse).toSet(),
        transparentDays: (await transparent.first).map(LocalDate.parse).toSet(),
      ));
});
