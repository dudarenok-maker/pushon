# Project context for Claude Code

PushOn — a free, open-source push-up logging app. Flutter (latest stable) +
Dart 3, Material 3, Riverpod, drift (SQLite), flutter_local_notifications,
go_router. Android first, iOS later from the same codebase. Local-only data
in v1; the data model is deliberately sync-ready (UUIDs, soft deletes,
timestamps) so health-platform export can be added without a migration.

Design of record: `docs/specs/` (dated design docs). The v1 design doc is the
source of truth for scope and behaviour — read it before changing either.

## Product invariants (do not break)

- **Weekly plan**: daily targets are multiples of 5 (≥0) and sum exactly to
  the weekly target. Easy day and peak day exist every week (defaults:
  Tuesday easy, Saturday peak). Weeks start Monday. The five normal days vary
  week to week (seeded by the week), but the easy day stays the smallest and
  the peak day the largest — variation never touches the anchors or the sum,
  and is deterministic per week so calendar previews match stored plans.
- **Plans are stored, never recomputed**: `week_plans` rows are written when
  a week begins and never mutate; settings changes take effect next Monday.
- **Daily targets never change mid-week.** Catch-up math ("to stay on track:
  X/day") is informational only.
- **Each logged entry = one set.** Day totals, best set, streak, and all
  stats are derived from `sets` rows — never stored.
- **Rest/sick days** silence nudges, show neutral in the calendar, and
  pause (never break) the streak.
- **Target suggestions go upward only**, and only after 3 consecutive weeks
  at/above target averaging ≥110%.

## Working principles

- **Think before coding.** State assumptions; if multiple interpretations
  exist, present them — don't pick silently. Push back when a simpler
  approach exists.
- **Simplicity first.** Minimum code that solves the problem. No speculative
  features, abstractions, or configurability. The v1 surface area is final —
  new features go to an issue, not into the diff.
- **Surgical changes.** Touch only what the task needs; match existing
  style; clean up only your own mess. Every changed line traces to the
  request.
- **Goal-driven execution.** Turn vague tasks into verifiable goals with a
  check per step (usually a test).

## Layout

- `lib/domain/` — pure Dart: distribution algorithm, streak math, summary
  rules. **Zero Flutter imports** — this rule is load-bearing (testability +
  iOS reuse). All product invariants above live here, enforced by tests.
- `lib/data/` — drift database, repositories, notification scheduler.
- `lib/ui/` — the four screens (Today, Calendar, Weekly summary, Settings)
  and shared widgets.
- `test/` mirrors `lib/`.

## Commands

- `flutter run` — run on a connected device/emulator.
- `flutter analyze` — static analysis; must stay clean.
- `flutter test` — full test suite.
- `flutter build apk --release` — release build (signing via `key.properties`,
  git-ignored).

## Testing discipline (REQUIRED for every change)

- New behaviour → paired test in the same PR. Bug fix → regression test that
  fails before the fix. Refactor → existing tests stay green.
- `lib/domain/` changes always get unit tests (invariants across many
  inputs, not single examples).
- UI flows that cross logging/derivation seams get widget tests.
- Never delete or skip a test without a replacement or a linked issue.

## Workflow

- Non-trivial work: cut a branch off `main`
  (`<type>/<slug>`, e.g. `feat/calendar-rest-flag`), open a PR, merge when
  CI (analyze + test + build) is green. Conventional-commit subjects:
  `<type>: <subject>` with types `feat|fix|refactor|test|docs|chore|build|ci`.
- Trivial fixes (typo, one-liner) may go straight to `main` — say so in the
  summary.
- Latest stable versions of Flutter/Dart/packages; pin them and keep them
  current — no drifting into tech debt.
- Keys, keystores, and local config are git-ignored; nothing secret in the
  repo — it's public.

## Out of scope until told otherwise

Accounts/cloud, health-platform sync (v2 — keep the door open, don't build
it), social features, other exercises, camera/proximity rep counting,
gamification beyond the streak, paid anything.
