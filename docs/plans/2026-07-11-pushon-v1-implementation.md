# PushOn v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build PushOn v1 — a free, local-only Flutter Android app that logs push-up sets against an auto-distributed weekly target, with streaks, calendar, weekly summary, and best-effort reminder notifications — ready for Google Play.

**Architecture:** Pure-Dart domain layer (`lib/domain/`, zero Flutter imports) holds every product invariant, exhaustively unit-tested. A drift/SQLite data layer (`lib/data/`) persists sets/plans/flags/settings with sync-ready rows (UUIDs, soft deletes, timestamps) and exposes reactive streams. Four Riverpod-wired screens (`lib/ui/`) render those streams; go_router handles navigation and notification deep-links.

**Tech Stack:** Flutter (latest stable) + Dart 3, Material 3, flutter_riverpod, drift + drift_flutter, go_router, flutter_local_notifications + timezone, uuid, permission_handler (battery-exemption prompt only), flutter_lints. Dev: drift_dev, build_runner.

**Source spec (design of record):** `docs/specs/2026-07-11-pushon-v1-design.md`. When this plan and the spec disagree, the spec wins — flag the discrepancy instead of guessing.

## Global Constraints

- Repo root **is** the Flutter project: `C:\Claude\Projects\PushOn` (git repo `dudarenok-maker/pushon`, branch off `main` per CLAUDE.md).
- Android applicationId: `io.github.dudarenokmaker.pushon` — permanent, never change.
- App display name everywhere: **PushOn**. Tagline: **The push-up habit that sticks.**
- Palette (only these + neutrals): sunshine `#FFD23F`, ink `#1B2A4A`, coral `#FF5A36`, cream `#FFFDF4`. No other hex literals in UI code — import from `lib/ui/theme.dart`.
- All daily targets are multiples of 5, ≥ 0, summing exactly to the weekly target. Weekly target: any multiple of 5 (default **500**). Defaults: easy day **Tuesday**, peak day **Saturday**, waking window **08:00–21:00**, evening reminder **20:00**.
- Weeks start **Monday**. Day indexes are always `0=Mon … 6=Sun`.
- `lib/domain/` must have **zero** Flutter imports (`dart:` and package:collection-level only). Enforced by review, used by tests.
- Derived stats (day totals, best set, streak, on-track, summary) are computed, never stored.
- Local-only: no network calls anywhere in v1.
- Latest stable versions of all packages at execution time (`flutter pub add` fetches latest; do not copy versions from this plan's examples). Commit generated drift code; CI checks it's not stale.
- Every commit message: `<type>: <subject>` (types: feat|fix|refactor|test|docs|chore|build|ci).
- Run commands from the repo root. On this Windows box use PowerShell syntax where shown.

## File map (what exists when done)

```
lib/
  main.dart                    # bootstrap: DB, notifications init, ProviderScope
  app.dart                     # MaterialApp.router + theme
  router.dart                  # go_router: shell (/, /calendar, /summary) + /settings + /onboarding
  domain/
    dates.dart                 # LocalDate value type, week math
    distribution.dart          # round5 + distributeWeek (the algorithm)
    streak.dart                # computeStreak
    on_track.dart              # onTrackPerDay
    day_status.dart            # DayStatus enum + dayStatus()
    suggestion.dart            # WeekResult + raiseSuggestion
    notification_planner.dart  # PlannedNotification + planNotifications (pure)
  data/
    db.dart                    # drift tables + AppDatabase (+ db.g.dart generated)
    repository.dart            # PushOnRepository + SetEntry + AppSettings + WeekPlanData
    notification_scheduler.dart# thin wrapper over flutter_local_notifications
  state/
    providers.dart             # Riverpod graph: db, repo, clock, settings, today/calendar/summary view models
  ui/
    theme.dart                 # palette consts + ThemeData
    today_screen.dart          # ring, wheel, sets list, on-track, week strip, streak
    calendar_screen.dart       # month grid + day bottom sheet (catch-up, rest toggle)
    summary_screen.dart        # weekly summary + raise suggestion
    settings_screen.dart       # target wheel, rhythm days, notifications, about
    onboarding_screen.dart     # first-run: target + rhythm, writes current week plan
    widgets/
      progress_ring.dart
      wheel_log_sheet.dart     # shared wheel bottom-sheet (Today inline + catch-up reuse the picker)
      week_strip.dart
test/                          # mirrors lib/ (test/domain/..., test/data/..., test/ui/...)
assets/brand/                  # icon.svg (exists), icon-1024.png, icon-foreground-1024.png
scripts/build-release.mjs      # AAB build with timestamp versionCode
docs/privacy-policy.md
.github/workflows/ci.yml
```

---

### Task 1: Flutter scaffold, dependencies, CI

**Files:**
- Create: entire Flutter scaffold in repo root (`flutter create`), `pubspec.yaml` deps, `.github/workflows/ci.yml`
- Modify: `.gitignore` (flutter create appends; keep existing entries), `analysis_options.yaml` (default from scaffold is fine)
- Test: scaffold's `test/widget_test.dart` (replaced in Task 10; keep passing until then)

**Interfaces:**
- Consumes: nothing (first task).
- Produces: a building, testing Flutter project every later task lives in; CI that gates PRs.

- [ ] **Step 1: Scaffold into the existing repo**

```powershell
Set-Location C:\Claude\Projects\PushOn
flutter create --org io.github.dudarenokmaker --project-name pushon --platforms android,ios .
flutter --version   # record the exact Flutter/Dart version in the commit body
```

Expected: `All done!`. Existing README/CLAUDE.md/docs untouched.

- [ ] **Step 2: Add dependencies (latest stable, resolved now — not pinned from this doc)**

```powershell
flutter pub add flutter_riverpod drift drift_flutter go_router flutter_local_notifications timezone uuid permission_handler
flutter pub add --dev drift_dev build_runner
```

- [ ] **Step 3: Verify the scaffold is green**

```powershell
flutter analyze
flutter test
```

Expected: `No issues found!` and `All tests passed!` (the scaffold counter test).

- [ ] **Step 4: Add CI workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push: { branches: [main] }
  pull_request:
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: flutter pub get
      - name: Generated code is not stale
        run: |
          dart run build_runner build --delete-conflicting-outputs
          git diff --exit-code
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --debug
```

(The build_runner step is a no-op until Task 7 introduces drift; harmless before that.)

- [ ] **Step 5: Set the Android app label and applicationId sanity-check**

In `android/app/src/main/AndroidManifest.xml` set `android:label="PushOn"`. Confirm `android/app/build.gradle.kts` (or `.gradle`) has `applicationId = "io.github.dudarenokmaker.pushon"`.

- [ ] **Step 6: Commit**

```powershell
git add -A
git commit -m "build: scaffold Flutter app with deps and CI"
git push -u origin HEAD
```

---

### Task 2: Domain — `LocalDate`

**Files:**
- Create: `lib/domain/dates.dart`
- Test: `test/domain/dates_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `class LocalDate` with `LocalDate(int year, int month, int day)`, `LocalDate.from(DateTime)`, `addDays(int) → LocalDate`, `previous → LocalDate`, `weekdayIndex → int` (0=Mon), `weekStart → LocalDate`, `isBefore/isAfter(LocalDate) → bool`, `iso → String` ('YYYY-MM-DD'), `static parse(String) → LocalDate`, value equality, `compareTo`. Every later task uses this for all date math — **never** raw `DateTime` for day identity.

- [ ] **Step 1: Write the failing test**

`test/domain/dates_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';

void main() {
  test('value equality and iso round-trip', () {
    const d = LocalDate(2026, 7, 11);
    expect(d, const LocalDate(2026, 7, 11));
    expect(d.iso, '2026-07-11');
    expect(LocalDate.parse('2026-07-11'), d);
  });

  test('addDays rolls months and years', () {
    expect(const LocalDate(2026, 12, 31).addDays(1), const LocalDate(2027, 1, 1));
    expect(const LocalDate(2026, 3, 1).addDays(-1), const LocalDate(2026, 2, 28));
  });

  test('addDays is DST-safe (date component math, never wall-clock)', () {
    // 2026-10-04 is an AEDT DST-start Sunday in Australia; component math must not skip/repeat a day.
    expect(const LocalDate(2026, 10, 3).addDays(1), const LocalDate(2026, 10, 4));
    expect(const LocalDate(2026, 10, 4).addDays(1), const LocalDate(2026, 10, 5));
  });

  test('weekStart is Monday, weekdayIndex 0=Mon..6=Sun', () {
    const sat = LocalDate(2026, 7, 11); // Saturday
    expect(sat.weekdayIndex, 5);
    expect(sat.weekStart, const LocalDate(2026, 7, 6)); // Monday
    expect(const LocalDate(2026, 7, 6).weekStart, const LocalDate(2026, 7, 6));
  });

  test('ordering', () {
    expect(const LocalDate(2026, 7, 10).isBefore(const LocalDate(2026, 7, 11)), isTrue);
    expect(const LocalDate(2026, 7, 12).isAfter(const LocalDate(2026, 7, 11)), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/dates_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'pushon/domain/dates.dart'` (or type not found).

- [ ] **Step 3: Implement**

`lib/domain/dates.dart`:

```dart
/// Calendar-day value type. All day identity in PushOn uses this,
/// never DateTime, so timezones and DST can't shift a day.
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.from(DateTime dt) => LocalDate(dt.year, dt.month, dt.day);

  factory LocalDate.parse(String iso) {
    final p = iso.split('-');
    return LocalDate(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  final int year;
  final int month;
  final int day;

  /// Component arithmetic via the DateTime constructor normalises
  /// month/year rolls without touching wall-clock time (DST-safe).
  LocalDate addDays(int n) {
    final d = DateTime(year, month, day + n);
    return LocalDate(d.year, d.month, d.day);
  }

  LocalDate get previous => addDays(-1);

  /// 0 = Monday … 6 = Sunday.
  int get weekdayIndex => DateTime(year, month, day).weekday - 1;

  LocalDate get weekStart => addDays(-weekdayIndex);

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  String get iso =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  int get _ordinal => year * 10000 + month * 100 + day;

  @override
  int compareTo(LocalDate other) => _ordinal - other._ordinal;

  @override
  bool operator ==(Object other) => other is LocalDate && other._ordinal == _ordinal;

  @override
  int get hashCode => _ordinal;

  @override
  String toString() => iso;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/dates_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```powershell
git add lib/domain/dates.dart test/domain/dates_test.dart
git commit -m "feat: add LocalDate domain value type"
```

---

### Task 3: Domain — distribution algorithm

**Files:**
- Create: `lib/domain/distribution.dart`
- Test: `test/domain/distribution_test.dart`

**Interfaces:**
- Consumes: nothing (pure ints).
- Produces: `int round5(num x)`; `List<int> distributeWeek({required int weeklyTarget, required int easyDay, required int peakDay})` returning 7 targets indexed 0=Mon..6=Sun. Throws `ArgumentError` when `weeklyTarget` is negative or not a multiple of 5, or `easyDay == peakDay`.

- [ ] **Step 1: Write the failing test**

`test/domain/distribution_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/distribution.dart';

void main() {
  test('round5 rounds to nearest 5, ties up', () {
    expect(round5(87), 85);
    expect(round5(88), 90);
    expect(round5(42), 40);
    expect(round5(42.5), 45);
    expect(round5(0), 0);
  });

  test('canonical spec fixture: W=500, easy Tue(1), peak Sat(5)', () {
    expect(
      distributeWeek(weeklyTarget: 500, easyDay: 1, peakDay: 5),
      [70, 40, 70, 75, 75, 100, 70], // Mon..Sun — MUST match the spec example
    );
  });

  test('hard invariants hold across the whole input space', () {
    for (var w = 0; w <= 2000; w += 5) {
      for (var easy = 0; easy < 7; easy++) {
        for (var peak = 0; peak < 7; peak++) {
          if (easy == peak) continue;
          final t = distributeWeek(weeklyTarget: w, easyDay: easy, peakDay: peak);
          expect(t.length, 7);
          expect(t.reduce((a, b) => a + b), w, reason: 'sum W=$w e=$easy p=$peak');
          for (final v in t) {
            expect(v >= 0, isTrue);
            expect(v % 5, 0);
          }
        }
      }
    }
  });

  test('soft goals hold for a comfortable target: peak is max, easy is min', () {
    final t = distributeWeek(weeklyTarget: 500, easyDay: 1, peakDay: 5);
    expect(t[5], t.reduce((a, b) => a > b ? a : b));
    expect(t[1], t.reduce((a, b) => a < b ? a : b));
  });

  test('tiny target: W=30 drops a day to 0 and still sums', () {
    final t = distributeWeek(weeklyTarget: 30, easyDay: 1, peakDay: 5);
    expect(t.reduce((a, b) => a + b), 30);
    expect(t.contains(0), isTrue);
  });

  test('peak on Monday: leftover wraps without crashing', () {
    final t = distributeWeek(weeklyTarget: 500, easyDay: 2, peakDay: 0);
    expect(t.reduce((a, b) => a + b), 500);
  });

  test('invalid input throws', () {
    expect(() => distributeWeek(weeklyTarget: 87, easyDay: 1, peakDay: 5), throwsArgumentError);
    expect(() => distributeWeek(weeklyTarget: -5, easyDay: 1, peakDay: 5), throwsArgumentError);
    expect(() => distributeWeek(weeklyTarget: 500, easyDay: 3, peakDay: 3), throwsArgumentError);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/distribution_test.dart`
Expected: FAIL — package path not found.

- [ ] **Step 3: Implement**

`lib/domain/distribution.dart`:

```dart
/// Nearest multiple of 5; ties round up (Dart's round() is half-away-from-zero).
int round5(num x) => 5 * (x / 5).round();

/// Distributes [weeklyTarget] across the 7 days (0=Mon..6=Sun).
///
/// Spec: docs/specs/2026-07-11-pushon-v1-design.md "The distribution
/// algorithm". Hard invariant: multiples of 5, >= 0, sum == weeklyTarget.
List<int> distributeWeek({
  required int weeklyTarget,
  required int easyDay,
  required int peakDay,
}) {
  if (weeklyTarget < 0 || weeklyTarget % 5 != 0) {
    throw ArgumentError.value(weeklyTarget, 'weeklyTarget', 'must be a non-negative multiple of 5');
  }
  if (easyDay == peakDay) {
    throw ArgumentError('easyDay and peakDay must differ');
  }

  final base = round5(weeklyTarget / 7);
  final targets = List<int>.filled(7, 0);
  targets[easyDay] = round5(0.6 * base);
  targets[peakDay] = round5(1.4 * base);

  // The five normal days, ordered by proximity BEFORE the peak day,
  // wrapping past the week start to the days after it.
  final normal = <int>[];
  for (var k = 1; k <= 6; k++) {
    final d = (peakDay - k) % 7; // Dart % is non-negative for positive divisor
    if (d != easyDay) normal.add(d);
  }

  final per = round5((weeklyTarget - targets[easyDay] - targets[peakDay]) / 5);
  for (final d in normal) {
    targets[d] = per > 0 ? per : 0;
  }

  // Adjustment pass: +5 in `normal` order while short; -5 in reverse order
  // (then peak, then easy) while over, skipping days already at 0.
  var diff = weeklyTarget - targets.reduce((a, b) => a + b);
  var i = 0;
  while (diff > 0) {
    targets[normal[i % normal.length]] += 5;
    diff -= 5;
    i++;
  }
  final drain = [...normal.reversed, peakDay, easyDay];
  i = 0;
  while (diff < 0) {
    final d = drain[i % drain.length];
    if (targets[d] >= 5) {
      targets[d] -= 5;
      diff += 5;
    }
    i++;
  }
  return targets;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/distribution_test.dart`
Expected: PASS (7 tests; the exhaustive one covers 16,842 combinations).

- [ ] **Step 5: Commit**

```powershell
git add lib/domain/distribution.dart test/domain/distribution_test.dart
git commit -m "feat: add weekly distribution algorithm with hard invariants"
```

---

### Task 4: Domain — streak

**Files:**
- Create: `lib/domain/streak.dart`
- Test: `test/domain/streak_test.dart`

**Interfaces:**
- Consumes: `LocalDate` (Task 2).
- Produces: `int computeStreak({required LocalDate today, required LocalDate installDate, required Set<LocalDate> loggedDays, required Set<LocalDate> transparentDays})`. `loggedDays` = days with ≥1 non-deleted set; `transparentDays` = rest-flagged days + target-0 days (callers build these sets; pre-install days are handled by the `installDate` bound).

- [ ] **Step 1: Write the failing test**

`test/domain/streak_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'package:pushon/domain/streak.dart';

void main() {
  const install = LocalDate(2026, 1, 1);
  const today = LocalDate(2026, 7, 11);
  LocalDate d(int daysAgo) => today.addDays(-daysAgo);

  test('unlogged today is pending, not a break', () {
    expect(
      computeStreak(today: today, installDate: install,
        loggedDays: {d(1), d(2), d(3)}, transparentDays: {}),
      3,
    );
  });

  test('logged today extends the streak', () {
    expect(
      computeStreak(today: today, installDate: install,
        loggedDays: {today, d(1), d(2)}, transparentDays: {}),
      3,
    );
  });

  test('rest day mid-gap is transparent — bridges, does not count', () {
    expect(
      computeStreak(today: today, installDate: install,
        loggedDays: {d(1), d(3)}, transparentDays: {d(2)}),
      2,
    );
  });

  test('a plain missed day breaks it', () {
    expect(
      computeStreak(today: today, installDate: install,
        loggedDays: {d(1), d(3)}, transparentDays: {}),
      1,
    );
  });

  test('catch-up heal: adding an old day retroactively restores the run', () {
    final without = computeStreak(today: today, installDate: install,
        loggedDays: {d(1), d(3), d(4)}, transparentDays: {});
    final with_ = computeStreak(today: today, installDate: install,
        loggedDays: {d(1), d(2), d(3), d(4)}, transparentDays: {});
    expect(without, 1);
    expect(with_, 4);
  });

  test('walk stops at installDate (pre-install days neither count nor break)', () {
    const installed = LocalDate(2026, 7, 9);
    expect(
      computeStreak(today: today, installDate: installed,
        loggedDays: {d(1), d(2)}, transparentDays: {}),
      2, // d(2) == installDate; the walk must not run past it
    );
  });

  test('zero when nothing logged and yesterday missed', () {
    expect(
      computeStreak(today: today, installDate: install,
        loggedDays: {}, transparentDays: {}),
      0,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/streak_test.dart`
Expected: FAIL — package path not found.

- [ ] **Step 3: Implement**

`lib/domain/streak.dart`:

```dart
import 'dates.dart';

/// Consecutive-day streak per the spec's testable definition:
/// - an unlogged *today* is pending (doesn't break, doesn't count);
/// - transparent days (rest / target-0) are skipped, never breaking;
/// - the walk never crosses [installDate] (pre-install days are neutral);
/// - derived entirely from inputs, so catch-up logging heals retroactively.
int computeStreak({
  required LocalDate today,
  required LocalDate installDate,
  required Set<LocalDate> loggedDays,
  required Set<LocalDate> transparentDays,
}) {
  var streak = 0;
  if (loggedDays.contains(today)) streak++;
  var day = today.previous;
  while (!day.isBefore(installDate)) {
    if (loggedDays.contains(day)) {
      streak++;
    } else if (!transparentDays.contains(day)) {
      break;
    }
    day = day.previous;
  }
  return streak;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/streak_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```powershell
git add lib/domain/streak.dart test/domain/streak_test.dart
git commit -m "feat: add streak computation with pause-not-break semantics"
```

---

### Task 5: Domain — on-track line + calendar day states

**Files:**
- Create: `lib/domain/on_track.dart`, `lib/domain/day_status.dart`
- Test: `test/domain/on_track_test.dart`, `test/domain/day_status_test.dart`

**Interfaces:**
- Consumes: `LocalDate`.
- Produces:
  - `int? onTrackPerDay({required int weeklyTarget, required List<int> targets, required int loggedThisWeek, required Set<int> restDayIndexes, required int todayIndex})` — reps/day to stay on track; `0` when the week is already met; `null` when the line must be hidden (no remaining non-rest days).
  - `enum DayStatus { hit, partial, missed, rest, pending, future, preInstall }` and `DayStatus dayStatus({required LocalDate date, required LocalDate today, required LocalDate installDate, required int logged, required int target, required bool rest})`.

- [ ] **Step 1: Write the failing tests**

`test/domain/on_track_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/on_track.dart';

void main() {
  const targets = [70, 40, 70, 75, 75, 100, 70]; // canonical W=500 fixture

  test('midweek behind: ceil of remaining over remaining non-rest days', () {
    // Thursday (index 3), 180 logged, no rest days: (500-180)/4 days = 80.
    expect(
      onTrackPerDay(weeklyTarget: 500, targets: targets, loggedThisWeek: 180,
        restDayIndexes: {}, todayIndex: 3),
      80,
    );
  });

  test('flagging a rest day can never raise the number', () {
    final before = onTrackPerDay(weeklyTarget: 500, targets: targets,
        loggedThisWeek: 180, restDayIndexes: {}, todayIndex: 3)!;
    final after = onTrackPerDay(weeklyTarget: 500, targets: targets,
        loggedThisWeek: 180, restDayIndexes: {4}, todayIndex: 3)!;
    expect(after <= before, isTrue, reason: 'rest flag must not inflate ($before -> $after)');
    // Fri(75) rest: (500-180-75)/3 remaining days (Thu,Sat,Sun) = 81.67 -> 82.
    expect(after, 82);
  });

  test('already met: 0', () {
    expect(
      onTrackPerDay(weeklyTarget: 500, targets: targets, loggedThisWeek: 505,
        restDayIndexes: {}, todayIndex: 6),
      0,
    );
  });

  test('hidden when every remaining day is rest or target-0', () {
    expect(
      onTrackPerDay(weeklyTarget: 500, targets: targets, loggedThisWeek: 100,
        restDayIndexes: {6}, todayIndex: 6),
      isNull,
    );
  });
}
```

`test/domain/day_status_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'package:pushon/domain/day_status.dart';

void main() {
  const install = LocalDate(2026, 7, 1);
  const today = LocalDate(2026, 7, 11);
  DayStatus s(LocalDate date, {int logged = 0, int target = 70, bool rest = false}) =>
      dayStatus(date: date, today: today, installDate: install,
          logged: logged, target: target, rest: rest);

  test('the eight rules', () {
    expect(s(const LocalDate(2026, 6, 20)), DayStatus.preInstall);
    expect(s(const LocalDate(2026, 7, 5), rest: true, logged: 999), DayStatus.rest); // grey regardless
    expect(s(const LocalDate(2026, 7, 5), target: 0), DayStatus.rest);               // target-0 == rest
    expect(s(const LocalDate(2026, 7, 5), logged: 70), DayStatus.hit);
    expect(s(const LocalDate(2026, 7, 5), logged: 30), DayStatus.partial);
    expect(s(const LocalDate(2026, 7, 5)), DayStatus.missed);
    expect(s(today, logged: 30), DayStatus.pending);   // today pending until hit
    expect(s(today, logged: 70), DayStatus.hit);
    expect(s(const LocalDate(2026, 7, 12)), DayStatus.future);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/domain/on_track_test.dart test/domain/day_status_test.dart`
Expected: FAIL — package paths not found.

- [ ] **Step 3: Implement**

`lib/domain/on_track.dart`:

```dart
/// "To stay on track: X/day" — informational only, never a target.
///
/// X = max(0, W - logged - sum(targets of rest-flagged days)) / remaining
/// non-rest, non-zero-target days (today included). Null = hide the line.
int? onTrackPerDay({
  required int weeklyTarget,
  required List<int> targets,
  required int loggedThisWeek,
  required Set<int> restDayIndexes,
  required int todayIndex,
}) {
  var restTargets = 0;
  for (final d in restDayIndexes) {
    restTargets += targets[d];
  }
  var remainingDays = 0;
  for (var d = todayIndex; d < 7; d++) {
    if (!restDayIndexes.contains(d) && targets[d] > 0) remainingDays++;
  }
  if (remainingDays == 0) return null;
  final remaining = weeklyTarget - loggedThisWeek - restTargets;
  if (remaining <= 0) return 0;
  return (remaining / remainingDays).ceil();
}
```

`lib/domain/day_status.dart`:

```dart
import 'dates.dart';

enum DayStatus { hit, partial, missed, rest, pending, future, preInstall }

/// Calendar day state per the spec's "Calendar day states" table.
/// Precedence: preInstall > rest (incl. target-0) > future > hit > pending(today) > partial > missed.
DayStatus dayStatus({
  required LocalDate date,
  required LocalDate today,
  required LocalDate installDate,
  required int logged,
  required int target,
  required bool rest,
}) {
  if (date.isBefore(installDate)) return DayStatus.preInstall;
  if (rest || target == 0) return DayStatus.rest;
  if (date.isAfter(today)) return DayStatus.future;
  if (logged >= target) return DayStatus.hit;
  if (date == today) return DayStatus.pending;
  if (logged > 0) return DayStatus.partial;
  return DayStatus.missed;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/domain/on_track_test.dart test/domain/day_status_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/domain/on_track.dart lib/domain/day_status.dart test/domain/on_track_test.dart test/domain/day_status_test.dart
git commit -m "feat: add on-track line and calendar day-state derivations"
```

---

### Task 6: Domain — raise suggestion

**Files:**
- Create: `lib/domain/suggestion.dart`
- Test: `test/domain/suggestion_test.dart`

**Interfaces:**
- Consumes: nothing (pure ints).
- Produces: `class WeekResult { const WeekResult({required int target, required int logged}); }` and `int? raiseSuggestion({required List<WeekResult> lastThreeCompleted, required int currentTarget})` — the suggested new weekly target, or null when no suggestion should show. Order of `lastThreeCompleted` doesn't matter.

- [ ] **Step 1: Write the failing test**

`test/domain/suggestion_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/suggestion_test.dart`
Expected: FAIL — package path not found.

- [ ] **Step 3: Implement**

`lib/domain/suggestion.dart`:

```dart
class WeekResult {
  const WeekResult({required this.target, required this.logged});
  final int target;
  final int logged;
}

/// Upward-only target suggestion: shown only when the last 3 completed
/// weeks all hit target AND averaged >= 110% of it. Suggests the 3-week
/// average of logged reps rounded DOWN to a multiple of 5; null when that
/// wouldn't be an increase.
int? raiseSuggestion({
  required List<WeekResult> lastThreeCompleted,
  required int currentTarget,
}) {
  if (lastThreeCompleted.length < 3) return null;
  for (final w in lastThreeCompleted) {
    if (w.target <= 0 || w.logged < w.target) return null;
  }
  final avgRatio = lastThreeCompleted
          .map((w) => w.logged / w.target)
          .reduce((a, b) => a + b) /
      lastThreeCompleted.length;
  if (avgRatio < 1.10) return null;
  final avgLogged = lastThreeCompleted
          .map((w) => w.logged)
          .reduce((a, b) => a + b) /
      lastThreeCompleted.length;
  final suggested = (avgLogged / 5).floor() * 5;
  return suggested > currentTarget ? suggested : null;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/suggestion_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```powershell
git add lib/domain/suggestion.dart test/domain/suggestion_test.dart
git commit -m "feat: add upward-only weekly target suggestion rule"
```

### Task 7: Data — drift schema + database

**Files:**
- Create: `lib/data/db.dart` (+ generated `lib/data/db.g.dart`, committed)
- Test: `test/data/db_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `class AppDatabase extends _$AppDatabase { AppDatabase(QueryExecutor e); }` with tables `Sets` (id TEXT pk, date TEXT iso, count INT, createdAt/updatedAt DATETIME, deletedAt DATETIME nullable), `WeekPlans` (weekStart TEXT pk, weeklyTarget INT, targetsCsv TEXT, easyDay INT, peakDay INT), `DayFlags` (date TEXT pk, rest BOOL default false), `SettingsKv` (key TEXT pk, value TEXT). Drift generates row classes `Set`→`SetsData` etc. — later tasks use the repository, not these, except the repository itself.

- [ ] **Step 1: Write the failing test**

`test/data/db_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/data/db.dart';

void main() {
  test('schema opens and round-trips a set row', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.sets).insert(SetsCompanion.insert(
      id: 'a-1', date: '2026-07-11', count: 25,
      createdAt: DateTime(2026, 7, 11, 9), updatedAt: DateTime(2026, 7, 11, 9),
    ));
    final rows = await db.select(db.sets).get();
    expect(rows.single.count, 25);
    expect(rows.single.deletedAt, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/db_test.dart`
Expected: FAIL — `db.dart` missing.

> **Windows note:** in-memory drift tests need a loadable sqlite3. If the run
> fails with "sqlite3.dll not found": `scoop install sqlite` (or place
> sqlite3.dll on PATH). CI's ubuntu-latest has libsqlite3 already.

- [ ] **Step 3: Implement**

`lib/data/db.dart`:

```dart
import 'package:drift/drift.dart';

part 'db.g.dart';

class Sets extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()(); // LocalDate.iso — the day the set counts toward
  IntColumn get count => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete
  @override
  Set<Column> get primaryKey => {id};
}

class WeekPlans extends Table {
  TextColumn get weekStart => text()(); // Monday, LocalDate.iso
  IntColumn get weeklyTarget => integer()();
  TextColumn get targetsCsv => text()(); // e.g. '70,40,70,75,75,100,70' Mon..Sun
  IntColumn get easyDay => integer()();
  IntColumn get peakDay => integer()();
  @override
  Set<Column> get primaryKey => {weekStart};
}

class DayFlags extends Table {
  TextColumn get date => text()();
  BoolColumn get rest => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {date};
}

class SettingsKv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Sets, WeekPlans, DayFlags, SettingsKv])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
```

Generate: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/db_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit (including generated code)**

```powershell
git add lib/data/db.dart lib/data/db.g.dart test/data/db_test.dart
git commit -m "feat: add drift schema for sets, week plans, day flags, settings"
```

---

### Task 8: Data — repository

**Files:**
- Create: `lib/data/repository.dart`
- Test: `test/data/repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` (Task 7), `LocalDate` (2), `distributeWeek` (3).
- Produces (exact signatures — UI/state tasks depend on these):

```dart
class SetEntry { final String id; final LocalDate date; final int count; final DateTime createdAt; }

class WeekPlanData {
  final LocalDate weekStart; final int weeklyTarget;
  final List<int> targets; final int easyDay; final int peakDay;
}

class AppSettings {
  final int weeklyTarget;            // default 500
  final int easyDay;                 // default 1 (Tue)
  final int peakDay;                 // default 5 (Sat)
  final int wakingStartMinutes;      // default 480 (08:00)
  final int wakingEndMinutes;        // default 1260 (21:00)
  final bool nudgeEnabled;           // default true
  final bool reminderEnabled;        // default true
  final LocalDate? installDate;      // null until onboarding completes
  final LocalDate? lastSummaryShownWeek;
  final bool batteryPromptShown;     // default false
}

class PushOnRepository {
  PushOnRepository(AppDatabase db, {String Function()? newId}); // newId defaults to uuid v4
  Future<void> logSet({required LocalDate date, required int count, required DateTime now});
  Future<void> editSet({required String id, required int count, required DateTime now});
  Future<void> deleteSet({required String id, required DateTime now}); // soft
  Stream<List<SetEntry>> watchSetsForDay(LocalDate date);              // non-deleted, by createdAt
  Stream<Map<String, int>> watchDayTotals(LocalDate from, LocalDate to);   // iso -> sum, non-deleted
  Stream<Set<String>> watchLoggedDays(LocalDate from, LocalDate to);       // iso days with >=1 set
  Future<void> setRest(LocalDate date, bool rest);
  Stream<Set<String>> watchRestDays(LocalDate from, LocalDate to);         // iso
  Stream<Set<String>> watchTransparentDays(LocalDate from, LocalDate to);  // rest ∪ target-0 (from stored plans)
  Future<WeekPlanData> ensureWeekPlan(LocalDate weekStart);  // touch semantics: insert-if-absent from current settings
  Stream<WeekPlanData?> watchWeekPlan(LocalDate weekStart);
  Future<WeekPlanData?> getWeekPlan(LocalDate weekStart);
  Future<AppSettings> getSettings();
  Stream<AppSettings> watchSettings();
  Future<void> patchSettings(Map<String, String> kv); // keys below
}

// SettingsKv keys (string constants in repository.dart):
// 'weeklyTarget','easyDay','peakDay','wakingStartMinutes','wakingEndMinutes',
// 'nudgeEnabled','reminderEnabled','installDate','lastSummaryShownWeek','batteryPromptShown'
// bools serialize as 'true'/'false'; dates as LocalDate.iso; ints as toString.
```

- [ ] **Step 1: Write the failing test**

`test/data/repository_test.dart`:

```dart
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/repository_test.dart`
Expected: FAIL — `repository.dart` missing.

- [ ] **Step 3: Implement**

`lib/data/repository.dart`:

```dart
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
      (_liveSets(date, date)..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
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
    final plans = (_db.select(_db.weekPlans)
          ..where((t) => t.weekStart.isBetweenValues(from.weekStart.iso, to.iso)))
        .watch()
        .map((rows) {
      final zero = <String>{};
      for (final p in rows) {
        final targets = p.targetsCsv.split(',').map(int.parse).toList();
        final start = LocalDate.parse(p.weekStart);
        for (var d = 0; d < 7; d++) {
          if (targets[d] == 0) zero.add(start.addDays(d).iso);
        }
      }
      return zero;
    });
    return watchRestDays(from, to).asyncMap((rest) async {
      final zero = await plans.first;
      return {...rest, ...zero.where((d) {
        final ld = LocalDate.parse(d);
        return !ld.isBefore(from) && !ld.isAfter(to);
      })};
    });
  }

  // ---- week plans ----

  Future<WeekPlanData> ensureWeekPlan(LocalDate weekStart) async {
    final existing = await getWeekPlan(weekStart);
    if (existing != null) return existing;
    final s = await getSettings();
    final targets = distributeWeek(
        weeklyTarget: s.weeklyTarget, easyDay: s.easyDay, peakDay: s.peakDay);
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/repository_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```powershell
git add lib/data/repository.dart test/data/repository_test.dart
git commit -m "feat: add repository with sync-ready CRUD, plans, settings"
```

---

### Task 9: Notification planner (pure) + scheduler wrapper

**Files:**
- Create: `lib/domain/notification_planner.dart`, `lib/data/notification_scheduler.dart`
- Test: `test/domain/notification_planner_test.dart`

**Interfaces:**
- Consumes: nothing (planner is pure).
- Produces:
  - `enum PlannedKind { inactivityNudge, eveningReminder }`; `class PlannedNotification { final PlannedKind kind; final DateTime fireAt; final String title; final String body; }`
  - `List<PlannedNotification> planNotifications({required DateTime now, required int remainingToday, required bool restOrZeroTarget, required DateTime? lastSetAt, required DateTime firstOpenToday, required int wakingStartMinutes, required int wakingEndMinutes, required bool nudgeEnabled, required bool reminderEnabled})`
  - `class NotificationScheduler { Future<void> init({required void Function() onTap}); Future<void> requestPermission(); Future<void> applyPlan(List<PlannedNotification> plan); }` — wraps `FlutterLocalNotificationsPlugin`, `AndroidScheduleMode.inexactAllowWhileIdle`, cancels-then-schedules. `requestPermission` is invoked from onboarding (Task 15), not `init`. Task 16 injects a fake with the same shape.

- [ ] **Step 1: Write the failing test**

`test/domain/notification_planner_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/notification_planner.dart';

void main() {
  final nineAm = DateTime(2026, 7, 11, 9);
  List<PlannedNotification> plan({
    DateTime? now, int remaining = 50, bool rest = false, DateTime? lastSetAt,
    DateTime? firstOpen, bool nudge = true, bool reminder = true,
  }) =>
      planNotifications(
        now: now ?? nineAm, remainingToday: remaining, restOrZeroTarget: rest,
        lastSetAt: lastSetAt, firstOpenToday: firstOpen ?? nineAm.subtract(const Duration(hours: 1)),
        wakingStartMinutes: 480, wakingEndMinutes: 1260,
        nudgeEnabled: nudge, reminderEnabled: reminder,
      );

  test('rest day or met target: nothing at all', () {
    expect(plan(rest: true), isEmpty);
    expect(plan(remaining: 0), isEmpty);
  });

  test('nudge fires 4h after last set, reminder at 20:00, bodies carry the count', () {
    final p = plan(lastSetAt: nineAm);
    expect(p, hasLength(2));
    final nudge = p.singleWhere((n) => n.kind == PlannedKind.inactivityNudge);
    expect(nudge.fireAt, DateTime(2026, 7, 11, 13));
    expect(nudge.body, contains('50'));
    final reminder = p.singleWhere((n) => n.kind == PlannedKind.eveningReminder);
    expect(reminder.fireAt, DateTime(2026, 7, 11, 20));
    expect(reminder.body, contains('50'));
  });

  test('no set yet: nudge anchors to first open of the day', () {
    final p = plan(lastSetAt: null, firstOpen: nineAm);
    expect(p.singleWhere((n) => n.kind == PlannedKind.inactivityNudge).fireAt,
        DateTime(2026, 7, 11, 13));
  });

  test('nudge clamps to waking start, drops past waking end', () {
    final early = plan(now: DateTime(2026, 7, 11, 5), firstOpen: DateTime(2026, 7, 11, 3));
    expect(early.singleWhere((n) => n.kind == PlannedKind.inactivityNudge).fireAt,
        DateTime(2026, 7, 11, 8));
    final late_ = plan(now: DateTime(2026, 7, 11, 18, 30), lastSetAt: DateTime(2026, 7, 11, 18));
    expect(late_.where((n) => n.kind == PlannedKind.inactivityNudge), isEmpty); // 22:00 > 21:00
  });

  test('reminder dropped once 20:00 has passed', () {
    final p = plan(now: DateTime(2026, 7, 11, 20, 30), lastSetAt: DateTime(2026, 7, 11, 20, 15));
    expect(p.where((n) => n.kind == PlannedKind.eveningReminder), isEmpty);
  });

  test('toggles disable each kind independently', () {
    expect(plan(nudge: false).map((n) => n.kind), [PlannedKind.eveningReminder]);
    expect(plan(reminder: false).map((n) => n.kind), [PlannedKind.inactivityNudge]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/notification_planner_test.dart`
Expected: FAIL — package path not found.

- [ ] **Step 3: Implement**

`lib/domain/notification_planner.dart`:

```dart
enum PlannedKind { inactivityNudge, eveningReminder }

class PlannedNotification {
  const PlannedNotification({required this.kind, required this.fireAt, required this.title, required this.body});
  final PlannedKind kind;
  final DateTime fireAt;
  final String title;
  final String body;
}

/// Pure notification plan for the rest of *today*. Recomputed on every app
/// open and every log; the scheduler applies it (cancel-all, then schedule).
/// Best-effort by design — see the spec's "Reliability posture".
List<PlannedNotification> planNotifications({
  required DateTime now,
  required int remainingToday,
  required bool restOrZeroTarget,
  required DateTime? lastSetAt,
  required DateTime firstOpenToday,
  required int wakingStartMinutes,
  required int wakingEndMinutes,
  required bool nudgeEnabled,
  required bool reminderEnabled,
}) {
  if (remainingToday <= 0 || restOrZeroTarget) return const [];
  final out = <PlannedNotification>[];
  final dayStart = DateTime(now.year, now.month, now.day);

  if (nudgeEnabled) {
    var fire = (lastSetAt ?? firstOpenToday).add(const Duration(hours: 4));
    final wakeStart = dayStart.add(Duration(minutes: wakingStartMinutes));
    final wakeEnd = dayStart.add(Duration(minutes: wakingEndMinutes));
    if (fire.isBefore(wakeStart)) fire = wakeStart;
    if (fire.isAfter(now) && !fire.isAfter(wakeEnd)) {
      out.add(PlannedNotification(
        kind: PlannedKind.inactivityNudge,
        fireAt: fire,
        title: 'Time for a set?',
        body: '$remainingToday reps to go today.',
      ));
    }
  }

  if (reminderEnabled) {
    final eightPm = dayStart.add(const Duration(hours: 20));
    if (now.isBefore(eightPm)) {
      out.add(PlannedNotification(
        kind: PlannedKind.eveningReminder,
        fireAt: eightPm,
        title: "Today's push-ups",
        body: '$remainingToday to go — a couple of quick sets.',
      ));
    }
  }
  return out;
}
```

`lib/data/notification_scheduler.dart`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_planner.dart';

/// Thin wrapper over flutter_local_notifications so the rest of the app
/// (and tests, via a fake) only ever sees `applyPlan`.
class NotificationScheduler {
  NotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'pushon_reminders', 'Reminders',
      channelDescription: 'Daily push-up nudges and the evening reminder',
      importance: Importance.defaultImportance,
    ),
  );

  Future<void> init({required void Function() onTap}) async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (_) => onTap(),
    );
  }

  /// Android 13+ runtime permission. Called from onboarding (after the
  /// explainer copy), NOT at init — the spec wants the ask on first run
  /// with context, not a cold system dialog at boot.
  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> applyPlan(List<PlannedNotification> plan) async {
    await _plugin.cancelAll();
    for (final n in plan) {
      await _plugin.zonedSchedule(
        n.kind.index, n.title, n.body,
        tz.TZDateTime.from(n.fireAt, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/notification_planner_test.dart`
Expected: PASS (6 tests). Also run `flutter analyze` — the scheduler wrapper has no test (plugin-bound); analyzer must be clean.

- [ ] **Step 5: Commit**

```powershell
git add lib/domain/notification_planner.dart lib/data/notification_scheduler.dart test/domain/notification_planner_test.dart
git commit -m "feat: add pure notification planner and scheduler wrapper"
```

---

### Task 10: Bootstrap — theme, providers, router, app shell

**Files:**
- Create: `lib/ui/theme.dart`, `lib/state/providers.dart`, `lib/router.dart`, `lib/app.dart`
- Modify: `lib/main.dart` (replace scaffold counter app)
- Create placeholders that Tasks 11–15 will replace: `lib/ui/today_screen.dart`, `lib/ui/calendar_screen.dart`, `lib/ui/summary_screen.dart`, `lib/ui/settings_screen.dart`, `lib/ui/onboarding_screen.dart` (each a `Scaffold` with the screen name; replaced by real code in their own task)
- Test: `test/ui/harness.dart`, `test/ui/app_boot_test.dart` (replaces scaffold `test/widget_test.dart` — delete it)

**Interfaces:**
- Consumes: everything above.
- Produces (later UI tasks build on these exact names):

```dart
// theme.dart
const kSunshine = Color(0xFFFFD23F); const kInk = Color(0xFF1B2A4A);
const kCoral = Color(0xFFFF5A36);   const kCream = Color(0xFFFFFDF4);
ThemeData buildTheme();

// providers.dart
final databaseProvider = Provider<AppDatabase>(...);        // MUST be overridden (main + tests)
final repositoryProvider = Provider<PushOnRepository>(...);
final clockProvider = Provider<DateTime Function()>(...);   // override in tests for a fixed now
final schedulerProvider = Provider<NotificationScheduler?>(...); // null default (tests); real in main
final settingsProvider = StreamProvider<AppSettings>(...);
final todayProvider = Provider<LocalDate>(...);             // LocalDate.from(clock())
final weekPlanProvider = FutureProvider<WeekPlanData>(...); // ensureWeekPlan(today.weekStart)
final weekTotalsProvider = StreamProvider<Map<String, int>>(...); // current week
final weekRestDaysProvider = StreamProvider<Set<String>>(...);    // current week
final daySetsProvider = StreamProvider.family<List<SetEntry>, LocalDate>(...);
final streakProvider = StreamProvider<int>(...);            // combines logged+transparent since install

// router.dart
GoRouter buildRouter();   // '/', '/calendar', '/summary' in an indexed-stack shell + '/settings'

// app.dart
class PushOnApp extends ConsumerWidget; // settings gate: loading → splash; installDate==null → OnboardingScreen; else MaterialApp.router

// test/ui/harness.dart
Future<(AppDatabase, PushOnRepository)> pumpApp(WidgetTester tester, {DateTime? now, bool onboarded = true});
```

- [ ] **Step 1: Write the failing test**

`test/ui/harness.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/app.dart';
import 'package:pushon/data/db.dart';
import 'package:pushon/data/repository.dart';
import 'package:pushon/domain/dates.dart';
import 'package:pushon/state/providers.dart';

/// Pumps the full app against an in-memory database.
/// [onboarded] seeds installDate so the app lands on Today.
Future<(AppDatabase, PushOnRepository)> pumpApp(
  WidgetTester tester, {
  DateTime? now,
  bool onboarded = true,
}) async {
  final clock = now ?? DateTime(2026, 7, 11, 9); // a Saturday
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = PushOnRepository(db);
  if (onboarded) {
    await repo.patchSettings({'installDate': LocalDate.from(clock).iso});
    await repo.ensureWeekPlan(LocalDate.from(clock).weekStart);
  }
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => clock),
    ],
    child: const PushOnApp(),
  ));
  await tester.pumpAndSettle();
  return (db, repo);
}
```

`test/ui/app_boot_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'harness.dart';

void main() {
  testWidgets('boots to Today when onboarded', (tester) async {
    await pumpApp(tester);
    expect(find.text('Today'), findsWidgets); // nav destination + placeholder
  });

  testWidgets('boots to onboarding on first run', (tester) async {
    await pumpApp(tester, onboarded: false);
    expect(find.textContaining('Onboarding'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/app_boot_test.dart`
Expected: FAIL — `app.dart`/`providers.dart` missing.

- [ ] **Step 3: Implement**

`lib/ui/theme.dart`:

```dart
import 'package:flutter/material.dart';

const kSunshine = Color(0xFFFFD23F);
const kInk = Color(0xFF1B2A4A);
const kCoral = Color(0xFFFF5A36);
const kCream = Color(0xFFFFFDF4);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kCoral,
    primary: kInk,
    secondary: kCoral,
    surface: kCream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kCream,
    appBarTheme: const AppBarTheme(
      backgroundColor: kSunshine, foregroundColor: kInk, elevation: 0, centerTitle: false,
      titleTextStyle: TextStyle(color: kInk, fontSize: 22, fontWeight: FontWeight.w800),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kCream,
      indicatorColor: kSunshine,
      iconTheme: WidgetStateProperty.all(const IconThemeData(color: kInk)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(backgroundColor: kCoral, foregroundColor: Colors.white),
    ),
  );
}
```

`lib/state/providers.dart`:

```dart
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

final streakProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(repositoryProvider);
  final today = ref.watch(todayProvider);
  final install = ref.watch(settingsProvider).valueOrNull?.installDate;
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
```

`lib/router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ui/calendar_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/summary_screen.dart';
import 'ui/today_screen.dart';

GoRouter buildRouter() => GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => _AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/summary', builder: (_, __) => const SummaryScreen()),
            ]),
          ],
        ),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    );

class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: shell.goBranch,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Today'),
            NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
            NavigationDestination(icon: Icon(Icons.insights), label: 'Summary'),
          ],
        ),
      );
}
```

`lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'state/providers.dart';
import 'ui/onboarding_screen.dart';
import 'ui/theme.dart';

class PushOnApp extends ConsumerWidget {
  const PushOnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return settings.when(
      loading: () => MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: Center(child: CircularProgressIndicator()))),
      error: (e, _) =>
          MaterialApp(theme: buildTheme(), home: Scaffold(body: Center(child: Text('$e')))),
      data: (s) {
        if (s.installDate == null) {
          return MaterialApp(theme: buildTheme(), home: const OnboardingScreen());
        }
        return MaterialApp.router(
          title: 'PushOn',
          theme: buildTheme(),
          routerConfig: buildRouter(),
        );
      },
    );
  }
}
```

`lib/main.dart`:

```dart
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/db.dart';
import 'data/notification_scheduler.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase(driftDatabase(name: 'pushon'));
  final scheduler = NotificationScheduler();
  await scheduler.init(onTap: () {}); // a tap simply opens the app — Today is home
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      schedulerProvider.overrideWithValue(scheduler),
    ],
    child: const PushOnApp(),
  ));
}
```

Each placeholder screen (until its real task), e.g. `lib/ui/today_screen.dart`:

```dart
import 'package:flutter/material.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Today')), body: const SizedBox());
}
```

(same shape for `CalendarScreen`, `SummaryScreen`, `SettingsScreen`, and `OnboardingScreen` — the onboarding placeholder body must contain `Text('Onboarding')` for the boot test.)

Delete `test/widget_test.dart` (scaffold counter test — replaced by `app_boot_test.dart`).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test`
Expected: ALL tests pass (domain + data + boot).

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat: add app bootstrap - theme, providers, router, shell"
```

---

### Task 11: Today screen

**Files:**
- Create: `lib/ui/widgets/progress_ring.dart`, `lib/ui/widgets/wheel_log_sheet.dart`, `lib/ui/widgets/week_strip.dart`
- Modify: `lib/ui/today_screen.dart` (replace placeholder)
- Test: `test/ui/today_screen_test.dart`

**Interfaces:**
- Consumes: providers (Task 10), domain functions, `SetEntry`.
- Produces:
  - `class ProgressRing extends StatelessWidget { const ProgressRing({required int logged, required int target, double size = 180}); }` — coral arc over faint ink track, `logged/target` centred.
  - `Future<int?> showWheelPicker(BuildContext context, {required String title, int initial = 20, int min = 1, int max = 200, int step = 1})` — modal bottom sheet with a `CupertinoPicker`, returns chosen value or null. Reused by Calendar (catch-up), Settings (target, with step 5) and edit flows.
  - `class WeekStrip extends ConsumerWidget` — Mon–Sun chips: day letter, target, state colour.
  - `TodayScreen` — inline wheel + **Log** button, ring, streak chip, best-set line, on-track line, editable set list, settings gear in the app bar (pushes `/settings`).

- [ ] **Step 1: Write the failing test**

`test/ui/today_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'harness.dart';

void main() {
  testWidgets('logging via the wheel updates ring total, best set, and list', (tester) async {
    final (_, repo) = await pumpApp(tester);
    expect(find.text('0 / 100'), findsOneWidget); // Saturday = peak day of the 500 fixture
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    // wheel defaults to 20 -> confirm
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('20 / 100'), findsOneWidget);
    expect(find.textContaining('Best set: 20'), findsOneWidget);
  });

  testWidgets('sets can be deleted from the list', (tester) async {
    final (_, repo) = await pumpApp(tester);
    await repo.logSet(date: const LocalDate(2026, 7, 11), count: 25, now: DateTime(2026, 7, 11, 8));
    await tester.pumpAndSettle();
    expect(find.text('25 / 100'), findsOneWidget);
    await tester.longPress(find.text('25 reps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 100'), findsOneWidget);
  });

  testWidgets('on-track line shows when behind for the week', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('to stay on track'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/today_screen_test.dart`
Expected: FAIL — placeholder screen has none of these widgets.

- [ ] **Step 3: Implement**

`lib/ui/widgets/progress_ring.dart`:

```dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.logged, required this.target, this.size = 180});
  final int logged;
  final int target;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(target == 0 ? 0 : (logged / target).clamp(0, 1).toDouble()),
          child: Center(
            child: Text('$logged / $target',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kInk)),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = kInk.withValues(alpha: 0.10);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = kCoral;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2,
        2 * pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}
```

`lib/ui/widgets/wheel_log_sheet.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared scrolling-wheel picker. Returns the chosen value or null.
Future<int?> showWheelPicker(
  BuildContext context, {
  required String title,
  int initial = 20,
  int min = 1,
  int max = 200,
  int step = 1,
}) {
  final values = [for (var v = min; v <= max; v += step) v];
  var selected = values.indexOf(initial.clamp(min, max));
  if (selected < 0) selected = 0;
  return showModalBottomSheet<int>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
          ),
          SizedBox(
            height: 160,
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: selected),
              itemExtent: 40,
              onSelectedItemChanged: (i) => selected = i,
              children: [for (final v in values) Center(child: Text('$v'))],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetContext, values[selected]),
                child: const Text('Add'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

`lib/ui/widgets/week_strip.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/day_status.dart';
import '../../state/providers.dart';
import '../theme.dart';

const kDayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

Color dayStatusColor(DayStatus s) => switch (s) {
      DayStatus.hit => kCoral,
      DayStatus.partial => kCoral.withValues(alpha: 0.45),
      DayStatus.missed => kInk.withValues(alpha: 0.25),
      DayStatus.rest => kInk.withValues(alpha: 0.12),
      DayStatus.pending => kSunshine,
      DayStatus.future || DayStatus.preInstall => Colors.transparent,
    };

class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final plan = ref.watch(weekPlanProvider).valueOrNull;
    final totals = ref.watch(weekTotalsProvider).valueOrNull ?? const {};
    final rest = ref.watch(weekRestDaysProvider).valueOrNull ?? const {};
    final install = ref.watch(settingsProvider).valueOrNull?.installDate;
    if (plan == null || install == null) return const SizedBox(height: 56);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var d = 0; d < 7; d++)
          _DayChip(
            letter: kDayLetters[d],
            target: plan.targets[d],
            status: dayStatus(
              date: today.weekStart.addDays(d),
              today: today,
              installDate: install,
              logged: totals[today.weekStart.addDays(d).iso] ?? 0,
              target: plan.targets[d],
              rest: rest.contains(today.weekStart.addDays(d).iso),
            ),
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.letter, required this.target, required this.status});
  final String letter;
  final int target;
  final DayStatus status;

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: dayStatusColor(status),
            shape: BoxShape.circle,
            border: Border.all(color: kInk.withValues(alpha: 0.25)),
          ),
          child: Text(letter, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
        ),
        const SizedBox(height: 2),
        Text('$target', style: TextStyle(fontSize: 11, color: kInk.withValues(alpha: 0.6))),
      ]);
}
```

`lib/ui/today_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/on_track.dart';
import '../state/providers.dart';
import 'theme.dart';
import 'widgets/progress_ring.dart';
import 'widgets/week_strip.dart';
import 'widgets/wheel_log_sheet.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final plan = ref.watch(weekPlanProvider).valueOrNull;
    final sets = ref.watch(daySetsProvider(today)).valueOrNull ?? const [];
    final totals = ref.watch(weekTotalsProvider).valueOrNull ?? const {};
    final restDays = ref.watch(weekRestDaysProvider).valueOrNull ?? const {};
    final streak = ref.watch(streakProvider).valueOrNull ?? 0;

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
      final now = ref.read(clockProvider)();
      await ref.read(repositoryProvider).logSet(date: today, count: count, now: now);
    }

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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/ui/today_screen_test.dart`
Expected: PASS (3 tests). Then `flutter test` — everything green.

- [ ] **Step 5: Commit**

```powershell
git add lib/ui test/ui
git commit -m "feat: implement Today screen with wheel logging, ring, streak"
```

---

### Task 12: Calendar screen

**Files:**
- Modify: `lib/ui/calendar_screen.dart` (replace placeholder)
- Test: `test/ui/calendar_screen_test.dart`

**Interfaces:**
- Consumes: providers, `dayStatus`/`dayStatusColor`, `showWheelPicker`, repository.
- Produces: `CalendarScreen` — month grid with prev/next month arrows; day cells coloured by `dayStatusColor`; future days show their target when the plan exists, otherwise a **preview** from current settings (`distributeWeek` called directly, NOT stored). Tapping a non-future, non-preInstall day opens `_DaySheet` (bottom sheet): that day's sets, "Add set" (catch-up wheel), and a "Rest / sick day" switch. Opening the sheet calls `ensureWeekPlan(date.weekStart)` first (spec's touch semantics).

- [ ] **Step 1: Write the failing test**

`test/ui/calendar_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'harness.dart';

void main() {
  testWidgets('catch-up: open a past day, add a set, total shows in the cell', (tester) async {
    await pumpApp(tester); // today = Sat 2026-07-11
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9').first); // Thursday this week (Aug 9 also renders in the 42-cell grid)
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle(); // wheel default 20 logged against Jul 9
    expect(find.textContaining('20'), findsWidgets);
  });

  testWidgets('rest toggle flips the day state', (tester) async {
    final (_, repo) = await pumpApp(tester);
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10')); // Friday this week
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rest / sick day'));
    await tester.pumpAndSettle();
    expect(await repo.watchRestDays(const LocalDate(2026, 7, 10), const LocalDate(2026, 7, 10)).first,
        {'2026-07-10'});
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/calendar_screen_test.dart`
Expected: FAIL — placeholder.

- [ ] **Step 3: Implement**

`lib/ui/calendar_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import '../domain/dates.dart';
import '../domain/day_status.dart';
import '../domain/distribution.dart';
import '../state/providers.dart';
import 'theme.dart';
import 'widgets/week_strip.dart' show dayStatusColor;
import 'widgets/wheel_log_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late LocalDate _month; // first of the displayed month

  @override
  void initState() {
    super.initState();
    final t = ref.read(todayProvider);
    _month = LocalDate(t.year, t.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final install = ref.watch(settingsProvider).valueOrNull?.installDate;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final gridStart = _month.weekStart;
    final gridEnd = gridStart.addDays(41); // 6 rows
    final totals = ref.watch(rangeTotalsProvider((gridStart, gridEnd))).valueOrNull ?? const {};
    final rest = ref.watch(rangeRestProvider((gridStart, gridEnd))).valueOrNull ?? const {};
    final plans = ref.watch(rangePlansProvider((gridStart, gridEnd))).valueOrNull ?? const {};

    int targetFor(LocalDate d) {
      final stored = plans[d.weekStart.iso];
      if (stored != null) return stored.targets[d.weekdayIndex];
      if (settings == null) return 0;
      // Preview only — never stored (spec: plans are written on touch).
      return distributeWeek(
          weeklyTarget: settings.weeklyTarget,
          easyDay: settings.easyDay,
          peakDay: settings.peakDay)[d.weekdayIndex];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _month = LocalDate(_month.year, _month.month - 1, 1))),
          Text('${_month.year}-${_month.month.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _month = LocalDate(_month.year, _month.month + 1, 1))),
        ]),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            children: [
              for (var i = 0; i < 42; i++)
                _cell(gridStart.addDays(i), today, install, totals, rest, targetFor),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _cell(LocalDate d, LocalDate today, LocalDate? install, Map<String, int> totals,
      Set<String> rest, int Function(LocalDate) targetFor) {
    final inMonth = d.month == _month.month;
    final logged = totals[d.iso] ?? 0;
    final target = targetFor(d);
    final status = install == null
        ? DayStatus.future
        : dayStatus(date: d, today: today, installDate: install,
            logged: logged, target: target, rest: rest.contains(d.iso));
    final openable = status != DayStatus.future && status != DayStatus.preInstall;
    return Opacity(
      opacity: inMonth ? 1 : 0.35,
      child: InkWell(
        onTap: openable ? () => _openDay(d) : null,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: dayStatusColor(status),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kInk.withValues(alpha: 0.15)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${d.day}', style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
            Text(status == DayStatus.future ? '$target' : '$logged/$target',
                style: TextStyle(fontSize: 10, color: kInk.withValues(alpha: 0.6))),
          ]),
        ),
      ),
    );
  }

  Future<void> _openDay(LocalDate date) async {
    final repo = ref.read(repositoryProvider);
    await repo.ensureWeekPlan(date.weekStart); // touch semantics
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => _DaySheet(date: date),
    );
  }
}

// Range-keyed providers used only by the calendar.
final rangeTotalsProvider = StreamProvider.family<Map<String, int>, (LocalDate, LocalDate)>(
    (ref, r) => ref.watch(repositoryProvider).watchDayTotals(r.$1, r.$2));
final rangeRestProvider = StreamProvider.family<Set<String>, (LocalDate, LocalDate)>(
    (ref, r) => ref.watch(repositoryProvider).watchRestDays(r.$1, r.$2));
final rangePlansProvider =
    StreamProvider.family<Map<String, WeekPlanData>, (LocalDate, LocalDate)>(
        (ref, r) => ref.watch(repositoryProvider).watchWeekPlans(r.$1, r.$2));

class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.date});
  final LocalDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(daySetsProvider(date)).valueOrNull ?? const [];
    final rest = ref.watch(rangeRestProvider((date, date))).valueOrNull ?? const {};
    final repo = ref.read(repositoryProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(date.iso, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
          SwitchListTile(
            title: const Text('Rest / sick day'),
            value: rest.contains(date.iso),
            onChanged: (v) => repo.setRest(date, v),
          ),
          for (final s in sets)
            ListTile(
              key: ValueKey(s.id),
              dense: true,
              title: Text('${s.count} reps'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => repo.deleteSet(id: s.id, now: ref.read(clockProvider)()),
              ),
            ),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add set'),
            onPressed: () async {
              final count = await showWheelPicker(context, title: 'How many?');
              if (count == null) return;
              await repo.logSet(date: date, count: count, now: ref.read(clockProvider)());
            },
          ),
        ]),
      ),
    );
  }
}
```

This task also adds the repository method the calendar needs
(`lib/data/repository.dart`):

```dart
  /// Stored plans keyed by weekStart.iso, for weeks intersecting [from, to].
  Stream<Map<String, WeekPlanData>> watchWeekPlans(LocalDate from, LocalDate to) =>
      (_db.select(_db.weekPlans)
            ..where((t) => t.weekStart.isBetweenValues(from.weekStart.iso, to.iso)))
          .watch()
          .map((rows) => {for (final r in rows) r.weekStart: _planFromRow(r)});
```

with a paired test appended to `test/data/repository_test.dart`:

```dart
  test('watchWeekPlans returns stored plans keyed by weekStart', () async {
    const monday = LocalDate(2026, 7, 6);
    await repo.ensureWeekPlan(monday);
    final plans = await repo.watchWeekPlans(monday, monday.addDays(6)).first;
    expect(plans.keys, ['2026-07-06']);
  });
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/ui/calendar_screen_test.dart`
Expected: PASS (2 tests). Then `flutter test` — all green.

- [ ] **Step 5: Commit**

```powershell
git add lib/ui/calendar_screen.dart lib/data/repository.dart test/ui/calendar_screen_test.dart test/data/repository_test.dart
git commit -m "feat: implement calendar with catch-up logging and rest toggle"
```

### Task 13: Weekly summary screen + Monday takeover

**Files:**
- Modify: `lib/ui/summary_screen.dart` (replace placeholder), `lib/state/providers.dart` (add `summaryDueProvider`), `lib/ui/today_screen.dart` (takeover listener), `lib/data/repository.dart` (add `watchBestSet`)
- Test: `test/ui/summary_screen_test.dart`, extend `test/data/repository_test.dart`

**Interfaces:**
- Consumes: `raiseSuggestion`/`WeekResult` (Task 6), repository, providers.
- Produces:
  - Repository addition: `Stream<int> watchBestSet(LocalDate from, LocalDate to)` — max non-deleted `count` in range, 0 when none.
  - `final summaryDueProvider = FutureProvider<LocalDate?>` — the `weekStart` of the most recent **completed** week whose summary hasn't been shown (`lastSummaryShownWeek` < current `weekStart`, install before current week), else null. **Most recent completed week only — summaries never queue.**
  - `SummaryScreen` — reads the most recent completed week (or shows "Your first summary arrives on Monday" when none): total vs target, per-day mini bars, best set of week, streak, and the raise-suggestion card (`Raise to N` / `Keep current`) shown when `raiseSuggestion` returns non-null for the last 3 completed weeks.
  - Today screen: `ref.listen(summaryDueProvider, ...)` — when a due week arrives, `context.push('/summary')` once and `patchSettings({'lastSummaryShownWeek': <current weekStart>.iso})`.

- [ ] **Step 1: Write the failing tests**

Add to `test/data/repository_test.dart`:

```dart
  test('watchBestSet returns the max count, 0 when empty', () async {
    expect(await repo.watchBestSet(day, day).first, 0);
    await repo.logSet(date: day, count: 25, now: now);
    await repo.logSet(date: day, count: 40, now: now);
    await repo.deleteSet(id: 'id-1', now: now); // the 40
    expect(await repo.watchBestSet(day, day).first, 25);
  });
```

`test/ui/summary_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'harness.dart';

void main() {
  testWidgets('takeover fires on first open of a new week and shows the completed week', (tester) async {
    // Install + data live in LAST week (Mon Jun 29 - Sun Jul 5); today is Sat Jul 11.
    final (_, repo) = await pumpApp(tester, seed: (repo) async {
      await repo.patchSettings({'installDate': '2026-06-29'});
      await repo.ensureWeekPlan(const LocalDate(2026, 6, 29));
      await repo.logSet(date: const LocalDate(2026, 7, 1), count: 300,
          now: DateTime(2026, 7, 1, 9));
      await repo.logSet(date: const LocalDate(2026, 7, 4), count: 250,
          now: DateTime(2026, 7, 4, 9));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('550'), findsWidgets);       // week total
    expect(find.textContaining('Best set: 300'), findsOneWidget);
    expect(find.text('Best set trend'), findsOneWidget);
    // Second boot with the same settings would not re-show: lastSummaryShownWeek was patched.
    final s = await repo.getSettings();
    expect(s.lastSummaryShownWeek, const LocalDate(2026, 7, 6));
  });

  testWidgets('suggestion card appears after 3 strong weeks and accept raises the target', (tester) async {
    final (_, repo) = await pumpApp(tester, seed: (repo) async {
      await repo.patchSettings({'installDate': '2026-06-15'});
      for (final monday in const [LocalDate(2026, 6, 15), LocalDate(2026, 6, 22), LocalDate(2026, 6, 29)]) {
        await repo.ensureWeekPlan(monday);
        await repo.logSet(date: monday, count: 560, now: DateTime(monday.year, monday.month, monday.day, 9));
      }
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Raise to 560'), findsOneWidget);
    await tester.tap(find.textContaining('Raise to 560'));
    await tester.pumpAndSettle();
    expect((await repo.getSettings()).weeklyTarget, 560);
  });
}
```

This needs a `seed` hook on the harness — extend `pumpApp` with an optional `Future<void> Function(PushOnRepository)? seed` parameter, run after DB creation and **instead of** the default `onboarded` seeding when provided:

```dart
Future<(AppDatabase, PushOnRepository)> pumpApp(
  WidgetTester tester, {
  DateTime? now,
  bool onboarded = true,
  Future<void> Function(PushOnRepository repo)? seed,
}) async {
  // ... db/repo as before ...
  if (seed != null) {
    await seed(repo);
  } else if (onboarded) {
    // ... default seeding as before ...
  }
  // ... pumpWidget as before ...
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/ui/summary_screen_test.dart test/data/repository_test.dart`
Expected: FAIL — `watchBestSet`/`seed` missing, placeholder screen.

- [ ] **Step 3: Implement**

Repository addition (`lib/data/repository.dart`):

```dart
  Stream<int> watchBestSet(LocalDate from, LocalDate to) =>
      _liveSets(from, to).watch().map((rows) =>
          rows.isEmpty ? 0 : rows.map((r) => r.count).reduce((a, b) => a > b ? a : b));
```

Provider addition (`lib/state/providers.dart`):

```dart
final summaryDueProvider = FutureProvider<LocalDate?>((ref) async {
  final s = await ref.watch(settingsProvider.future);
  final today = ref.watch(todayProvider);
  final currentWeek = today.weekStart;
  final install = s.installDate;
  if (install == null || !install.isBefore(currentWeek)) return null; // no completed week yet
  if (s.lastSummaryShownWeek != null && !s.lastSummaryShownWeek!.isBefore(currentWeek)) return null;
  return currentWeek.addDays(-7); // most recent completed week only — never queue
});
```

Today screen — add inside `build`, before `return Scaffold(...)`:

```dart
    ref.listen(summaryDueProvider, (prev, next) {
      final due = next.valueOrNull;
      if (due != null) {
        ref.read(repositoryProvider).patchSettings(
            {'lastSummaryShownWeek': ref.read(todayProvider).weekStart.iso});
        context.push('/summary');
      }
    });
```

`lib/ui/summary_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import '../domain/dates.dart';
import '../domain/suggestion.dart';
import '../state/providers.dart';
import 'theme.dart';

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
    final data = ref.watch(summaryDataProvider).valueOrNull;
    final streak = ref.watch(streakProvider).valueOrNull ?? 0;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Summary')),
        body: const Center(child: Text('Your first summary arrives on Monday.')),
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
      ]),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test`
Expected: ALL green (including the two new summary tests and the repo test).

- [ ] **Step 5: Commit**

```powershell
git add lib test
git commit -m "feat: implement weekly summary with takeover and raise suggestion"
```

---

### Task 14: Settings screen

**Files:**
- Modify: `lib/ui/settings_screen.dart` (replace placeholder)
- Test: `test/ui/settings_screen_test.dart`

**Interfaces:**
- Consumes: providers, `showWheelPicker`, repository.
- Produces: `SettingsScreen` — sections: **Weekly target** (tile shows current value; tap → `showWheelPicker(min: 5, max: 2000, step: 5)`; subtitle "Changes apply from next Monday"), **Rhythm** (easy-day and peak-day `DropdownButtonFormField<int>` over Mon..Sun; selecting `easy == peak` shows a `SnackBar` "Easy and peak day must differ" and does not save), **Reminders** (two `SwitchListTile`s for nudge/reminder; two tiles for waking start/end via `showTimePicker`; "Reminders not showing up?" tile → battery-exemption request, Task 16 wires the actual call — until then it stores nothing and shows a dialog explaining), **About** (version tile, licenses via `showLicensePage`, privacy policy summary dialog: "All data stays on your device.").

- [ ] **Step 1: Write the failing test**

`test/ui/settings_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'harness.dart';

void main() {
  Future<void> openSettings(tester) async {
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
  }

  testWidgets('weekly target edits via wheel and persists', (tester) async {
    final (_, repo) = await pumpApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Weekly target'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add')); // wheel confirm, unchanged default = current 500
    await tester.pumpAndSettle();
    expect((await repo.getSettings()).weeklyTarget, 500);
  });

  testWidgets('easy == peak is rejected with a snackbar', (tester) async {
    final (_, repo) = await pumpApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Easy day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saturday').last); // same as default peak
    await tester.pumpAndSettle();
    expect(find.text('Easy and peak day must differ'), findsOneWidget);
    expect((await repo.getSettings()).easyDay, 1, reason: 'not saved');
  });
}
```

(Import `package:flutter/material.dart` for `Icons` in the test file.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/settings_screen_test.dart`
Expected: FAIL — placeholder.

- [ ] **Step 3: Implement**

`lib/ui/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'theme.dart';
import 'widgets/wheel_log_sheet.dart';

const kDayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _fmtMinutes(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).valueOrNull;
    final repo = ref.read(repositoryProvider);
    if (s == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    Future<void> pickDay({required bool easy}) async {
      final chosen = await showDialog<int>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: Text(easy ? 'Easy day' : 'Peak day'),
          children: [
            for (var d = 0; d < 7; d++)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, d),
                child: Text(kDayNames[d]),
              ),
          ],
        ),
      );
      if (chosen == null) return;
      final conflict = easy ? chosen == s.peakDay : chosen == s.easyDay;
      if (conflict) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Easy and peak day must differ')));
        }
        return;
      }
      await repo.patchSettings({easy ? 'easyDay' : 'peakDay': '$chosen'});
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        ListTile(
          title: const Text('Weekly target'),
          subtitle: const Text('Changes apply from next Monday'),
          trailing: Text('${s.weeklyTarget}', style: const TextStyle(fontSize: 16, color: kInk)),
          onTap: () async {
            final v = await showWheelPicker(context,
                title: 'Weekly target', initial: s.weeklyTarget, min: 5, max: 2000, step: 5);
            if (v != null) await repo.patchSettings({'weeklyTarget': '$v'});
          },
        ),
        ListTile(
            title: const Text('Easy day'),
            trailing: Text(kDayNames[s.easyDay]),
            onTap: () => pickDay(easy: true)),
        ListTile(
            title: const Text('Peak day'),
            trailing: Text(kDayNames[s.peakDay]),
            onTap: () => pickDay(easy: false)),
        const Divider(),
        SwitchListTile(
          title: const Text('Inactivity nudge'),
          subtitle: const Text('A prod 4 hours after your last set'),
          value: s.nudgeEnabled,
          onChanged: (v) => repo.patchSettings({'nudgeEnabled': '$v'}),
        ),
        SwitchListTile(
          title: const Text('Evening reminder'),
          subtitle: const Text('Remaining reps at 8pm'),
          value: s.reminderEnabled,
          onChanged: (v) => repo.patchSettings({'reminderEnabled': '$v'}),
        ),
        ListTile(
          title: const Text('Waking window starts'),
          trailing: Text(_fmtMinutes(s.wakingStartMinutes)),
          onTap: () async {
            final t = await showTimePicker(context: context,
                initialTime: TimeOfDay(hour: s.wakingStartMinutes ~/ 60, minute: s.wakingStartMinutes % 60));
            if (t != null) await repo.patchSettings({'wakingStartMinutes': '${t.hour * 60 + t.minute}'});
          },
        ),
        ListTile(
          title: const Text('Waking window ends'),
          trailing: Text(_fmtMinutes(s.wakingEndMinutes)),
          onTap: () async {
            final t = await showTimePicker(context: context,
                initialTime: TimeOfDay(hour: s.wakingEndMinutes ~/ 60, minute: s.wakingEndMinutes % 60));
            if (t != null) await repo.patchSettings({'wakingEndMinutes': '${t.hour * 60 + t.minute}'});
          },
        ),
        ListTile(
          title: const Text('Reminders not showing up?'),
          subtitle: const Text("Ask Android not to put PushOn to sleep"),
          onTap: () => requestBatteryExemption(context), // Task 16 provides this
        ),
        const Divider(),
        ListTile(
          title: const Text('About PushOn'),
          subtitle: const Text('The push-up habit that sticks. All data stays on your device.'),
          onTap: () => showLicensePage(context: context, applicationName: 'PushOn'),
        ),
      ]),
    );
  }
}

/// Placeholder until Task 16 wires permission_handler; keeps this task shippable.
Future<void> requestBatteryExemption(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: const Text('Reminders work best if Android does not put PushOn to sleep.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
    ),
  );
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test`
Expected: ALL green.

- [ ] **Step 5: Commit**

```powershell
git add lib/ui/settings_screen.dart test/ui/settings_screen_test.dart
git commit -m "feat: implement settings screen with rhythm validation"
```

---

### Task 15: Onboarding

**Files:**
- Modify: `lib/ui/onboarding_screen.dart` (replace placeholder)
- Test: `test/ui/onboarding_test.dart`

**Interfaces:**
- Consumes: repository, providers, `kDayNames` (Task 14), theme.
- Produces: `OnboardingScreen` — brand header (icon block + "PushOn" + tagline), inline `CupertinoPicker` for the weekly target (multiples of 5, 5–2000, initial 500), easy/peak day dropdowns (defaults Tue/Sat, same `!=` validation as Settings), **Start** button that: `patchSettings({weeklyTarget, easyDay, peakDay, installDate: today.iso})` then `ensureWeekPlan(today.weekStart)` — the spec's one pre-Monday plan write. The settings gate in `app.dart` (Task 10) then flips to the router automatically.

- [ ] **Step 1: Write the failing test**

`test/ui/onboarding_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'harness.dart';

void main() {
  testWidgets('completing onboarding writes settings and the current week plan', (tester) async {
    final (_, repo) = await pumpApp(tester, onboarded: false);
    expect(find.text('The push-up habit that sticks.'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    final s = await repo.getSettings();
    expect(s.installDate, const LocalDate(2026, 7, 11));
    expect(s.weeklyTarget, 500);
    final plan = await repo.getWeekPlan(const LocalDate(2026, 7, 6));
    expect(plan, isNotNull, reason: 'the one pre-Monday plan write');
    expect(find.text('Log'), findsOneWidget, reason: 'landed on Today');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/onboarding_test.dart`
Expected: FAIL — placeholder has no Start button.

- [ ] **Step 3: Implement**

`lib/ui/onboarding_screen.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dates.dart';
import '../state/providers.dart';
import 'settings_screen.dart' show kDayNames;
import 'theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static final _targets = [for (var v = 5; v <= 2000; v += 5) v];
  int _targetIndex = _targets.indexOf(500);
  int _easy = 1;
  int _peak = 5;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kSunshine,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Spacer(),
              const Text('PushOn',
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: kInk)),
              const Text('The push-up habit that sticks.',
                  style: TextStyle(fontSize: 16, color: kInk)),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text("We'll nudge you when a set is due — allow notifications when asked.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: kInk)),
              ),
              const Spacer(),
              const Text('Weekly target', style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
              SizedBox(
                height: 120,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: _targetIndex),
                  itemExtent: 36,
                  onSelectedItemChanged: (i) => setState(() => _targetIndex = i),
                  children: [for (final v in _targets) Center(child: Text('$v'))],
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                DropdownButton<int>(
                  value: _easy,
                  items: [for (var d = 0; d < 7; d++)
                    DropdownMenuItem(value: d, child: Text('Easy: ${kDayNames[d]}'))],
                  onChanged: (d) {
                    if (d == null || d == _peak) return;
                    setState(() => _easy = d);
                  },
                ),
                DropdownButton<int>(
                  value: _peak,
                  items: [for (var d = 0; d < 7; d++)
                    DropdownMenuItem(value: d, child: Text('Peak: ${kDayNames[d]}'))],
                  onChanged: (d) {
                    if (d == null || d == _easy) return;
                    setState(() => _peak = d);
                  },
                ),
              ]),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final repo = ref.read(repositoryProvider);
                    final today = LocalDate.from(ref.read(clockProvider)());
                    await repo.patchSettings({
                      'weeklyTarget': '${_targets[_targetIndex]}',
                      'easyDay': '$_easy',
                      'peakDay': '$_peak',
                      'installDate': today.iso,
                    });
                    await repo.ensureWeekPlan(today.weekStart);
                    // Contextual permission ask (spec: first run, with explainer).
                    await ref.read(schedulerProvider)?.requestPermission();
                  },
                  child: const Text('Start'),
                ),
              ),
            ]),
          ),
        ),
      );
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test`
Expected: ALL green (update `app_boot_test.dart`'s onboarding expectation from `textContaining('Onboarding')` to `text('The push-up habit that sticks.')` in this task).

- [ ] **Step 5: Commit**

```powershell
git add lib/ui/onboarding_screen.dart test/ui
git commit -m "feat: implement first-run onboarding with immediate week plan"
```

---

### Task 16: Notification wiring — sync, permissions, battery prompt, manifest

**Files:**
- Modify: `lib/state/providers.dart` (add `notificationSyncProvider`, `firstOpenTodayProvider`), `lib/app.dart` (activate sync), `lib/ui/today_screen.dart` (battery prompt after first-ever log), `lib/ui/settings_screen.dart` (real `requestBatteryExemption`), `android/app/src/main/AndroidManifest.xml`
- Test: `test/ui/notification_sync_test.dart`

**Interfaces:**
- Consumes: `planNotifications` (Task 9), `NotificationScheduler`, providers, `permission_handler`.
- Produces:
  - `final firstOpenTodayProvider = Provider<DateTime>` — captured once per app process at first read.
  - `final notificationSyncProvider = Provider<void>` — watches today's sets, plan, rest flags, and settings; on every change computes `planNotifications(...)` and calls `scheduler.applyPlan(...)` when `schedulerProvider` is non-null. Activated by `ref.watch(notificationSyncProvider)` inside `PushOnApp.build` on the `installDate != null` path.
  - `requestBatteryExemption(BuildContext)` in `settings_screen.dart` becomes real: `Permission.ignoreBatteryOptimizations.request()` behind an explainer dialog.
  - Today screen: after a successful `logSet`, when `!settings.batteryPromptShown`, show the explainer → request → `patchSettings({'batteryPromptShown': 'true'})` (whatever the permission outcome — ask once).
  - Manifest gains: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permissions + the flutter_local_notifications `ScheduledNotificationBootReceiver` receiver block (see the package README for the exact XML — copy it verbatim).

- [ ] **Step 1: Write the failing test**

`test/ui/notification_sync_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/data/notification_scheduler.dart';
import 'package:pushon/domain/notification_planner.dart';
import 'package:pushon/state/providers.dart';
import 'harness.dart';

class FakeScheduler implements NotificationScheduler {
  final applied = <List<PlannedNotification>>[];
  @override
  Future<void> init({required void Function() onTap}) async {}
  @override
  Future<void> requestPermission() async {}
  @override
  Future<void> applyPlan(List<PlannedNotification> plan) async => applied.add(plan);
}

void main() {
  testWidgets('logging a set reschedules; meeting the target clears the plan', (tester) async {
    final fake = FakeScheduler();
    await pumpApp(tester, extraOverrides: [schedulerProvider.overrideWithValue(fake)]);
    expect(fake.applied, isNotEmpty, reason: 'initial sync on boot');
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add')); // logs 20 of Saturday's 100
    await tester.pumpAndSettle();
    expect(fake.applied.last.map((n) => n.kind),
        containsAll([PlannedKind.inactivityNudge, PlannedKind.eveningReminder]));
    expect(fake.applied.last.singleWhere((n) => n.kind == PlannedKind.eveningReminder).body,
        contains('80'));
  });
}
```

(Extend the harness with `List<Override> extraOverrides = const []` appended to the ProviderScope overrides.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/notification_sync_test.dart`
Expected: FAIL — `extraOverrides`/sync provider missing.

- [ ] **Step 3: Implement**

Additions to `lib/state/providers.dart`:

```dart
final firstOpenTodayProvider = Provider<DateTime>((ref) => ref.watch(clockProvider)());

final notificationSyncProvider = Provider<void>((ref) {
  final scheduler = ref.watch(schedulerProvider);
  if (scheduler == null) return;
  final today = ref.watch(todayProvider);
  final plan = ref.watch(weekPlanProvider).valueOrNull;
  final settings = ref.watch(settingsProvider).valueOrNull;
  final totals = ref.watch(weekTotalsProvider).valueOrNull;
  final rest = ref.watch(weekRestDaysProvider).valueOrNull;
  final sets = ref.watch(daySetsProvider(today)).valueOrNull;
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
```

(add `import '../domain/notification_planner.dart';` to providers.dart)

In `lib/app.dart`, on the `installDate != null` branch, first line: `ref.watch(notificationSyncProvider);`.

Real battery exemption in `lib/ui/settings_screen.dart`:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestBatteryExemption(BuildContext context) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: const Text(
          'Reminders work best if Android does not put PushOn to sleep. Allow it?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Not now')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Allow')),
      ],
    ),
  );
  if (proceed == true) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}
```

Today screen, inside `log()` after the `logSet` await:

```dart
      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings != null && !settings.batteryPromptShown && context.mounted) {
        await requestBatteryExemption(context);
        await ref.read(repositoryProvider).patchSettings({'batteryPromptShown': 'true'});
      }
```

(add `import 'settings_screen.dart' show requestBatteryExemption;`)

Manifest additions inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

and inside `<application>` the two flutter_local_notifications receivers (copy the `ScheduledNotificationReceiver` + `ScheduledNotificationBootReceiver` XML verbatim from the package's current README — names/attributes occasionally change between majors, so the README of the resolved version is the source of truth).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test`
Expected: ALL green.

- [ ] **Step 5: Manual smoke on a device/emulator**

```powershell
flutter run
```

Log a set → battery-exemption dialog appears once. Check a scheduled notification exists: `adb shell dumpsys alarm | Select-String pushon` (best-effort — presence, not exact time).

- [ ] **Step 6: Commit**

```powershell
git add lib test android/app/src/main/AndroidManifest.xml
git commit -m "feat: wire notification sync, permissions, battery prompt"
```

---

### Task 17: Branding — launcher icon + assets

**Files:**
- Create: `assets/brand/icon-1024.png`, `assets/brand/icon-foreground-1024.png`, `assets/brand/icon-foreground.svg`, `flutter_launcher_icons.yaml`
- Modify: `pubspec.yaml` (dev dep)

**Interfaces:**
- Consumes: `assets/brand/icon.svg` (committed, approved mark).
- Produces: real launcher icons (legacy + adaptive) baked into `android/app/src/main/res/mipmap-*`.

- [ ] **Step 1: Create the adaptive foreground SVG**

`assets/brand/icon-foreground.svg` — the figure only, centred in the adaptive safe zone (66% of canvas), no tile:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120">
  <!-- PushOn adaptive foreground — figure scaled into the 66% safe zone -->
  <g transform="translate(60 60) scale(0.62) translate(-60 -60)">
    <line x1="22" y1="87" x2="98" y2="87" stroke="#1B2A4A" stroke-width="5" stroke-linecap="round" opacity="0.22"/>
    <circle cx="30" cy="45" r="9" fill="#1B2A4A"/>
    <line x1="40" y1="52" x2="92" y2="72" stroke="#1B2A4A" stroke-width="10" stroke-linecap="round"/>
    <line x1="47" y1="56" x2="44" y2="84" stroke="#1B2A4A" stroke-width="9" stroke-linecap="round"/>
  </g>
</svg>
```

- [ ] **Step 2: Rasterize both SVGs to 1024px PNGs**

```powershell
npx sharp-cli --input assets/brand/icon.svg --output assets/brand/icon-1024.png resize 1024 1024
npx sharp-cli --input assets/brand/icon-foreground.svg --output assets/brand/icon-foreground-1024.png resize 1024 1024
```

(Node 20+ is on this box. If sharp-cli balks at SVG input, any rasterizer at 1024×1024 is fine — e.g. Inkscape `--export-type=png`.) Visually inspect both PNGs before continuing.

- [ ] **Step 3: Generate launcher icons**

```powershell
flutter pub add --dev flutter_launcher_icons
```

`flutter_launcher_icons.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: assets/brand/icon-1024.png
  adaptive_icon_background: "#FFD23F"
  adaptive_icon_foreground: assets/brand/icon-foreground-1024.png
```

Run: `dart run flutter_launcher_icons`
Expected: mipmap folders repopulated.

- [ ] **Step 4: Verify on device/emulator**

`flutter run` — launcher shows the plank icon on the yellow tile (round + square masks both look centred).

- [ ] **Step 5: Commit**

```powershell
git add assets/brand flutter_launcher_icons.yaml pubspec.yaml pubspec.lock android
git commit -m "feat: add PushOn launcher icon (legacy + adaptive)"
```

---

### Task 18: Release readiness — signing, build script, privacy policy

**Files:**
- Create: `android/key.properties.example`, `scripts/build-release.mjs`, `docs/privacy-policy.md`, `docs/release-checklist.md`
- Modify: `android/app/build.gradle.kts` (conditional release signing)

**Interfaces:**
- Consumes: the working app.
- Produces: a Play-uploadable AAB pipeline. **No automated test** (config-only task — the CI debug build plus a local release build are the verification).

- [ ] **Step 1: Generate the upload keystore (one-time, NEVER committed)**

```powershell
keytool -genkey -v -keystore android/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Confirm `.gitignore` already covers `*.jks` and `key.properties` (it does — repo root `.gitignore`). Create `android/key.properties` locally from the example:

`android/key.properties.example`:

```properties
storePassword=CHANGE_ME
keyPassword=CHANGE_ME
keyAlias=upload
storeFile=../upload-keystore.jks
```

- [ ] **Step 2: Wire conditional signing in `android/app/build.gradle.kts`**

Follow the standard Flutter deployment pattern (docs.flutter.dev "Build and release an Android app"): load `key.properties` if it exists; `signingConfigs.release` from it; `buildTypes.release.signingConfig = if (keystoreProperties exists) signingConfigs.release else signingConfigs.debug`. Copy the snippet from the Flutter docs for the scaffold's current Gradle DSL — do not hand-invent Gradle syntax.

- [ ] **Step 3: Build script with timestamp versionCode**

`scripts/build-release.mjs`:

```js
#!/usr/bin/env node
// Builds the Play AAB with a strictly-increasing versionCode
// (minutes since epoch — same scheme as the Castwright companion).
import { execSync } from 'node:child_process';

const buildNumber = Math.floor(Date.now() / 60000);
const cmd = `flutter build appbundle --release --build-number=${buildNumber}`;
console.log(`versionCode ${buildNumber}\n> ${cmd}`);
if (!process.argv.includes('--dry-run')) {
  execSync(cmd, { stdio: 'inherit' });
  console.log('AAB at build/app/outputs/bundle/release/app-release.aab');
}
```

Run: `node scripts/build-release.mjs --dry-run`
Expected: prints a versionCode > 29,000,000 and the command, builds nothing.

- [ ] **Step 4: Privacy policy + release checklist**

`docs/privacy-policy.md`:

```markdown
# PushOn privacy policy

PushOn stores your push-up log, targets, and settings **only on your
device**. The app makes no network requests: nothing is collected,
transmitted, shared, or sold — to anyone, ever.

Notifications are generated on-device. Deleting the app deletes all data.

Contact: open an issue at https://github.com/dudarenok-maker/pushon/issues
```

`docs/release-checklist.md` — the manual Play Console path, verbatim steps: create app (name PushOn, free), upload AAB from `scripts/build-release.mjs`, data-safety form = "no data collected", content rating questionnaire (fitness, no UGC), privacy policy URL `https://github.com/dudarenok-maker/pushon/blob/main/docs/privacy-policy.md`, listing copy (tagline as short description), screenshots from a real device, internal testing → production.

- [ ] **Step 5: Verify a signed release build**

```powershell
node scripts/build-release.mjs
```

Expected: `app-release.aab` produced; `flutter build appbundle` reports signing with the upload key (not debug).

- [ ] **Step 6: Commit**

```powershell
git add android/key.properties.example android/app/build.gradle.kts scripts/build-release.mjs docs/privacy-policy.md docs/release-checklist.md
git commit -m "build: add release signing, versioned AAB script, privacy policy"
```

---

### Task 19: Docs, repo hygiene, final verification

**Files:**
- Create: `CONTRIBUTING.md`
- Modify: `README.md`, `CLAUDE.md` (commands section if any drifted)

**Interfaces:** none — closes out the plan.

- [ ] **Step 1: Update README**

Replace the "Status: design phase" paragraph with: feature list (weekly target + rhythm, wheel logging, streak, calendar catch-up, weekly summary, reminders), a "Build it yourself" section (`flutter pub get`, `dart run build_runner build`, `flutter run`), the privacy one-liner, and a link to `docs/release-checklist.md`. Keep the tagline header.

- [ ] **Step 2: Add CONTRIBUTING.md**

Short: dev setup (Flutter stable, `flutter pub get`, build_runner), test commands, commit convention (`<type>: <subject>`), PR flow (branch → PR → CI green → merge), where invariants live (`lib/domain/` + spec link).

- [ ] **Step 3: Full local verification**

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Expected: zero issues, all tests pass, build succeeds.

- [ ] **Step 4: Repo protections (now that CI exists)**

```powershell
gh api -X PUT repos/dudarenok-maker/pushon/branches/main/protection --input - <<'JSON'
{"required_status_checks":{"strict":false,"contexts":["verify"]},
 "enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null}
JSON
```

(Run from Git Bash for the heredoc, or write the JSON to a temp file and `--input file`.) Also enable CodeQL default setup for Actions workflows: repo Settings → Code security → CodeQL → Default (or `gh api -X PATCH repos/dudarenok-maker/pushon/code-scanning/default-setup -f state=configured`).

- [ ] **Step 5: Commit and merge**

```powershell
git add README.md CONTRIBUTING.md CLAUDE.md
git commit -m "docs: add contributor guide and final README"
git push
```

Open the PR for the whole branch per CLAUDE.md workflow; merge when CI is green.

---

## Final verification checklist (after all tasks)

1. `flutter analyze` — clean. `flutter test` — all green (domain, data, UI).
2. Fresh install on a real device: onboarding → Today; log 3 sets via the wheel; streak shows 1; calendar shows today pending.
3. Kill + reopen: data persists; notifications rescheduled (check `adb shell dumpsys alarm`).
4. Set device clock to next Monday, open app: weekly summary takeover appears once.
5. `node scripts/build-release.mjs` produces a signed AAB; versionCode strictly increases between runs.
6. CI green on the PR; branch protection blocks direct pushes to main with a red check.

## Deliberately NOT in this plan (spec's out-of-scope list)

Accounts/cloud, health sync, iOS build/release, social, other exercises, camera counting, paid anything. The `sets` schema (UUID/soft-delete/timestamps) is the only future-proofing bought.
