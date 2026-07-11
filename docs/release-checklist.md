# PushOn release checklist (Google Play, manual)

One-time setup and the per-release steps to ship PushOn to the Play Store.
The app is free, local-only, and collects no data — the store answers below
reflect that.

## One-time (first release)

1. **Upload keystore** — generate it locally (never commit it; `*.jks` and
   `key.properties` are git-ignored):
   ```
   keytool -genkey -v -keystore android/upload-keystore.jks -storetype JKS \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Then copy `android/key.properties.example` to `android/key.properties` and
   fill in the passwords / alias / `storeFile=../upload-keystore.jks`.
2. **Create the app** in the Play Console: name **PushOn**, free, not an ad
   app.
3. **Data safety form**: "No data collected", "No data shared". PushOn makes
   no network requests.
4. **Content rating** questionnaire: category Health & Fitness; no user-
   generated content, no ads, no in-app purchases → expect "Everyone".
5. **Privacy policy URL**:
   `https://github.com/dudarenok-maker/pushon/blob/main/docs/privacy-policy.md`
6. **Store listing**: short description = the tagline
   *"The push-up habit that sticks."*; full description of the weekly-target /
   streak / reminder loop; feature graphic + phone screenshots captured on a
   real device (Today, Calendar, Weekly summary, Settings).

## Each release

1. Bump `version:` in `pubspec.yaml` if the marketing version changed
   (the `versionCode` is set automatically by the build script).
2. Build the signed AAB:
   ```
   node scripts/build-release.mjs
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`. Confirm the
   build log reports signing with the **upload** key, not debug.
3. Upload the AAB to a testing track (internal → closed) first; smoke-test on
   a device (log a set, check a reminder fires, calendar/summary render).
4. Promote to production and roll out.

## Notes

- `versionCode` = minutes since epoch (strictly increasing), so every build
  is a higher code than the last without manual bookkeeping.
- Play App Signing may re-sign with a Google-managed key; the upload key
  above is only your upload credential — keep it and its passwords safe.
