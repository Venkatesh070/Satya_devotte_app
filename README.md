# satya_devotte_app

Flutter app for Satya Devotte — daily prayers, moon phases, pujas, rituals, and Puja Kit delivery.

## CMS notifications

- **Activity** — system alerts (new orders, donations paid, refund requests) from `GET /api/v1/admin/notifications`.
- **Notifications** — manual broadcast push send/history (`POST /notifications/send`).

### Web push (admin CMS)

1. Firebase Console → **Cloud Messaging** → **Web Push certificates** → copy the **Key pair** (VAPID public key).
2. Run or build with:

```bash
flutter run -d chrome --dart-define=FIREBASE_VAPID_KEY=YOUR_VAPID_PUBLIC_KEY
```

3. Allow browser notifications when prompted after admin login.
4. `web/firebase-messaging-sw.js` must be deployed at the site root (included in `flutter build web` output).

---

## Shorebird OTA (code push)

Shorebird lets you ship Dart/Flutter **code fixes** to users already on a store build, without waiting for a full Play Store / App Store review.

| Term | Meaning |
|------|---------|
| **Release** | A full app binary built with Shorebird and uploaded to stores (and to Shorebird). Patches attach to this release. |
| **Patch** | A small Dart code update pushed over-the-air to devices that already installed that release. |
| **Track** | Channel for patches: `stable` (production) or `staging` (testing). |
| **Release version** | Must match `pubspec.yaml` `version` (e.g. `1.0.0+17` → name `1.0.0`, number `17`). |

### What Shorebird can and cannot update

**Can patch (OTA):** Dart/Flutter UI and business logic changes.

**Cannot patch (needs a new store release):**

- Native Android/iOS code changes
- New or changed assets that are not part of the Dart snapshot in some cases
- Plugin / native dependency upgrades
- App permissions, package name, signing, or store listing changes
- Bumping the store `version` / build number for a brand-new binary

Config for this app lives in [`shorebird.yaml`](shorebird.yaml) (`app_id`, auto-update enabled by default).

Official docs: [https://docs.shorebird.dev](https://docs.shorebird.dev)

---

### 0. One-time setup

1. Install the Shorebird CLI: [https://docs.shorebird.dev/getting-started/install](https://docs.shorebird.dev/getting-started/install)
2. Log in:

```bash
shorebird login
```

3. Confirm this project is linked (already has `shorebird.yaml` with `app_id`).
4. From the app root:

```bash
cd Satya_devotte_app
shorebird doctor
```

5. Keep `pubspec.yaml` `version` in sync with what you ship to stores (currently `1.0.0+17`).

---

### 1. Production flow (Android — Play Store)

#### A. Create a Shorebird release (full binary)

Bump version in `pubspec.yaml` if this is a new store upload, then:

```bash
# AAB for Play Store (default)
shorebird release android

# Or explicitly:
shorebird release android --artifact aab
```

This builds a release artifact **and** registers it with Shorebird so later patches can target it.

#### B. Upload to Play Store

Upload the generated AAB (from Shorebird / Flutter release output) to Google Play Console as usual (internal → closed → production).

#### C. Ship an OTA patch (after users have that release)

1. Make Dart/Flutter code changes.
2. Do **not** bump `version` in `pubspec.yaml` for a patch — patches must target the **same** release version users already installed.
3. Create and publish the patch:

```bash
# Patch current release for Android (stable track)
shorebird patch android

# Or pin the exact store version users have:
shorebird patch --platforms=android --release-version=1.0.0+17
```

4. Users on that release download the patch on next launch (auto-update is on in `shorebird.yaml`). A restart may be required for the new code to run.

#### D. Useful commands

```bash
shorebird releases list
shorebird patches list
```

---

### 2. Production flow (iOS — App Store)

Same idea as Android: **release** once per store binary, then **patch** that version.

```bash
# Create iOS release (IPA / archive via Shorebird)
shorebird release ios

# After users install that build from TestFlight / App Store:
shorebird patch ios

# Or pin version:
shorebird patch --platforms=ios --release-version=1.0.0+17
```

Upload the IPA / archive through Xcode or Transporter / App Store Connect as you normally would.

**Notes:**

- Apple still requires a full review for **new** binaries; OTA patches only update Dart code on devices that already have that Shorebird release.
- Use the same `version` string as in `pubspec.yaml` / App Store build number when targeting patches.

---

### 3. Patch both platforms at once

```bash
shorebird patch --platforms=android,ios --release-version=1.0.0+17
```

---

### 4. Staging / test flow (safe OTA practice)

Use **staging** so production users are not affected while you verify a patch.

#### A. Build a Shorebird release APK (Android test device)

```bash
shorebird release android --artifact apk
```

#### B. Confirm the release exists

```bash
shorebird releases list
```

#### C. Install the release on a phone

```bash
# Installs the latest release preview on a connected device
shorebird preview
```

Or install the APK manually, then open the app once so it registers with Shorebird.

#### D. Make a code change and create a **staging** patch

```bash
shorebird patch android --track=staging
# iOS:
# shorebird patch ios --track=staging
```

#### E. Preview the staging patch

```bash
shorebird preview --track=staging
```

#### F. Verify OTA behavior

1. Kill and reopen the app (or wait for update check on launch).
2. Confirm your Dart change appears without reinstalling from the store.
3. When happy, create the same change as a **stable** patch (omit `--track=staging`, or use the stable track explicitly) against the **production** release version.

---

### 5. End-to-end checklist

```text
[ ] Install CLI + shorebird login + shorebird doctor
[ ] Set pubspec version for the store binary (e.g. 1.0.0+17)
[ ] shorebird release android / ios
[ ] Upload AAB / IPA to Play Store / App Store
[ ] Wait until that build is installed by users (or your test device)
[ ] Change Dart code only
[ ] (Optional) shorebird patch … --track=staging → shorebird preview --track=staging
[ ] shorebird patch android / ios (stable) for production
[ ] Verify on a device that already has that release version
```

---

### 6. Common pitfalls

| Issue | Fix |
|-------|-----|
| Patch not applied | Device must be on the **same** release version you patched; reinstall store/preview build if unsure. |
| Wrong version | Match `--release-version` to `name+number` from `pubspec.yaml` (e.g. `1.0.0+17`). |
| Native / plugin change | Create a **new release** and upload to the store; do not rely on a patch. |
| Testing on `flutter run` | Debug/`flutter run` builds are **not** Shorebird releases — use `shorebird release` + `shorebird preview` / store build. |
| Patching after bumping version | Bumping version creates a **new** release; old patches do not apply to the new binary. |

---

### 7. Quick command reference

```bash
# Setup
shorebird login
shorebird doctor

# Releases (full binaries)
shorebird release android
shorebird release android --artifact apk
shorebird release ios
shorebird releases list

# Patches (OTA)
shorebird patch android
shorebird patch ios
shorebird patch --platforms=android --release-version=1.0.0+17
shorebird patch android --track=staging
shorebird patches list

# Device preview
shorebird preview
shorebird preview --track=staging
```

For deeper detail (flavors, CI, rollback, `shorebird_code_push`), see [Shorebird documentation](https://docs.shorebird.dev).
