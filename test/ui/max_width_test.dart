import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/ui/theme.dart';
import 'package:pushon/ui/widgets/max_width.dart';
import 'harness.dart';

Widget _probe() => const SizedBox(width: double.infinity, height: 80, key: Key('probe'));

void main() {
  testWidgets('caps a full-width child at kContentMaxWidth on a large screen', (tester) async {
    tester.view.physicalSize = const Size(2000, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MaxWidthBody(child: _probe()))));
    expect(tester.getSize(find.byKey(const Key('probe'))).width, kContentMaxWidth);
  });

  testWidgets('leaves a narrow (phone) screen unconstrained', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MaxWidthBody(child: _probe()))));
    expect(tester.getSize(find.byKey(const Key('probe'))).width, 400);
  });

  testWidgets("Today's Log button never exceeds the content max width", (tester) async {
    await pumpApp(tester); // default 800px surface — wider than the 500 cap
    final w = tester.getSize(find.widgetWithText(FilledButton, 'Log')).width;
    expect(w, lessThanOrEqualTo(kContentMaxWidth));
  });
}
