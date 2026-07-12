# Store assets

Permanent home for PushOn's Google Play listing assets and copy, so a release
never depends on regenerating them.

## Files

| Asset | Path | Spec |
| --- | --- | --- |
| App icon | `app-icon-512.png` | 512×512 PNG (≤1 MB) |
| Feature graphic | `feature-graphic.png` | 1024×500 PNG |
| Phone screenshots | `screenshots/phone/01–04` | 1764×3136 PNG · 9:16 · 320–3840 px/side |
| 7-inch tablet | `screenshots/tablet-7in/01–04` | 2048×1152 PNG · 16:9 · 320–3840 px/side |
| 10-inch tablet | `screenshots/tablet-10in/01–04` | 2560×1440 PNG · 16:9 · ≥1080 px/side |

All screenshots are captured from a **release** build (no debug banner).
Upload order in every slot: Today → Calendar → Summary → Settings.

- **Phone** — the app screen framed on brand sunshine (portrait 9:16).
- **Tablets** — PushOn is a single-column portrait app, so the tablet slots
  use landscape marketing shots: the phone screen framed beside the wordmark
  and a per-screen caption (16:9). The 7-inch set is the 10-inch set scaled
  down.

Play needs **2–8** screenshots per slot and **at least 4** for promotion
eligibility — each slot here has four. The app icon is derived from
`assets/brand/icon-1024.png`.

## Listing copy

- **App name:** PushOn
- **Package name:** `io.github.dudarenokmaker.pushon`
- **Category:** Health & Fitness
- **Tags:** Activity tracker, Health & fitness, Workout
- **Contains ads:** No · **In-app purchases:** No
- **Data safety:** No data collected, no data shared (fully on-device, no network)
- **Content rating:** Everyone
- **Privacy policy:** https://github.com/dudarenok-maker/pushon/blob/main/docs/privacy-policy.md

**Short description** (≤80 chars)

```
The push-up habit that sticks.
```

**Full description**

```
PushOn is the simplest way to build a lasting push-up habit — free, private, and completely offline.

Set one weekly target. PushOn spreads it across the week into daily goals, with a lighter easy day and a bigger peak day built in — and it reshapes every week so no two feel the same. Log a set in two taps and watch your daily ring fill.

What you get
• Weekly target, smartly distributed — daily goals that vary week to week and always add up to your goal.
• Two-tap logging — every set counts toward your day, your week, and your streak.
• A streak that survives real life — rest and sick days pause it instead of breaking it.
• Calendar view — see every day at a glance and back-fill one you forgot.
• Weekly summary — how you did, your best set, and whether your max is trending up.
• Gentle reminders — a nudge if you've gone quiet and an evening check-in, only during your waking hours.
• Milestones & badges — lifetime reps, streaks, personal bests, and perfect weeks.
• Aim higher — after a few strong weeks, PushOn suggests a higher target (only ever upward).

Private by design
Everything stays on your device. PushOn makes no network requests — nothing is collected, shared, or sold. No account, no ads, no in-app purchases. Delete the app and all your data goes with it.

Open source
PushOn is free and open source.

Just you, the floor, and a habit that sticks.
```

See [`docs/release-checklist.md`](../release-checklist.md) for the full publish flow.
