import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'harness.dart';

void main() {
  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
  }

  testWidgets('weekly target edits via wheel and persists', (tester) async {
    final (_, repo) = await pumpApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Weekly target'));
    await tester.pumpAndSettle();
    // Scroll the wheel off its default (500) so the assertion below can tell a
    // real write from a no-op — items are 5 apart, up = larger values.
    await tester.drag(find.byType(CupertinoPicker), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add')); // confirm the changed value
    await tester.pumpAndSettle();
    await settle(tester); // drain the patchSettings write before reading it back
    final saved = (await readFuture(tester, () => repo.getSettings())).weeklyTarget;
    expect(saved, greaterThan(500), reason: 'a wheel change must persist, not the default');
    expect(saved % 5, 0, reason: 'weekly target stays a multiple of 5');
  });

  testWidgets('easy == peak is rejected with a snackbar', (tester) async {
    final (_, repo) = await pumpApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Easy day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saturday').last); // same as default peak
    await tester.pumpAndSettle();
    expect(find.text('Easy and peak day must differ'), findsOneWidget);
    expect((await readFuture(tester, () => repo.getSettings())).easyDay, 1, reason: 'not saved');
  });
}
