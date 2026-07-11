# PushOn

**The push-up habit that sticks.**

A free, open-source push-up logging app that keeps you going year-round.

Set a weekly target, let PushOn spread it across the week (easy days, a peak
day, clean round numbers), log reps in seconds on a scrolling wheel, and get
the nudges that keep the habit alive long after the annual challenge ends.

Android first (Flutter), iOS later. Local-only data in v1, with health-platform
integration kept open for the future.

## Features

- **Weekly target, auto-distributed** across the week into round-number daily
  targets, with a configurable easy day and peak day.
- **Wheel logging** — record a set in seconds; day total, best set, and an
  informational "to stay on track" line update live.
- **Streak** that pauses (never breaks) on rest/sick days.
- **Calendar** with per-day status colours and catch-up logging for past days.
- **Weekly summary** on the first open of a new week, with an upward-only
  "raise your target" suggestion after three strong weeks.
- **Reminders** — an inactivity nudge and an evening reminder, generated
  entirely on-device.

## Build it yourself

Requires the latest stable [Flutter](https://docs.flutter.dev/get-started/install).

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates drift code
flutter run                                                 # on a device/emulator
```

Run the checks: `flutter analyze` and `flutter test`.

## Privacy

All data stays on your device. PushOn makes no network requests — nothing is
collected, transmitted, shared, or sold. See [docs/privacy-policy.md](docs/privacy-policy.md).

Releasing to Google Play: see [docs/release-checklist.md](docs/release-checklist.md).

## License

[MIT](LICENSE)
