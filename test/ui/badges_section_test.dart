import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'harness.dart';

void main() {
  testWidgets('earning a best-set badge shows it on the Summary screen', (tester) async {
    await pumpApp(tester, seed: (repo) async {
      // A seed callback owns onboarding setup (pumpApp skips it when seeding).
      await repo.patchSettings({'installDate': '2026-07-11'});
      await repo.ensureWeekPlan(const LocalDate(2026, 7, 6));
      // A single set of 30 clears the "A set of 25" badge (bestSet track).
      await repo.logSet(date: const LocalDate(2026, 7, 11), count: 30, now: DateTime(2026, 7, 11, 9));
    });
    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();
    // The milestone stats come from a drift stream — settle on the real loop
    // until the earned badge renders (see harness.settleUntil).
    await settleUntil(tester, find.text('A set of 25'));
    expect(find.text('A set of 25'), findsOneWidget); // earned
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('A set of 50'), findsOneWidget); // shown under "Up next"
  });

  testWidgets('a brand-new account shows the empty-badges hint', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();
    await settleUntil(tester, find.text('Badges'));
    expect(find.textContaining('No badges yet'), findsOneWidget);
  });
}
