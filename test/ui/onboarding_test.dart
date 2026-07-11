import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'harness.dart';

void main() {
  testWidgets('completing onboarding writes settings and the current week plan', (tester) async {
    final (_, repo) = await pumpApp(tester, onboarded: false);
    expect(find.text('The push-up habit that sticks.'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await settleUntil(tester, find.text('Log'));
    final s = await readFuture(tester, () => repo.getSettings());
    expect(s.installDate, const LocalDate(2026, 7, 11));
    expect(s.weeklyTarget, 500);
    final plan = await readFuture(tester, () => repo.getWeekPlan(const LocalDate(2026, 7, 6)));
    expect(plan, isNotNull, reason: 'the one pre-Monday plan write');
    expect(find.text('Log'), findsOneWidget, reason: 'landed on Today');
  });
}
