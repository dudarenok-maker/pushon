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
    await settle(tester);
    expect(fake.applied, isNotEmpty, reason: 'initial sync on boot');
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add')); // logs 20 of Saturday's 100
    await settle(tester);
    expect(fake.applied.last.map((n) => n.kind),
        containsAll([PlannedKind.inactivityNudge, PlannedKind.eveningReminder]));
    expect(fake.applied.last.singleWhere((n) => n.kind == PlannedKind.eveningReminder).body,
        contains('80'));
  });
}
