import 'dates.dart';

enum DayStatus { hit, partial, missed, rest, pending, future, preInstall }

/// Calendar day state per the spec's "Calendar day states" table.
/// Precedence: preInstall > rest (incl. target-0) > future > hit > pending(today) > partial > missed.
DayStatus dayStatus({
  required LocalDate date,
  required LocalDate today,
  required LocalDate installDate,
  required int logged,
  required int target,
  required bool rest,
}) {
  if (date.isBefore(installDate)) return DayStatus.preInstall;
  if (rest || target == 0) return DayStatus.rest;
  if (date.isAfter(today)) return DayStatus.future;
  if (logged >= target) return DayStatus.hit;
  if (date == today) return DayStatus.pending;
  if (logged > 0) return DayStatus.partial;
  return DayStatus.missed;
}

/// Whether a day can be opened for logging/editing from the week strip or the
/// calendar. Editable = from the install *week* onward and not in the future.
/// This lets you back-fill the week you joined (days earlier that week are
/// pre-install but still editable) while earlier weeks stay locked — keeping
/// the install date a hard boundary for the streak and summaries.
bool isDayEditable({
  required LocalDate date,
  required LocalDate today,
  required LocalDate installDate,
}) =>
    !date.isAfter(today) && !date.isBefore(installDate.weekStart);
