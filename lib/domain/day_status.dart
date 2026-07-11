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
