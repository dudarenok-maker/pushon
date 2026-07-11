import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/domain/dates.dart';
import 'package:pushon/state/providers.dart';
import 'package:pushon/ui/day_rollover.dart';

void main() {
  // A mutable clock the scope and todayProvider both read through clockProvider.
  late DateTime now;

  Future<List<LocalDate>> pumpScope(WidgetTester tester) async {
    final seen = <LocalDate>[];
    await tester.pumpWidget(ProviderScope(
      overrides: [clockProvider.overrideWithValue(() => now)],
      child: DayRolloverScope(
        child: Consumer(builder: (_, ref, _) {
          seen.add(ref.watch(todayProvider));
          return const SizedBox();
        }),
      ),
    ));
    return seen;
  }

  testWidgets('midnight timer refreshes today while foregrounded', (tester) async {
    now = DateTime(2026, 7, 11, 23, 59); // Saturday, a minute before midnight
    final seen = await pumpScope(tester);
    expect(seen.last, const LocalDate(2026, 7, 11));

    // Clock rolls over; the ~1-minute midnight timer should fire and refresh.
    now = DateTime(2026, 7, 12, 0, 0, 30);
    await tester.pump(const Duration(minutes: 2));
    expect(seen.last, const LocalDate(2026, 7, 12),
        reason: 'today must roll to Sunday without a cold start; saw $seen');

    await tester.pumpWidget(const SizedBox()); // dispose → cancel the timer
  });

  testWidgets('warm resume refreshes today', (tester) async {
    now = DateTime(2026, 7, 11, 9);
    final seen = await pumpScope(tester);
    expect(seen.last, const LocalDate(2026, 7, 11));

    // Simulate being backgrounded overnight and warm-resumed the next day.
    // AppLifecycleListener only accepts adjacent transitions, so walk the full
    // chain out to paused and back through hidden/inactive to resumed.
    now = DateTime(2026, 7, 12, 9);
    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
    expect(seen.last, const LocalDate(2026, 7, 12),
        reason: 'resume must refresh today; saw $seen');

    await tester.pumpWidget(const SizedBox()); // dispose → cancel the timer
  });
}
