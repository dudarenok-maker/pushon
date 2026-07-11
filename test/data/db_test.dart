import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/data/db.dart';

void main() {
  test('schema opens and round-trips a set row', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.sets).insert(SetsCompanion.insert(
      id: 'a-1', date: '2026-07-11', count: 25,
      createdAt: DateTime(2026, 7, 11, 9), updatedAt: DateTime(2026, 7, 11, 9),
    ));
    final rows = await db.select(db.sets).get();
    expect(rows.single.count, 25);
    expect(rows.single.deletedAt, isNull);
  });
}
