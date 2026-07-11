/// Calendar-day value type. All day identity in PushOn uses this,
/// never DateTime, so timezones and DST can't shift a day.
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.from(DateTime dt) => LocalDate(dt.year, dt.month, dt.day);

  factory LocalDate.parse(String iso) {
    final p = iso.split('-');
    return LocalDate(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  final int year;
  final int month;
  final int day;

  /// Component arithmetic via the DateTime constructor normalises
  /// month/year rolls without touching wall-clock time (DST-safe).
  LocalDate addDays(int n) {
    final d = DateTime(year, month, day + n);
    return LocalDate(d.year, d.month, d.day);
  }

  LocalDate get previous => addDays(-1);

  /// 0 = Monday … 6 = Sunday.
  int get weekdayIndex => DateTime(year, month, day).weekday - 1;

  LocalDate get weekStart => addDays(-weekdayIndex);

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  String get iso =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  int get _ordinal => year * 10000 + month * 100 + day;

  @override
  int compareTo(LocalDate other) => _ordinal - other._ordinal;

  @override
  bool operator ==(Object other) => other is LocalDate && other._ordinal == _ordinal;

  @override
  int get hashCode => _ordinal;

  @override
  String toString() => iso;
}
