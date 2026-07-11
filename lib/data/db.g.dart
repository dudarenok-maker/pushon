// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $SetsTable extends Sets with TableInfo<$SetsTable, SetsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    count,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetsData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SetsTable createAlias(String alias) {
    return $SetsTable(attachedDatabase, alias);
  }
}

class SetsData extends DataClass implements Insertable<SetsData> {
  final String id;
  final String date;
  final int count;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const SetsData({
    required this.id,
    required this.date,
    required this.count,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['count'] = Variable<int>(count);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SetsCompanion toCompanion(bool nullToAbsent) {
    return SetsCompanion(
      id: Value(id),
      date: Value(date),
      count: Value(count),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SetsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetsData(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      count: serializer.fromJson<int>(json['count']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'count': serializer.toJson<int>(count),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SetsData copyWith({
    String? id,
    String? date,
    int? count,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SetsData(
    id: id ?? this.id,
    date: date ?? this.date,
    count: count ?? this.count,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SetsData copyWithCompanion(SetsCompanion data) {
    return SetsData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      count: data.count.present ? data.count.value : this.count,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetsData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('count: $count, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, count, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetsData &&
          other.id == this.id &&
          other.date == this.date &&
          other.count == this.count &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SetsCompanion extends UpdateCompanion<SetsData> {
  final Value<String> id;
  final Value<String> date;
  final Value<int> count;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SetsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.count = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetsCompanion.insert({
    required String id,
    required String date,
    required int count,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       count = Value(count),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SetsData> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<int>? count,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (count != null) 'count': count,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetsCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<int>? count,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SetsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      count: count ?? this.count,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('count: $count, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeekPlansTable extends WeekPlans
    with TableInfo<$WeekPlansTable, WeekPlansData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeekPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weeklyTargetMeta = const VerificationMeta(
    'weeklyTarget',
  );
  @override
  late final GeneratedColumn<int> weeklyTarget = GeneratedColumn<int>(
    'weekly_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetsCsvMeta = const VerificationMeta(
    'targetsCsv',
  );
  @override
  late final GeneratedColumn<String> targetsCsv = GeneratedColumn<String>(
    'targets_csv',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _easyDayMeta = const VerificationMeta(
    'easyDay',
  );
  @override
  late final GeneratedColumn<int> easyDay = GeneratedColumn<int>(
    'easy_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peakDayMeta = const VerificationMeta(
    'peakDay',
  );
  @override
  late final GeneratedColumn<int> peakDay = GeneratedColumn<int>(
    'peak_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    weekStart,
    weeklyTarget,
    targetsCsv,
    easyDay,
    peakDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'week_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeekPlansData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('weekly_target')) {
      context.handle(
        _weeklyTargetMeta,
        weeklyTarget.isAcceptableOrUnknown(
          data['weekly_target']!,
          _weeklyTargetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weeklyTargetMeta);
    }
    if (data.containsKey('targets_csv')) {
      context.handle(
        _targetsCsvMeta,
        targetsCsv.isAcceptableOrUnknown(data['targets_csv']!, _targetsCsvMeta),
      );
    } else if (isInserting) {
      context.missing(_targetsCsvMeta);
    }
    if (data.containsKey('easy_day')) {
      context.handle(
        _easyDayMeta,
        easyDay.isAcceptableOrUnknown(data['easy_day']!, _easyDayMeta),
      );
    } else if (isInserting) {
      context.missing(_easyDayMeta);
    }
    if (data.containsKey('peak_day')) {
      context.handle(
        _peakDayMeta,
        peakDay.isAcceptableOrUnknown(data['peak_day']!, _peakDayMeta),
      );
    } else if (isInserting) {
      context.missing(_peakDayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {weekStart};
  @override
  WeekPlansData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeekPlansData(
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_start'],
      )!,
      weeklyTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekly_target'],
      )!,
      targetsCsv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}targets_csv'],
      )!,
      easyDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}easy_day'],
      )!,
      peakDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peak_day'],
      )!,
    );
  }

  @override
  $WeekPlansTable createAlias(String alias) {
    return $WeekPlansTable(attachedDatabase, alias);
  }
}

class WeekPlansData extends DataClass implements Insertable<WeekPlansData> {
  final String weekStart;
  final int weeklyTarget;
  final String targetsCsv;
  final int easyDay;
  final int peakDay;
  const WeekPlansData({
    required this.weekStart,
    required this.weeklyTarget,
    required this.targetsCsv,
    required this.easyDay,
    required this.peakDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['week_start'] = Variable<String>(weekStart);
    map['weekly_target'] = Variable<int>(weeklyTarget);
    map['targets_csv'] = Variable<String>(targetsCsv);
    map['easy_day'] = Variable<int>(easyDay);
    map['peak_day'] = Variable<int>(peakDay);
    return map;
  }

  WeekPlansCompanion toCompanion(bool nullToAbsent) {
    return WeekPlansCompanion(
      weekStart: Value(weekStart),
      weeklyTarget: Value(weeklyTarget),
      targetsCsv: Value(targetsCsv),
      easyDay: Value(easyDay),
      peakDay: Value(peakDay),
    );
  }

  factory WeekPlansData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeekPlansData(
      weekStart: serializer.fromJson<String>(json['weekStart']),
      weeklyTarget: serializer.fromJson<int>(json['weeklyTarget']),
      targetsCsv: serializer.fromJson<String>(json['targetsCsv']),
      easyDay: serializer.fromJson<int>(json['easyDay']),
      peakDay: serializer.fromJson<int>(json['peakDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'weekStart': serializer.toJson<String>(weekStart),
      'weeklyTarget': serializer.toJson<int>(weeklyTarget),
      'targetsCsv': serializer.toJson<String>(targetsCsv),
      'easyDay': serializer.toJson<int>(easyDay),
      'peakDay': serializer.toJson<int>(peakDay),
    };
  }

  WeekPlansData copyWith({
    String? weekStart,
    int? weeklyTarget,
    String? targetsCsv,
    int? easyDay,
    int? peakDay,
  }) => WeekPlansData(
    weekStart: weekStart ?? this.weekStart,
    weeklyTarget: weeklyTarget ?? this.weeklyTarget,
    targetsCsv: targetsCsv ?? this.targetsCsv,
    easyDay: easyDay ?? this.easyDay,
    peakDay: peakDay ?? this.peakDay,
  );
  WeekPlansData copyWithCompanion(WeekPlansCompanion data) {
    return WeekPlansData(
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      weeklyTarget: data.weeklyTarget.present
          ? data.weeklyTarget.value
          : this.weeklyTarget,
      targetsCsv: data.targetsCsv.present
          ? data.targetsCsv.value
          : this.targetsCsv,
      easyDay: data.easyDay.present ? data.easyDay.value : this.easyDay,
      peakDay: data.peakDay.present ? data.peakDay.value : this.peakDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeekPlansData(')
          ..write('weekStart: $weekStart, ')
          ..write('weeklyTarget: $weeklyTarget, ')
          ..write('targetsCsv: $targetsCsv, ')
          ..write('easyDay: $easyDay, ')
          ..write('peakDay: $peakDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(weekStart, weeklyTarget, targetsCsv, easyDay, peakDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeekPlansData &&
          other.weekStart == this.weekStart &&
          other.weeklyTarget == this.weeklyTarget &&
          other.targetsCsv == this.targetsCsv &&
          other.easyDay == this.easyDay &&
          other.peakDay == this.peakDay);
}

class WeekPlansCompanion extends UpdateCompanion<WeekPlansData> {
  final Value<String> weekStart;
  final Value<int> weeklyTarget;
  final Value<String> targetsCsv;
  final Value<int> easyDay;
  final Value<int> peakDay;
  final Value<int> rowid;
  const WeekPlansCompanion({
    this.weekStart = const Value.absent(),
    this.weeklyTarget = const Value.absent(),
    this.targetsCsv = const Value.absent(),
    this.easyDay = const Value.absent(),
    this.peakDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeekPlansCompanion.insert({
    required String weekStart,
    required int weeklyTarget,
    required String targetsCsv,
    required int easyDay,
    required int peakDay,
    this.rowid = const Value.absent(),
  }) : weekStart = Value(weekStart),
       weeklyTarget = Value(weeklyTarget),
       targetsCsv = Value(targetsCsv),
       easyDay = Value(easyDay),
       peakDay = Value(peakDay);
  static Insertable<WeekPlansData> custom({
    Expression<String>? weekStart,
    Expression<int>? weeklyTarget,
    Expression<String>? targetsCsv,
    Expression<int>? easyDay,
    Expression<int>? peakDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (weekStart != null) 'week_start': weekStart,
      if (weeklyTarget != null) 'weekly_target': weeklyTarget,
      if (targetsCsv != null) 'targets_csv': targetsCsv,
      if (easyDay != null) 'easy_day': easyDay,
      if (peakDay != null) 'peak_day': peakDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeekPlansCompanion copyWith({
    Value<String>? weekStart,
    Value<int>? weeklyTarget,
    Value<String>? targetsCsv,
    Value<int>? easyDay,
    Value<int>? peakDay,
    Value<int>? rowid,
  }) {
    return WeekPlansCompanion(
      weekStart: weekStart ?? this.weekStart,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      targetsCsv: targetsCsv ?? this.targetsCsv,
      easyDay: easyDay ?? this.easyDay,
      peakDay: peakDay ?? this.peakDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (weeklyTarget.present) {
      map['weekly_target'] = Variable<int>(weeklyTarget.value);
    }
    if (targetsCsv.present) {
      map['targets_csv'] = Variable<String>(targetsCsv.value);
    }
    if (easyDay.present) {
      map['easy_day'] = Variable<int>(easyDay.value);
    }
    if (peakDay.present) {
      map['peak_day'] = Variable<int>(peakDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeekPlansCompanion(')
          ..write('weekStart: $weekStart, ')
          ..write('weeklyTarget: $weeklyTarget, ')
          ..write('targetsCsv: $targetsCsv, ')
          ..write('easyDay: $easyDay, ')
          ..write('peakDay: $peakDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayFlagsTable extends DayFlags with TableInfo<$DayFlagsTable, DayFlag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayFlagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restMeta = const VerificationMeta('rest');
  @override
  late final GeneratedColumn<bool> rest = GeneratedColumn<bool>(
    'rest',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rest" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [date, rest];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_flags';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayFlag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('rest')) {
      context.handle(
        _restMeta,
        rest.isAcceptableOrUnknown(data['rest']!, _restMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DayFlag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayFlag(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      rest: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rest'],
      )!,
    );
  }

  @override
  $DayFlagsTable createAlias(String alias) {
    return $DayFlagsTable(attachedDatabase, alias);
  }
}

class DayFlag extends DataClass implements Insertable<DayFlag> {
  final String date;
  final bool rest;
  const DayFlag({required this.date, required this.rest});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['rest'] = Variable<bool>(rest);
    return map;
  }

  DayFlagsCompanion toCompanion(bool nullToAbsent) {
    return DayFlagsCompanion(date: Value(date), rest: Value(rest));
  }

  factory DayFlag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayFlag(
      date: serializer.fromJson<String>(json['date']),
      rest: serializer.fromJson<bool>(json['rest']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'rest': serializer.toJson<bool>(rest),
    };
  }

  DayFlag copyWith({String? date, bool? rest}) =>
      DayFlag(date: date ?? this.date, rest: rest ?? this.rest);
  DayFlag copyWithCompanion(DayFlagsCompanion data) {
    return DayFlag(
      date: data.date.present ? data.date.value : this.date,
      rest: data.rest.present ? data.rest.value : this.rest,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayFlag(')
          ..write('date: $date, ')
          ..write('rest: $rest')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, rest);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayFlag && other.date == this.date && other.rest == this.rest);
}

class DayFlagsCompanion extends UpdateCompanion<DayFlag> {
  final Value<String> date;
  final Value<bool> rest;
  final Value<int> rowid;
  const DayFlagsCompanion({
    this.date = const Value.absent(),
    this.rest = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayFlagsCompanion.insert({
    required String date,
    this.rest = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DayFlag> custom({
    Expression<String>? date,
    Expression<bool>? rest,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (rest != null) 'rest': rest,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayFlagsCompanion copyWith({
    Value<String>? date,
    Value<bool>? rest,
    Value<int>? rowid,
  }) {
    return DayFlagsCompanion(
      date: date ?? this.date,
      rest: rest ?? this.rest,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (rest.present) {
      map['rest'] = Variable<bool>(rest.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayFlagsCompanion(')
          ..write('date: $date, ')
          ..write('rest: $rest, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsKvTable extends SettingsKv
    with TableInfo<$SettingsKvTable, SettingsKvData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsKvData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsKvData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsKvData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsKvTable createAlias(String alias) {
    return $SettingsKvTable(attachedDatabase, alias);
  }
}

class SettingsKvData extends DataClass implements Insertable<SettingsKvData> {
  final String key;
  final String value;
  const SettingsKvData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsKvCompanion toCompanion(bool nullToAbsent) {
    return SettingsKvCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsKvData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsKvData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsKvData copyWith({String? key, String? value}) =>
      SettingsKvData(key: key ?? this.key, value: value ?? this.value);
  SettingsKvData copyWithCompanion(SettingsKvCompanion data) {
    return SettingsKvData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsKvData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsKvData &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsKvCompanion extends UpdateCompanion<SettingsKvData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsKvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsKvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingsKvData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsKvCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsKvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsKvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SetsTable sets = $SetsTable(this);
  late final $WeekPlansTable weekPlans = $WeekPlansTable(this);
  late final $DayFlagsTable dayFlags = $DayFlagsTable(this);
  late final $SettingsKvTable settingsKv = $SettingsKvTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sets,
    weekPlans,
    dayFlags,
    settingsKv,
  ];
}

typedef $$SetsTableCreateCompanionBuilder =
    SetsCompanion Function({
      required String id,
      required String date,
      required int count,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$SetsTableUpdateCompanionBuilder =
    SetsCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<int> count,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$SetsTableFilterComposer extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SetsTableOrderingComposer extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetsTable,
          SetsData,
          $$SetsTableFilterComposer,
          $$SetsTableOrderingComposer,
          $$SetsTableAnnotationComposer,
          $$SetsTableCreateCompanionBuilder,
          $$SetsTableUpdateCompanionBuilder,
          (SetsData, BaseReferences<_$AppDatabase, $SetsTable, SetsData>),
          SetsData,
          PrefetchHooks Function()
        > {
  $$SetsTableTableManager(_$AppDatabase db, $SetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetsCompanion(
                id: id,
                date: date,
                count: count,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required int count,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetsCompanion.insert(
                id: id,
                date: date,
                count: count,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetsTable,
      SetsData,
      $$SetsTableFilterComposer,
      $$SetsTableOrderingComposer,
      $$SetsTableAnnotationComposer,
      $$SetsTableCreateCompanionBuilder,
      $$SetsTableUpdateCompanionBuilder,
      (SetsData, BaseReferences<_$AppDatabase, $SetsTable, SetsData>),
      SetsData,
      PrefetchHooks Function()
    >;
typedef $$WeekPlansTableCreateCompanionBuilder =
    WeekPlansCompanion Function({
      required String weekStart,
      required int weeklyTarget,
      required String targetsCsv,
      required int easyDay,
      required int peakDay,
      Value<int> rowid,
    });
typedef $$WeekPlansTableUpdateCompanionBuilder =
    WeekPlansCompanion Function({
      Value<String> weekStart,
      Value<int> weeklyTarget,
      Value<String> targetsCsv,
      Value<int> easyDay,
      Value<int> peakDay,
      Value<int> rowid,
    });

class $$WeekPlansTableFilterComposer
    extends Composer<_$AppDatabase, $WeekPlansTable> {
  $$WeekPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weeklyTarget => $composableBuilder(
    column: $table.weeklyTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetsCsv => $composableBuilder(
    column: $table.targetsCsv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get easyDay => $composableBuilder(
    column: $table.easyDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peakDay => $composableBuilder(
    column: $table.peakDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeekPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $WeekPlansTable> {
  $$WeekPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weeklyTarget => $composableBuilder(
    column: $table.weeklyTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetsCsv => $composableBuilder(
    column: $table.targetsCsv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get easyDay => $composableBuilder(
    column: $table.easyDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peakDay => $composableBuilder(
    column: $table.peakDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeekPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeekPlansTable> {
  $$WeekPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<int> get weeklyTarget => $composableBuilder(
    column: $table.weeklyTarget,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetsCsv => $composableBuilder(
    column: $table.targetsCsv,
    builder: (column) => column,
  );

  GeneratedColumn<int> get easyDay =>
      $composableBuilder(column: $table.easyDay, builder: (column) => column);

  GeneratedColumn<int> get peakDay =>
      $composableBuilder(column: $table.peakDay, builder: (column) => column);
}

class $$WeekPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeekPlansTable,
          WeekPlansData,
          $$WeekPlansTableFilterComposer,
          $$WeekPlansTableOrderingComposer,
          $$WeekPlansTableAnnotationComposer,
          $$WeekPlansTableCreateCompanionBuilder,
          $$WeekPlansTableUpdateCompanionBuilder,
          (
            WeekPlansData,
            BaseReferences<_$AppDatabase, $WeekPlansTable, WeekPlansData>,
          ),
          WeekPlansData,
          PrefetchHooks Function()
        > {
  $$WeekPlansTableTableManager(_$AppDatabase db, $WeekPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeekPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeekPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeekPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> weekStart = const Value.absent(),
                Value<int> weeklyTarget = const Value.absent(),
                Value<String> targetsCsv = const Value.absent(),
                Value<int> easyDay = const Value.absent(),
                Value<int> peakDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeekPlansCompanion(
                weekStart: weekStart,
                weeklyTarget: weeklyTarget,
                targetsCsv: targetsCsv,
                easyDay: easyDay,
                peakDay: peakDay,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String weekStart,
                required int weeklyTarget,
                required String targetsCsv,
                required int easyDay,
                required int peakDay,
                Value<int> rowid = const Value.absent(),
              }) => WeekPlansCompanion.insert(
                weekStart: weekStart,
                weeklyTarget: weeklyTarget,
                targetsCsv: targetsCsv,
                easyDay: easyDay,
                peakDay: peakDay,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeekPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeekPlansTable,
      WeekPlansData,
      $$WeekPlansTableFilterComposer,
      $$WeekPlansTableOrderingComposer,
      $$WeekPlansTableAnnotationComposer,
      $$WeekPlansTableCreateCompanionBuilder,
      $$WeekPlansTableUpdateCompanionBuilder,
      (
        WeekPlansData,
        BaseReferences<_$AppDatabase, $WeekPlansTable, WeekPlansData>,
      ),
      WeekPlansData,
      PrefetchHooks Function()
    >;
typedef $$DayFlagsTableCreateCompanionBuilder =
    DayFlagsCompanion Function({
      required String date,
      Value<bool> rest,
      Value<int> rowid,
    });
typedef $$DayFlagsTableUpdateCompanionBuilder =
    DayFlagsCompanion Function({
      Value<String> date,
      Value<bool> rest,
      Value<int> rowid,
    });

class $$DayFlagsTableFilterComposer
    extends Composer<_$AppDatabase, $DayFlagsTable> {
  $$DayFlagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rest => $composableBuilder(
    column: $table.rest,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayFlagsTableOrderingComposer
    extends Composer<_$AppDatabase, $DayFlagsTable> {
  $$DayFlagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rest => $composableBuilder(
    column: $table.rest,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayFlagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayFlagsTable> {
  $$DayFlagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get rest =>
      $composableBuilder(column: $table.rest, builder: (column) => column);
}

class $$DayFlagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayFlagsTable,
          DayFlag,
          $$DayFlagsTableFilterComposer,
          $$DayFlagsTableOrderingComposer,
          $$DayFlagsTableAnnotationComposer,
          $$DayFlagsTableCreateCompanionBuilder,
          $$DayFlagsTableUpdateCompanionBuilder,
          (DayFlag, BaseReferences<_$AppDatabase, $DayFlagsTable, DayFlag>),
          DayFlag,
          PrefetchHooks Function()
        > {
  $$DayFlagsTableTableManager(_$AppDatabase db, $DayFlagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayFlagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayFlagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayFlagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<bool> rest = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayFlagsCompanion(date: date, rest: rest, rowid: rowid),
          createCompanionCallback:
              ({
                required String date,
                Value<bool> rest = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayFlagsCompanion.insert(
                date: date,
                rest: rest,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayFlagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayFlagsTable,
      DayFlag,
      $$DayFlagsTableFilterComposer,
      $$DayFlagsTableOrderingComposer,
      $$DayFlagsTableAnnotationComposer,
      $$DayFlagsTableCreateCompanionBuilder,
      $$DayFlagsTableUpdateCompanionBuilder,
      (DayFlag, BaseReferences<_$AppDatabase, $DayFlagsTable, DayFlag>),
      DayFlag,
      PrefetchHooks Function()
    >;
typedef $$SettingsKvTableCreateCompanionBuilder =
    SettingsKvCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsKvTableUpdateCompanionBuilder =
    SettingsKvCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsKvTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsKvTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsKvTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsKvTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsKvTable,
          SettingsKvData,
          $$SettingsKvTableFilterComposer,
          $$SettingsKvTableOrderingComposer,
          $$SettingsKvTableAnnotationComposer,
          $$SettingsKvTableCreateCompanionBuilder,
          $$SettingsKvTableUpdateCompanionBuilder,
          (
            SettingsKvData,
            BaseReferences<_$AppDatabase, $SettingsKvTable, SettingsKvData>,
          ),
          SettingsKvData,
          PrefetchHooks Function()
        > {
  $$SettingsKvTableTableManager(_$AppDatabase db, $SettingsKvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsKvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsKvCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsKvCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsKvTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsKvTable,
      SettingsKvData,
      $$SettingsKvTableFilterComposer,
      $$SettingsKvTableOrderingComposer,
      $$SettingsKvTableAnnotationComposer,
      $$SettingsKvTableCreateCompanionBuilder,
      $$SettingsKvTableUpdateCompanionBuilder,
      (
        SettingsKvData,
        BaseReferences<_$AppDatabase, $SettingsKvTable, SettingsKvData>,
      ),
      SettingsKvData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SetsTableTableManager get sets => $$SetsTableTableManager(_db, _db.sets);
  $$WeekPlansTableTableManager get weekPlans =>
      $$WeekPlansTableTableManager(_db, _db.weekPlans);
  $$DayFlagsTableTableManager get dayFlags =>
      $$DayFlagsTableTableManager(_db, _db.dayFlags);
  $$SettingsKvTableTableManager get settingsKv =>
      $$SettingsKvTableTableManager(_db, _db.settingsKv);
}
