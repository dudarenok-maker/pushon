import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'harness.dart';

void main() {
  // Install on MONDAY of the test week: with the harness default
  // (installDate == today, Sat Jul 11), every earlier day is preInstall and
  // deliberately un-openable — these tests need openable past days.
  Future<void> seedMondayInstall(repo) async {
    await repo.patchSettings({'installDate': '2026-07-06'});
    await repo.ensureWeekPlan(const LocalDate(2026, 7, 6));
  }

  testWidgets('catch-up: open a past day, add a set, total shows in the cell', (tester) async {
    await pumpApp(tester, seed: seedMondayInstall); // today = Sat 2026-07-11
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
    final (_, repo) = await pumpApp(tester, seed: seedMondayInstall);
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10')); // Friday this week
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rest / sick day'));
    await tester.pumpAndSettle();
    expect(await repo.watchRestDays(const LocalDate(2026, 7, 10), const LocalDate(2026, 7, 10)).first,
        {'2026-07-10'});
    // Rest-toggle behaviour is also covered at the data layer by
    // test/data/repository_test.dart (setRest / watchRestDays round-trip).
  },
      // Quarantined: this test hangs (drift + riverpod + flutter_test teardown
      // deadlock under closeStreamsSynchronously, only after a CupertinoPicker
      // test). Not a production bug — the app never closes the DB under a live
      // widget tree. Rest-toggle behaviour is covered at the data layer by
      // test/data/repository_test.dart. Re-enable per:
      // https://github.com/dudarenok-maker/pushon/issues/2
      skip: true);
}
