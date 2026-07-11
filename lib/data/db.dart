import 'package:drift/drift.dart';

part 'db.g.dart';

// @DataClassName is REQUIRED on Sets: drift's default row-class name would
// be `Set`, which shadows dart:core's Set inside this library (db.g.dart is
// a part of this file) and breaks compilation. WeekPlans gets one too so the
// repository's `WeekPlansData` references resolve.
@DataClassName('SetsData')
class Sets extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()(); // LocalDate.iso — the day the set counts toward
  IntColumn get count => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WeekPlansData')
class WeekPlans extends Table {
  TextColumn get weekStart => text()(); // Monday, LocalDate.iso
  IntColumn get weeklyTarget => integer()();
  TextColumn get targetsCsv => text()(); // e.g. '70,40,70,75,75,100,70' Mon..Sun
  IntColumn get easyDay => integer()();
  IntColumn get peakDay => integer()();
  @override
  Set<Column> get primaryKey => {weekStart};
}

class DayFlags extends Table {
  TextColumn get date => text()();
  BoolColumn get rest => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {date};
}

class SettingsKv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Sets, WeekPlans, DayFlags, SettingsKv])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
