# Khatu Shyam Baba — Flutter app

Hindi-first Flutter client (Android + iOS) for the Khatu Shyam Baba experience.

## Stack

- Flutter + Riverpod + go_router
- Firebase Authentication (Google Sign-In required)
- Firebase Cloud Messaging
- Dio API client attaching `Authorization: Bearer <Firebase ID token>`
- Razorpay monthly subscription (via Node backend) gates all features except **Story** and **Chamatkar**
- No shop

## Brand colors

| Token | Hex |
|-------|-----|
| Saffron | `#C45C26` |
| Sacred red | `#8B1E1E` |
| Marigold | `#E8A317` |
| Indigo | `#1A2744` |
| Paper | `#FFF8F0` |

## Project layout

```
lib/
  core/           theme, routing, network, config, l10n, widgets
  features/
    auth/         AuthService interface + Firebase / Fake implementations
    subscription/ entitlement model + paywall
    home/ story/ chamatkar/ premium/ shell/
```

## Required setup (do not commit secrets)

Firebase options are **not** checked in with fabricated values.

1. Create a Firebase project; enable **Authentication → Google** and **Cloud Messaging**.
2. From `frontend/`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<your-firebase-project-id>
   ```
   This generates `lib/firebase_options.dart` (gitignored if you prefer; keep out of public repos if it embeds restricted keys).
3. Android: add `google-services.json` under `android/app/` (FlutterFire usually does this).
4. iOS: add `GoogleService-Info.plist`; configure URL schemes for Google Sign-In in Xcode.
5. Pass runtime flags when Firebase is ready:
   ```bash
   flutter run --dart-define=FIREBASE_CONFIGURED=true --dart-define=API_BASE_URL=http://10.0.2.2:4000
   ```
   Use your deployed API origin instead of the emulator default when testing against AWS.
6. Wire `main.dart` to:
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```
7. Backend (`../backend`) already exposes (verify Firebase ID tokens in production):
   - `GET /v1/entitlement`
   - `POST /v1/subscriptions/razorpay/monthly`
   - default local port `4000`
8. Google Cloud / Firebase: add SHA-1 for Android debug/release; create OAuth client IDs.

Until `FIREBASE_CONFIGURED=true`, the app uses **FakeAuthService** so UI and tests run without live Firebase.

## Local run (with backend)

Terminal 1 — API (fake Google auth):
```bash
cd backend
npm run local
# http://127.0.0.1:4000
```

Terminal 2 — Flutter pointed at that API:

**Android emulator**
```bash
cd frontend
flutter run \
  --dart-define=USE_BACKEND_API=true \
  --dart-define=API_BASE_URL=http://10.0.2.2:4000
```

**iOS simulator**
```bash
cd frontend
flutter run \
  --dart-define=USE_BACKEND_API=true \
  --dart-define=API_BASE_URL=http://127.0.0.1:4000
```

**Physical phone** (same Wi‑Fi; replace with your Mac IP):
```bash
flutter run \
  --dart-define=USE_BACKEND_API=true \
  --dart-define=API_BASE_URL=http://192.168.0.100:4000
```

`USE_BACKEND_API` defaults to **true** (wallpapers/ringtones/story/chamatkar/live/entitlement hit the API). FakeAuth sign-in sends `Bearer premium` to match `npm run local`. Pass `--dart-define=USE_BACKEND_API=false` only for pure offline UI mocks.

Real Firebase Google Sign-In:
```bash
flutter run \
  --dart-define=FIREBASE_CONFIGURED=true \
  --dart-define=USE_BACKEND_API=true \
  --dart-define=API_BASE_URL=http://10.0.2.2:4000
```

Default locale is **Hindi** (`hi`) with English (`en`) available via Flutter localization.

## Tests (no live Firebase)

```bash
flutter test
flutter analyze
dart format .
```

## Tier-2/3 India notes

- Large tap targets (52dp primary buttons)
- High-contrast saffron/indigo on paper backgrounds
- Devanagari-capable typography (Noto Sans Devanagari via google_fonts when online)
- Prefer small downloads; feature modules load behind subscription checks

## Platform minimums

- Android `minSdk` 23 (Firebase)
- iOS deployment target 13.0 (Firebase / Google Sign-In)
