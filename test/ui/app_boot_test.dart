import 'package:flutter_test/flutter_test.dart';
import 'harness.dart';

void main() {
  testWidgets('boots to Today when onboarded', (tester) async {
    await pumpApp(tester);
    expect(find.text('Today'), findsWidgets); // nav destination + placeholder
  });

  testWidgets('boots to onboarding on first run', (tester) async {
    await pumpApp(tester, onboarded: false);
    expect(find.textContaining('Onboarding'), findsOneWidget);
  });
}
