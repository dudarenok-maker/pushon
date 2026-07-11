import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'package:pushon/domain/distribution.dart';
import 'harness.dart';

// The harness week is Sat 2026-07-11 (weekStart Mon 07-06); the peak (Saturday)
// target is seeded per week, so derive it rather than hard-coding a number.
final _peak = distributeWeek(
    weeklyTarget: 500, easyDay: 1, peakDay: 5,
    weekSeed: const LocalDate(2026, 7, 6).epochDay ~/ 7)[5];

void main() {
  testWidgets('logging via the wheel updates ring total, best set, and list', (tester) async {
    await pumpApp(tester);
    expect(find.text('0 / $_peak'), findsOneWidget); // Saturday = peak day
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    // wheel defaults to 20 -> confirm
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('20 / $_peak'), findsOneWidget);
    expect(find.textContaining('Best set: 20'), findsOneWidget);
  });

  testWidgets('sets can be deleted from the list', (tester) async {
    final (_, repo) = await pumpApp(tester);
    await repo.logSet(date: const LocalDate(2026, 7, 11), count: 25, now: DateTime(2026, 7, 11, 8));
    await tester.pumpAndSettle();
    expect(find.text('25 / $_peak'), findsOneWidget);
    await tester.longPress(find.text('25 reps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('0 / $_peak'), findsOneWidget);
  });

  testWidgets('on-track line shows when behind for the week', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('to stay on track'), findsOneWidget);
  });

  testWidgets('on-track line hides once the weekly target is met', (tester) async {
    final (_, repo) = await pumpApp(tester);
    // Log the whole 500 weekly target in one set — nothing left to catch up on.
    await repo.logSet(date: const LocalDate(2026, 7, 11), count: 500, now: DateTime(2026, 7, 11, 8));
    await tester.pumpAndSettle();
    expect(find.textContaining('to stay on track'), findsNothing);
  });
}
