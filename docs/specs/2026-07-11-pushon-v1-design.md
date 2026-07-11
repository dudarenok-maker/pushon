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

Given weekly target `W` (multiple of 5), easy day `E`, peak day `P`
(settings validation enforces `E ≠ P`):

1. `round5(x) = 5 · round(x / 5)`, ties rounding up. Used everywhere below.
2. `base = round5(W / 7)`.
3. `easy = round5(0.6 · base)`, `peak = round5(1.4 · base)`.
4. Each of the other five days gets `d = round5((W − easy − peak) / 5)`.
5. **Adjustment pass** (the remainder after rounding, always a multiple of
   5, possibly negative): walk the five normal days in order of proximity
   *before* the peak day, wrapping past the week start to the days after
   it. While the sum is short of `W`, add 5 per visit; while over, subtract
   5 per visit in the reverse order, skipping days at 0. If the normal days
   can't absorb it (tiny `W`), adjust peak, then easy, last.
6. **Hard invariant:** all seven values are multiples of 5, ≥0, and sum
   exactly to `W`. Soft goals (hold whenever `W` permits): peak is the
   largest day, easy the smallest.
7. **Per-week variation.** So consecutive weeks don't look identical, the
   five normal days are shuffled by a per-week seed (`weekStart` epoch-week
   index): a walk of sum-preserving ±5 transfers between two normal days,
   each accepted only if both stay inside a moderate band
   `[max(easy+5, base−15, 0) … min(peak−5, base+15)]`. Because every transfer
   conserves the sum and the band sits strictly between the anchors, the hard
   invariant and both soft goals are preserved for *any* seed; the easy and
   peak day values themselves never move. The band is deliberately narrow of
   the anchors (`easy+5 … peak−5`), so the easy day stays uniquely smallest
   and the peak day uniquely largest. Degenerate targets that squeeze the band
   shut (tiny `W`) fall back to the reference split untouched. The variation is
   **deterministic in the seed**, so the calendar's preview of a future week
   matches the plan eventually stored for it. `seed == 0` is the unshuffled
   reference.

Worked example (the `seed == 0` **reference**), `W=500`, easy Tue, peak Sat —
*the canonical unit-test fixture*:
`Mon 70 · Tue 40 · Wed 70 · Thu 75 · Fri 75 · Sat 100 · Sun 70`
(base 70, easy 40, peak 100, five days at 70, +5 to Fri and Thu). Real weeks
carry a non-zero seed, so their five normal days land elsewhere in the band —
e.g. `Mon 80 · Wed 65 · Thu 75 · Fri 70 · Sun 70` — with Tue/Sat unchanged.

Rules around it:

- **Plans are stored, never recomputed.** A `week_plans` row is written the
  first time a week is *touched* (opened in the app, or logged into via
  catch-up), using the settings current at that moment, and never mutates.
  Settings changes take effect the following Monday (the UI says so) — the
  one exception is first-run onboarding, below.
- Tiny targets (`W < 35`): some days get 0 — rendered and treated exactly
  like rest days (no nudges, neutral calendar, streak-transparent).
- Weeks start Monday everywhere: calendar, summary, streak math.
- **"On track" line** (informational only):
  `X = max(0, W − logged − Σ targets of this week's rest-flagged days) ÷
  (remaining non-rest days)`. A rest day's own target is **written off, not
  redistributed** onto the remaining days: with 180 logged on Thursday,
  flagging Friday (75) shows ⌈245/3⌉ = 82, not ⌈320/3⌉ = 107. Resting can
  shift X by the rounding effect of having fewer days (80 → 82 here), but
  never dumps the flagged day's burden on you. Hidden when no non-rest days
  remain.

## First run and precise semantics

- **First run (mid-week install):** onboarding asks for the weekly target
  (default 500) and rhythm, then writes the *current* week's plan
  immediately — the only time a plan takes effect before a Monday. Days
  before the install date are **neutral**: not "missed", excluded from the
  on-track denominator, transparent to the streak.
- **Streak** (testable definition): count consecutive calendar days ending
  at yesterday where each day has ≥1 set logged, treating rest days,
  target-0 days, and pre-install days as transparent (skipped, never
  breaking). An unlogged *today* is pending — it extends the streak the
  moment a set is logged, and only breaks it once the day ends. The streak
  is derived from `sets` rows with no lookback cap, so a catch-up log heals
  it retroactively.
- **Calendar day states:** `hit` = logged ≥ target · `partial` =
  0 < logged < target · `missed` = past day, logged 0 · `rest` = flagged
  (grey, regardless of logging) · `today` = pending style until hit ·
  `future` = outlined with target.
- **Returning after weeks away:** the takeover summary shows the most
  recent *completed* week only — summaries never queue up. Untouched gap
  weeks get their plan backfilled from current settings when first viewed.

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

**Reliability posture (accepted trade-off):** v1 accepts *best-effort*
delivery — under Doze, inexact alarms batch to maintenance windows, so the
20:00 reminder may drift by minutes and the 4h nudge is approximate; no
exact alarms, no foreground service. Mitigations: after the first
successful log, the app offers the battery-optimization exemption
("reminders work best if Android doesn't put PushOn to sleep" →
`ignoreBatteryOptimizations` prompt), and Settings carries a "Reminders
not showing up?" row that re-offers it — aimed squarely at OEM battery
killers (Samsung/Xiaomi/etc.). If real-world use shows best-effort isn't
enough, exact alarms are the designated v1.x escalation path.

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
