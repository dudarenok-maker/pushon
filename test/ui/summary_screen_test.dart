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
    // The Today-screen takeover listener pushes /weekly-summary once its
    // summaryDueProvider resolves, and the summary screen then loads its
    // drift-backed summaryDataProvider. Both run on the real event loop, so we
    // settle via real-loop rounds until the week total renders — see
    // harness.settleUntil.
    await settleUntil(tester, find.textContaining('550'));
    expect(find.textContaining('550'), findsWidgets);       // week total
    expect(find.textContaining('Best set: 300'), findsOneWidget);
    expect(find.text('Best set trend'), findsOneWidget);
    // Second boot with the same settings would not re-show: lastSummaryShownWeek was patched.
    final s = await readFuture(tester, () => repo.getSettings());
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
    await settleUntil(tester, find.textContaining('Raise to 560'));
    expect(find.textContaining('Raise to 560'), findsOneWidget);
    await tester.tap(find.textContaining('Raise to 560'));
    await settle(tester); // the tap patches weeklyTarget (drift write) on the real loop
    final s = await readFuture(tester, () => repo.getSettings());
    expect(s.weeklyTarget, 560);
  });
}
