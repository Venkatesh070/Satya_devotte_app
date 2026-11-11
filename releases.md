# Sathya App — Store & Shorebird Releases

## Versioning rules (important)

- **Android Play Store** uses `versionCode` (build number). It must **always increase**.
  - Example: users on `1.0.0+23` cannot receive `1.0.1+1` (build 1 &lt; 23).
  - Correct next Android upload: `1.0.1+24` or higher (e.g. `1.0.1+25`).
- **iOS App Store** update popup compares marketing version (`1.0.0` → `1.0.1`), not build.
- **Shorebird patches** target an exact release string (`name+number`), e.g. `1.0.0+32` or `1.0.1+1`. Do not bump `pubspec` version when only patching.

Current `pubspec.yaml`: `1.0.1+1` (adjust Android build before Play upload if needed).

---

## 7 Nov 2026 — Android & iOS

| Platform | Version | Notes |
|----------|---------|--------|
| Android  | `1.0.0` build **23** | Play Store release |
| iOS      | `1.0.0`              | App Store release |

---

## 9 Nov 2026 — iOS only

| Platform | Version | Notes |
|----------|---------|--------|
| iOS      | `1.0.1` | App Store release (updated app icons) |

---

## 11 Nov 2026 — Android store + iOS Shorebird patch

| Platform | Version | Notes |
|----------|---------|--------|
| Android  | `1.0.1` build **25** | Play Store release — includes global Shop restriction (GPS / SA-only) |
| iOS      | Shorebird patch on App Store `1.0.1` | Patch for Shop restriction / related Dart fixes (see Shorebird dashboard for patch #) |

### This release includes

- Global Shop restriction (Shop / cart / My Orders only when physically in South Africa via GPS)
