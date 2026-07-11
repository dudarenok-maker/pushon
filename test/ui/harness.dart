import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/app.dart';
import 'package:pushon/data/db.dart';
import 'package:pushon/data/repository.dart';
import 'package:pushon/domain/dates.dart';
import 'package:pushon/state/providers.dart';

/// Pumps the full app against an in-memory database.
/// [onboarded] seeds installDate so the app lands on Today.
///
/// Teardown closes the database inside [WidgetTester.runAsync]. drift drives
/// its stream-query fetches, cancellations and final `close()` on the *real*
/// event loop; flutter_test's default fake-async clock never advances that
/// work, so closing the db (or tearing down a live `.watch()` subscription)
/// under fake-async deadlocks. Running teardown under `runAsync` lets the real
/// event loop drain drift's async work. This is a test-harness concern only —
/// the production app never closes the database under a live widget tree.
Future<(AppDatabase, PushOnRepository)> pumpApp(
  WidgetTester tester, {
  DateTime? now,
  bool onboarded = true,
  Future<void> Function(PushOnRepository repo)? seed,
}) async {
  final clock = now ?? DateTime(2026, 7, 11, 9); // a Saturday
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() => tester.runAsync(() async => db.close()));
  final repo = PushOnRepository(db);
  if (seed != null) {
    await seed(repo);
  } else if (onboarded) {
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

/// Settles the widget tree while letting drift's real-event-loop work run.
///
/// [WidgetTester.pumpAndSettle] only advances the fake-async clock, so a frame
/// that is waiting on a drift stream emission (e.g. a screen showing a spinner
/// until a `FutureProvider` finishes its `watch().first` reads) never settles.
/// Each round hands control to the real event loop via `runAsync` (draining
/// drift's query futures) and then pumps a frame. Returns as soon as the tree
/// is idle, or after [rounds] rounds.
Future<void> settle(WidgetTester tester, {int rounds = 60}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
    // `find.byType(ProgressIndicator)` would never match: ProgressIndicator is
    // abstract, so no widget's runtimeType equals it. Match the concrete
    // subtypes (Circular/Linear) via an is-check so a visible spinner actually
    // keeps `settle` looping.
    if (!tester.binding.hasScheduledFrame &&
        find.byWidgetPredicate((w) => w is ProgressIndicator).evaluate().isEmpty) {
      return;
    }
  }
}

/// Like [settle], but drives real-event-loop rounds until [finder] matches (or
/// [rounds] elapse). Use when a screen renders a non-spinner placeholder while
/// a drift-backed `FutureProvider` loads — [settle]'s spinner heuristic would
/// return before the awaited content appears. The weekly-summary screen is the
/// case in point: it shows a text placeholder until `summaryDataProvider`
/// resolves its ~15 sequential `watch().first` reads.
Future<void> settleUntil(WidgetTester tester, Finder finder, {int rounds = 100}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// Reads a drift stream's current value on the real event loop.
///
/// A bare `await stream.first` inside a widget test subscribes to a drift query
/// stream under fake-async; the subscription's fetch and cancel are scheduled
/// on the real event loop and are never drained, hanging the test at teardown.
/// Wrapping the read in `runAsync` keeps drift's async work on the real loop.
Future<T> readStream<T>(WidgetTester tester, Stream<T> stream) async {
  late T value;
  await tester.runAsync(() async => value = await stream.first);
  return value;
}

/// Reads a drift-backed `Future` (e.g. `repo.getSettings()`) on the real event
/// loop, for the same fake-async reason as [readStream].
Future<T> readFuture<T>(WidgetTester tester, Future<T> Function() read) async {
  late T value;
  await tester.runAsync(() async => value = await read());
  return value;
}
