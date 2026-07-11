# PushOn v1 — design

**Date:** 2026-07-11 · **Status:** approved design, pre-implementation

PushOn is a free, open-source push-up logging app. Android first (Flutter),
iOS later from the same codebase. Its reason to exist: annual push-up
challenges build a great habit and then abandon you — the nudges stop, the
habit dies. PushOn is the year-round version: a weekly target, sane daily
plans, frictionless logging, and reminders that keep the streak alive.

**Tagline:** *The push-up habit that sticks.*

## Product decisions (all user-approved)

| Area | Decision |
|---|---|
| Target model | Weekly target (default **500**, any multiple of 5 via settings), auto-distributed across Mon–Sun |
| Week rhythm | At least one easy day and one peak day; defaults **easy = Tuesday**, **peak = Saturday**, both changeable |
| Daily numbers | Always multiples of 5 (≥0), summing exactly to the weekly target — never an awkward 87 |
| Mid-week divergence | **Daily targets never change mid-week.** A separate, informational "to stay on track: X/day" line shows catch-up math. Sickness must never inflate targets |
| Rest/sick days | One-tap flag on any day: silences nudges, renders neutral (grey) in calendar, **pauses (never breaks) the streak**. No target-math changes |
| Logging | Open app → scrolling wheel → log. **Each entry = one set.** Entries per day are listed, editable, deletable |
| Best set | Largest single entry of the day, derived automatically; trend over time visible |
| Over-logging | Allowed and celebrated — surplus shown, still counts toward the week |
| Catch-up logging | Any past day can be opened from the calendar and logged against |
| Streak | Day streak (≥1 set logged); rest days pause it; prominent on Today screen **and weekly summary**. Critical feature |
| Weekly summary | Full-screen card on first open of a new week: totals vs target, per-day bars, best set, streak, and target suggestion |
| Target suggestions | **Upward only.** Shown only when the last 3 weeks all hit target and averaged ≥110%; suggests the 3-week average rounded down to 5. Accept or dismiss |
| Nudges | (a) inactivity nudge 4h after last set, only while today's target is unmet, within waking window (default 08:00–21:00); (b) 20:00 reminder with remaining reps if unmet. Both skipped on rest days |
| Data | **Local-only in v1.** No accounts, no cloud. Data model is deliberately sync-ready so Health Connect / HealthKit export is additive later |
| Price | Free. No payments, no ads |
| Distribution | Google Play via existing account; open-source (MIT) public repo |

## The distribution algorithm

Given weekly target `W` (multiple of 5), easy day `E`, peak day `P`:

1. `base = round5(W / 7)`
2. Easy day ≈ 60% of base, peak day ≈ 140% of base (each rounded to 5).
3. The remaining five days split `W − easy − peak` evenly in multiples of 5;
   leftover 5s are given one each to the days before the peak day.
4. **Invariant:** all seven values are multiples of 5, ≥0, and sum exactly
   to `W`.

Example, `W=500`: `Mon 70 · Tue 45 · Wed 70 · Thu 70 · Fri 75 · Sat 100 · Sun 70`.

Rules around it:

- **Plans are stored, never recomputed.** A `week_plans` row is written when
  a week first begins and never mutates. Settings changes take effect the
  following Monday (the UI says so).
- Tiny targets (`W < 35`): some days get 0, shown as built-in rest days.
- Weeks start Monday everywhere: calendar, summary, streak math.
- "On track" line = `(W − logged so far) ÷ remaining non-rest days`,
  informational only.

## Data model (drift / SQLite)

- **`sets`** — `id` (UUID), `date` (local day it counts toward), `count`,
  `created_at`, `updated_at`, `deleted_at` (soft delete). Catch-up entries
  are rows with a past `date`. UUIDs + timestamps + soft deletes make a
  future health-platform exporter idempotent.
- **`week_plans`** — `week_start`, weekly target, seven daily targets,
  easy/peak days.
- **`day_flags`** — `date`, rest flag.
- **`settings`** — key–value: target, rhythm days, notification prefs,
  quiet hours.

Everything else — day totals, best set, streak, on-track line, summary
stats — is **derived, never stored**, so a catch-up log automatically heals
the streak and every stat.

## Screens (the whole app is four)

1. **Today** (home): progress ring (logged/target), streak, best set today,
   the scrolling wheel + Log button (two interactions from app-open to
   logged), today's set list (tap to edit/delete), on-track line, Mon–Sun
   week strip.
2. **Calendar**: month grid, colour-coded per day — hit / partial / missed /
   rest (grey) / future (outlined, shows target). Tap a day → bottom sheet:
   its sets, add catch-up set, toggle rest flag.
3. **Weekly summary**: takeover card on first open of a new week, reachable
   anytime after. Totals, per-day bars, best set, streak, raise suggestion.
4. **Settings**: weekly target (wheel, steps of 5), easy/peak day pickers,
   notification toggles + quiet hours, about/licenses.

## Notifications

`flutter_local_notifications` + `timezone`, **inexact** scheduling (avoids
Android 14 exact-alarm permission). Schedules recomputed on every app open
and every log. Android 13+ runtime notification permission requested on
first run with a one-line explainer. Monday summary is in-app, not a
notification.

## Architecture & stack

Latest stable versions of everything at scaffold time, pinned and kept
current (Dependabot weekly).

- Flutter + Dart 3, Material 3, **Riverpod**, **drift**, **go_router**
  (notification taps deep-link to Today), `CupertinoPicker` for the wheel.
- `lib/domain/` — pure Dart, zero Flutter imports: distribution algorithm,
  streak math, summary/suggestion rules. All product invariants live here,
  enforced by unit tests.
- `lib/data/` — drift DB, repositories, notification scheduler.
- `lib/ui/` — four screens + shared widgets.

## Branding

- **Name:** PushOn (repo `pushon`).
- **Tagline:** *The push-up habit that sticks.*
- **Palette (Sunshine):** yellow `#FFD23F` (primary/background), navy ink
  `#1B2A4A`, coral accent `#FF5A36` (progress, hit-target moments, the "On"
  in the wordmark).
- **Icon:** minimal plank figure (dot head, straight-back body line,
  vertical arm, faint ground line) in navy on a yellow rounded tile —
  approved after size-testing at 48px. Master SVG: `assets/brand/icon.svg`.
- **Wordmark:** "Push" in navy + "On" in coral, heavy geometric sans.
- Bright, lively, simple — deliberately no further brand apparatus.

## Quality, CI, Play readiness

- Unit tests for `lib/domain/` (invariants across many inputs), widget
  tests for logging/edit flows, a smoke integration test. `flutter analyze`
  clean.
- GitHub Actions on every PR: analyze + test + debug build. Free on the
  public repo. CodeQL for Actions workflows once CI lands (Dart itself is
  unsupported); branch protection on `main` once the CI check exists.
- Security suite already enabled: Dependabot alerts + security updates +
  weekly version PRs, secret scanning with push protection, private
  vulnerability reporting.
- Release signing config from the start (new upload keystore, git-ignored),
  auto-incrementing `versionCode` (timestamp scheme), current target SDK,
  privacy policy page in the repo ("all data stays on your device").

## Roadmap after v1

1. **iOS** — same codebase; Apple dev account + TestFlight.
2. **Health sync** — `health` package exports to Health Connect / HealthKit;
   the `sets` design makes this an additive exporter.
3. Nothing else promised.

## Out of scope for v1

Accounts/cloud, health sync, social features, other exercises,
camera/proximity rep counting, gamification beyond the streak, paid
anything.
