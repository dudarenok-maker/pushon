import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/dates.dart';
import '../domain/distribution.dart';
import 'db.dart';

class SetEntry {
  const SetEntry({required this.id, required this.date, required this.count, required this.createdAt});
  final String id;
  final LocalDate date;
  final int count;
  final DateTime createdAt;
}

class WeekPlanData {
  const WeekPlanData({required this.weekStart, required this.weeklyTarget,
      required this.targets, required this.easyDay, required this.peakDay});
  final LocalDate weekStart;
  final int weeklyTarget;
  final List<int> targets;
  final int easyDay;
  final int peakDay;
}

class AppSettings {
  const AppSettings({
    this.weeklyTarget = 500,
    this.easyDay = 1,
    this.peakDay = 5,
    this.wakingStartMinutes = 480,
    this.wakingEndMinutes = 1260,
    this.nudgeEnabled = true,
    this.reminderEnabled = true,
    this.installDate,
    this.lastSummaryShownWeek,
    this.batteryPromptShown = false,
  });
  final int weeklyTarget;
  final int easyDay;
  final int peakDay;
  final int wakingStartMinutes;
  final int wakingEndMinutes;
  final bool nudgeEnabled;
  final bool reminderEnabled;
  final LocalDate? installDate;
  final LocalDate? lastSummaryShownWeek;
  final bool batteryPromptShown;

  static AppSettings fromKv(Map<String, String> kv) => AppSettings(
        weeklyTarget: int.tryParse(kv['weeklyTarget'] ?? '') ?? 500,
        easyDay: int.tryParse(kv['easyDay'] ?? '') ?? 1,
        peakDay: int.tryParse(kv['peakDay'] ?? '') ?? 5,
        wakingStartMinutes: int.tryParse(kv['wakingStartMinutes'] ?? '') ?? 480,
        wakingEndMinutes: int.tryParse(kv['wakingEndMinutes'] ?? '') ?? 1260,
        nudgeEnabled: kv['nudgeEnabled'] != 'false',
        reminderEnabled: kv['reminderEnabled'] != 'false',
        installDate: kv['installDate'] != null ? LocalDate.parse(kv['installDate']!) : null,
        lastSummaryShownWeek: kv['lastSummaryShownWeek'] != null
            ? LocalDate.parse(kv['lastSummaryShownWeek']!) : null,
        batteryPromptShown: kv['batteryPromptShown'] == 'true',
      );
}

class PushOnRepository {
  PushOnRepository(this._db, {String Function()? newId})
      : _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final String Function() _newId;

  // ---- sets ----

  Future<void> logSet({required LocalDate date, required int count, required DateTime now}) =>
      _db.into(_db.sets).insert(SetsCompanion.insert(
          id: _newId(), date: date.iso, count: count, createdAt: now, updatedAt: now));

  Future<void> editSet({required String id, required int count, required DateTime now}) =>
      (_db.update(_db.sets)..where((t) => t.id.equals(id)))
          .write(SetsCompanion(count: Value(count), updatedAt: Value(now)));

  Future<void> deleteSet({required String id, required DateTime now}) =>
      (_db.update(_db.sets)..where((t) => t.id.equals(id)))
          .write(SetsCompanion(deletedAt: Value(now), updatedAt: Value(now)));

  SimpleSelectStatement<$SetsTable, SetsData> _liveSets(LocalDate from, LocalDate to) =>
      _db.select(_db.sets)
        ..where((t) => t.deletedAt.isNull() & t.date.isBetweenValues(from.iso, to.iso));

  Stream<List<SetEntry>> watchSetsForDay(LocalDate date) =>
      // rowid tiebreaker keeps same-instant sets in insertion order — createdAt
      // alone is not unique (several sets can share a timestamp), which would
      // otherwise leave display/best-set order at the mercy of the table scan.
      (_liveSets(date, date)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt), (t) => OrderingTerm.asc(t.rowId)]))
          .watch()
          .map((rows) => [
                for (final r in rows)
                  SetEntry(id: r.id, date: LocalDate.parse(r.date), count: r.count, createdAt: r.createdAt)
              ]);

  Stream<Map<String, int>> watchDayTotals(LocalDate from, LocalDate to) =>
      _liveSets(from, to).watch().map((rows) {
        final out = <String, int>{};
        for (final r in rows) {
          out[r.date] = (out[r.date] ?? 0) + r.count;
        }
        return out;
      });

  Stream<Set<String>> watchLoggedDays(LocalDate from, LocalDate to) =>
      watchDayTotals(from, to).map((m) => m.keys.toSet());

  /// Logged and transparent (rest/target-0) day-sets in one stream, so a
  /// consumer re-emits when *either* changes. The streak needs this: flagging
  /// a day rest/sick to bridge a gap changes only the transparent set, and a
  /// stream that watches logged days alone would show a stale streak until the
  /// next log or a day rollover (issue #4).
  Stream<({Set<String> logged, Set<String> transparent})> watchStreakInputs(
          LocalDate from, LocalDate to) =>
      _combineLatest2(watchLoggedDays(from, to), watchTransparentDays(from, to),
          (l, t) => (logged: l, transparent: t));

  /// The counts of the most recent [limit] live sets, newest first — feeds the
  /// logger's "standard reps" default.
  Stream<List<int>> watchRecentSetCounts({int limit = 10}) =>
      (_db.select(_db.sets)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt), (t) => OrderingTerm.desc(t.rowId)])
            ..limit(limit))
          .watch()
          .map((rows) => [for (final r in rows) r.count]);

  Stream<int> watchBestSet(LocalDate from, LocalDate to) =>
      _liveSets(from, to).watch().map((rows) =>
          rows.isEmpty ? 0 : rows.map((r) => r.count).reduce((a, b) => a > b ? a : b));

  /// Lifetime totals over every live set — reps summed and the best single set,
  /// for the lifetime-reps and best-set milestone badges.
  Stream<({int reps, int best})> watchLifetimeTotals() =>
      (_db.select(_db.sets)..where((t) => t.deletedAt.isNull())).watch().map((rows) {
        var reps = 0, best = 0;
        for (final r in rows) {
          reps += r.count;
          if (r.count > best) best = r.count;
        }
        return (reps: reps, best: best);
      });

  /// Completed weeks — those with a stored plan starting before
  /// [currentWeekStart] — as (weeklyTarget, logged) pairs, for perfect-week
  /// badges. Joins plans with per-week logged totals over all live sets.
  Stream<List<({int target, int logged})>> watchCompletedWeekResults(LocalDate currentWeekStart) {
    final plans = (_db.select(_db.weekPlans)
          ..where((t) => t.weekStart.isSmallerThanValue(currentWeekStart.iso)))
        .watch();
    final sets = (_db.select(_db.sets)..where((t) => t.deletedAt.isNull())).watch();
    return _combineLatest2(plans, sets, (planRows, setRows) {
      final byWeek = <String, int>{};
      for (final r in setRows) {
        final ws = LocalDate.parse(r.date).weekStart.iso;
        byWeek[ws] = (byWeek[ws] ?? 0) + r.count;
      }
      return [
        for (final p in planRows) (target: p.weeklyTarget, logged: byWeek[p.weekStart] ?? 0)
      ];
    });
  }

  // ---- day flags ----

  Future<void> setRest(LocalDate date, bool rest) => _db
      .into(_db.dayFlags)
      .insertOnConflictUpdate(DayFlagsCompanion.insert(date: date.iso, rest: Value(rest)));

  Stream<Set<String>> watchRestDays(LocalDate from, LocalDate to) =>
      (_db.select(_db.dayFlags)
            ..where((t) => t.rest.equals(true) & t.date.isBetweenValues(from.iso, to.iso)))
          .watch()
          .map((rows) => rows.map((r) => r.date).toSet());

  Stream<Set<String>> watchTransparentDays(LocalDate from, LocalDate to) {
    final zeroDays = (_db.select(_db.weekPlans)
          ..where((t) => t.weekStart.isBetweenValues(from.weekStart.iso, to.iso)))
        .watch()
        .map((rows) {
      final zero = <String>{};
      for (final p in rows) {
        final targets = p.targetsCsv.split(',').map(int.parse).toList();
        final start = LocalDate.parse(p.weekStart);
        for (var d = 0; d < 7; d++) {
          final day = start.addDays(d);
          if (targets[d] == 0 && !day.isBefore(from) && !day.isAfter(to)) {
            zero.add(day.iso);
          }
        }
      }
      return zero;
    });
    // True combineLatest — a new week_plans row (fresh target-0 day) must
    // propagate immediately, not wait for the next rest-flag change.
    return _combineLatest2(watchRestDays(from, to), zeroDays, (a, b) => {...a, ...b});
  }

  /// Minimal combineLatest for two streams (avoids an rxdart dependency).
  static Stream<T> _combineLatest2<A, B, T>(
      Stream<A> sa, Stream<B> sb, T Function(A a, B b) combine) {
    late StreamController<T> controller;
    A? lastA;
    B? lastB;
    var hasA = false, hasB = false;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;
    controller = StreamController<T>(
      onListen: () {
        subA = sa.listen((v) {
          lastA = v;
          hasA = true;
          if (hasB) controller.add(combine(lastA as A, lastB as B));
        }, onError: controller.addError);
        subB = sb.listen((v) {
          lastB = v;
          hasB = true;
          if (hasA) controller.add(combine(lastA as A, lastB as B));
        }, onError: controller.addError);
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return controller.stream;
  }

  // ---- week plans ----

  Future<WeekPlanData> ensureWeekPlan(LocalDate weekStart) async {
    final existing = await getWeekPlan(weekStart);
    if (existing != null) return existing;
    final s = await getSettings();
    final targets = distributeWeek(
        weeklyTarget: s.weeklyTarget, easyDay: s.easyDay, peakDay: s.peakDay,
        weekSeed: weekStart.epochDay ~/ 7);
    await _db.into(_db.weekPlans).insert(
        WeekPlansCompanion.insert(
            weekStart: weekStart.iso, weeklyTarget: s.weeklyTarget,
            targetsCsv: targets.join(','), easyDay: s.easyDay, peakDay: s.peakDay),
        mode: InsertMode.insertOrIgnore);
    return (await getWeekPlan(weekStart))!;
  }

  Future<WeekPlanData?> getWeekPlan(LocalDate weekStart) async {
    final row = await (_db.select(_db.weekPlans)
          ..where((t) => t.weekStart.equals(weekStart.iso)))
        .getSingleOrNull();
    return row == null ? null : _planFromRow(row);
  }

  /// Stored plans keyed by weekStart.iso, for weeks intersecting [from, to].
  Stream<Map<String, WeekPlanData>> watchWeekPlans(LocalDate from, LocalDate to) =>
      (_db.select(_db.weekPlans)
            ..where((t) => t.weekStart.isBetweenValues(from.weekStart.iso, to.iso)))
          .watch()
          .map((rows) => {for (final r in rows) r.weekStart: _planFromRow(r)});

  Stream<WeekPlanData?> watchWeekPlan(LocalDate weekStart) =>
      (_db.select(_db.weekPlans)..where((t) => t.weekStart.equals(weekStart.iso)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _planFromRow(row));

  WeekPlanData _planFromRow(WeekPlansData row) => WeekPlanData(
        weekStart: LocalDate.parse(row.weekStart),
        weeklyTarget: row.weeklyTarget,
        targets: row.targetsCsv.split(',').map(int.parse).toList(),
        easyDay: row.easyDay,
        peakDay: row.peakDay,
      );

  // ---- settings ----

  Future<AppSettings> getSettings() async =>
      AppSettings.fromKv({for (final r in await _db.select(_db.settingsKv).get()) r.key: r.value});

  Stream<AppSettings> watchSettings() => _db
      .select(_db.settingsKv)
      .watch()
      .map((rows) => AppSettings.fromKv({for (final r in rows) r.key: r.value}));

  Future<void> patchSettings(Map<String, String> kv) async {
    await _db.batch((b) {
      for (final e in kv.entries) {
        b.insert(_db.settingsKv, SettingsKvCompanion.insert(key: e.key, value: e.value),
            mode: InsertMode.insertOrReplace);
      }
    });
  }
}
