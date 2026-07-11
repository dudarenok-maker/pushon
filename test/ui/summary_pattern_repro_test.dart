// Regression repro for issue #2 (the systemic half): a full-app widget test
// that navigates to a pushed top-level route whose screen resolves a
// FutureProvider performing several sequential drift `watch().first` reads.
//
// Under flutter_test's fake-async clock those drift stream reads never resolve
// (drift drives them on the real event loop), so the screen's spinner never
// clears (pumpAndSettle would hang) and the test deadlocks at teardown. The
// harness `settle` (real-event-loop rounds) + runAsync db teardown fix it.
//
// This mirrors the real weekly-summary screen's data provider without
// depending on its (still-stubbed) implementation.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/data/db.dart';
import 'package:pushon/data/repository.dart';
import 'package:pushon/domain/dates.dart';
import 'package:pushon/state/providers.dart';

import 'harness.dart';

// ~15 sequential drift stream `.first` reads, exactly the summary-screen shape.
final _summaryDataProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(repositoryProvider);
  var total = 0;
  for (var w = 0; w < 5; w++) {
    final from = const LocalDate(2026, 6, 1).addDays(w * 7);
    final to = from.addDays(6);
    total += (await repo.watchDayTotals(from, to).first).values.fold(0, (a, b) => a + b);
    total += (await repo.watchRestDays(from, to).first).length;
    total += (await repo.watchWeekPlans(from, to).first).length;
  }
  return total;
});

class _SummaryLikeScreen extends ConsumerWidget {
  const _SummaryLikeScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_summaryDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly summary')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
        data: (d) => Center(child: Text('total=$d')),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _SummaryLikeScreen())),
            child: const Text('Open summary'),
          ),
        ),
      );
}

void main() {
  testWidgets('summary-pattern: pushed route resolves many drift .first reads', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(() async => db.close()));
    final repo = PushOnRepository(db);
    await repo.patchSettings({'installDate': '2026-06-01'});
    await repo.ensureWeekPlan(const LocalDate(2026, 6, 1));
    await repo.logSet(date: const LocalDate(2026, 6, 3), count: 30, now: DateTime(2026, 6, 3, 9));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 7, 11, 9)),
      ],
      child: const MaterialApp(home: _HomeScreen()),
    ));
    await tester.pumpAndSettle();

    // Navigate to the pushed top-level route (summary takeover).
    await tester.tap(find.text('Open summary'));
    await settle(tester); // real-event-loop settle: resolves the drift reads

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('total='), findsOneWidget);
  });
}
