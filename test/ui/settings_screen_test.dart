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
    await tester.tap(find.text('Add')); // wheel confirm, unchanged default = current 500
    await tester.pumpAndSettle();
    await settle(tester); // drain the patchSettings write before reading it back
    expect((await readFuture(tester, () => repo.getSettings())).weeklyTarget, 500);
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
