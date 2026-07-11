import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/data/db.dart';
import 'package:pushon/data/repository.dart';
import 'package:pushon/domain/dates.dart';

void main() {
  late AppDatabase db;
  late PushOnRepository repo;
  var idCounter = 0;
  final now = DateTime(2026, 7, 11, 9);
  const day = LocalDate(2026, 7, 11);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    idCounter = 0;
    repo = PushOnRepository(db, newId: () => 'id-${idCounter++}');
  });
  tearDown(() => db.close());

  test('log, edit, soft-delete; totals and sets exclude deleted', () async {
    await repo.logSet(date: day, count: 25, now: now);
    await repo.logSet(date: day, count: 15, now: now);
    expect((await repo.watchSetsForDay(day).first).map((s) => s.count), [25, 15]);
    await repo.editSet(id: 'id-1', count: 20, now: now);
    expect((await repo.watchSetsForDay(day).first).map((s) => s.count), [25, 20]);
    await repo.deleteSet(id: 'id-0', now: now);
    expect((await repo.watchSetsForDay(day).first).map((s) => s.count), [20]);
    final totals = await repo.watchDayTotals(day, day).first;
    expect(totals[day.iso], 20);
  });

  test('defaults come back when nothing is stored', () async {
    final s = await repo.getSettings();
    expect(s.weeklyTarget, 500);
    expect(s.easyDay, 1);
    expect(s.peakDay, 5);
    expect(s.wakingStartMinutes, 480);
    expect(s.wakingEndMinutes, 1260);
    expect(s.nudgeEnabled, isTrue);
    expect(s.installDate, isNull);
  });

  test('ensureWeekPlan writes once and never recomputes after settings change', () async {
    const monday = LocalDate(2026, 7, 6);
    final plan1 = await repo.ensureWeekPlan(monday);
    expect(plan1.targets, [70, 40, 70, 75, 75, 100, 70]);
    await repo.patchSettings({'weeklyTarget': '1000'});
    final plan2 = await repo.ensureWeekPlan(monday);
    expect(plan2.targets, plan1.targets, reason: 'stored plans never mutate');
    final fresh = await repo.ensureWeekPlan(const LocalDate(2026, 7, 13));
    expect(fresh.weeklyTarget, 1000, reason: 'new weeks use current settings');
  });

  test('rest flags round-trip; transparent days = rest plus target-0', () async {
    await repo.setRest(day, true);
    expect(await repo.watchRestDays(day, day).first, {day.iso});
    await repo.setRest(day, false);
    expect(await repo.watchRestDays(day, day).first, isEmpty);
    // W=30 forces a 0-target day somewhere in the stored plan.
    await repo.patchSettings({'weeklyTarget': '30'});
    const monday = LocalDate(2026, 7, 6);
    final plan = await repo.ensureWeekPlan(monday);
    final zeroIdx = plan.targets.indexOf(0);
    final transparent = await repo.watchTransparentDays(monday, monday.addDays(6)).first;
    expect(transparent.contains(monday.addDays(zeroIdx).iso), isTrue);
  });

  test('watchWeekPlans returns stored plans keyed by weekStart', () async {
    const monday = LocalDate(2026, 7, 6);
    await repo.ensureWeekPlan(monday);
    final plans = await repo.watchWeekPlans(monday, monday.addDays(6)).first;
    expect(plans.keys, ['2026-07-06']);
  });

  test('watchBestSet returns the max count, 0 when empty', () async {
    expect(await repo.watchBestSet(day, day).first, 0);
    await repo.logSet(date: day, count: 25, now: now);
    await repo.logSet(date: day, count: 40, now: now);
    await repo.deleteSet(id: 'id-1', now: now); // the 40
    expect(await repo.watchBestSet(day, day).first, 25);
  });
}
