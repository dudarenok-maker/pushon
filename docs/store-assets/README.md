# Store assets

Permanent home for PushOn's Google Play listing assets and copy, so a release
never depends on regenerating them.

## Files

| Asset | File | Spec |
| --- | --- | --- |
| Feature graphic | `feature-graphic.png` | 1024×500 PNG |
| Phone screenshots | `screenshots/01-today.png` … `04-settings.png` | 1764×3136 PNG (9:16, under Play's 2:1 cap) |

Screenshots are captured from a **release** build (no debug banner) and framed
on the brand sunshine. Upload order: Today → Calendar → Summary → Settings.
The app icon comes from `assets/brand/icon-1024.png` (use 512×512 for Play).

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
