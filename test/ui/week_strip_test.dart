import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'harness.dart';

void main() {
  // Install on MONDAY so earlier weekdays this week are openable (not preInstall);
  // the harness default installs today (Sat), which would gate them off.
  Future<void> seedMondayInstall(repo) async {
    await repo.patchSettings({'installDate': '2026-07-06'});
    await repo.ensureWeekPlan(const LocalDate(2026, 7, 6));
  }

  testWidgets('tapping a past day in the Today week strip opens it for logging', (tester) async {
    final (_, repo) = await pumpApp(tester, seed: seedMondayInstall); // today = Sat 2026-07-11
    // Monday ('M') is a past, openable day this week.
    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();
    expect(find.text('2026-07-06'), findsOneWidget); // the shared day sheet is up

    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add')); // wheel default 20
    await settle(tester);

    final totals = await readStream(
        tester, repo.watchDayTotals(const LocalDate(2026, 7, 6), const LocalDate(2026, 7, 6)));
    expect(totals['2026-07-06'], 20, reason: 'the set logged against the tapped past day');
  });

  testWidgets('a pre-install day within the install week is tappable (back-fill)', (tester) async {
    // Install Thursday 2026-07-09; today Sat 07-11. Monday ('M', 07-06) is
    // before install but in the same week, so it should be editable.
    final (_, repo) = await pumpApp(tester, seed: (repo) async {
      await repo.patchSettings({'installDate': '2026-07-09'});
      await repo.ensureWeekPlan(const LocalDate(2026, 7, 6));
    });
    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();
    expect(find.text('2026-07-06'), findsOneWidget); // day sheet opened for the pre-install day
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await settle(tester);
    final totals = await readStream(
        tester, repo.watchDayTotals(const LocalDate(2026, 7, 6), const LocalDate(2026, 7, 6)));
    expect(totals['2026-07-06'], 20);
  });

  testWidgets('future days in the week strip are not tappable', (tester) async {
    await pumpApp(tester, seed: seedMondayInstall); // today = Sat; Sun is future
    // Sunday's chip exists but tapping it opens nothing (openable == false).
    await tester.tap(find.text('S').last); // the second 'S' = Sunday
    await tester.pumpAndSettle();
    expect(find.text('2026-07-12'), findsNothing); // no day sheet for the future day
  });
}
