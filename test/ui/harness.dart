import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/app.dart';
import 'package:pushon/data/db.dart';
import 'package:pushon/data/repository.dart';
import 'package:pushon/domain/dates.dart';
import 'package:pushon/state/providers.dart';

/// Pumps the full app against an in-memory database.
/// [onboarded] seeds installDate so the app lands on Today.
Future<(AppDatabase, PushOnRepository)> pumpApp(
  WidgetTester tester, {
  DateTime? now,
  bool onboarded = true,
}) async {
  final clock = now ?? DateTime(2026, 7, 11, 9); // a Saturday
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = PushOnRepository(db);
  if (onboarded) {
    await repo.patchSettings({'installDate': LocalDate.from(clock).iso});
    await repo.ensureWeekPlan(LocalDate.from(clock).weekStart);
  }
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => clock),
    ],
    child: const PushOnApp(),
  ));
  await tester.pumpAndSettle();
  return (db, repo);
}
