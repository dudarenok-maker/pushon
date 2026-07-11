# Contributing to PushOn

Thanks for your interest! PushOn is a small, deliberately-scoped v1 — please
open an issue before starting non-trivial work so we can agree it fits.

## Dev setup

Requires the latest stable Flutter (Dart 3).

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen
flutter run
```

## Tests

```sh
flutter analyze     # must stay clean
flutter test        # full suite
```

- New behaviour ships with a paired test in the same PR.
- Bug fixes ship with a regression test that fails before the fix.
- `lib/domain/` changes always get unit tests — invariants across many inputs,
  not single examples.

## Where the rules live

All product invariants (weekly-plan maths, streak semantics, on-track line,
summary rules) live in `lib/domain/` as pure Dart with **zero Flutter imports**,
enforced by tests. The design of record is
[`docs/specs/2026-07-11-pushon-v1-design.md`](docs/specs/2026-07-11-pushon-v1-design.md) —
read it before changing behaviour.

## Commits & PRs

- Conventional-commit subjects: `<type>: <subject>`, where `<type>` is one of
  `feat | fix | refactor | test | docs | chore | build | ci`.
- Branch off `main` (`<type>/<slug>`), open a PR, and merge once CI
  (analyze + test + build) is green.
- Keep changes surgical: every changed line should trace to the task. No
  keystores, keys, or local config in the repo — it's public.
