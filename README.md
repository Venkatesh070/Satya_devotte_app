# satya_devotte_app

A new Flutter project.

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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
