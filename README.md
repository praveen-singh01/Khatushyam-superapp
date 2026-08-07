# Khatu Shyam Superapp

Flutter client + Node.js API for the Khatu Shyam Baba experience.

## Layout

| Path | Role |
|------|------|
| [`frontend/`](frontend/) | Flutter Android/iOS app (Hindi-first) |
| [`backend/`](backend/) | Node.js + MongoDB API on AWS |

## Product rules

- Free forever: Story video + Chamatkar community
- Everything else requires a Razorpay monthly subscription
- Auth: Firebase Google Sign-In only
- Notifications: Firebase Cloud Messaging
- Media uploads: AWS S3 (signed URLs)
- No Redis, no in-app shop

## Flutter ↔ API contract

With `API_BASE_URL=http://10.0.2.2:4000` (Android emulator default):

| Method | Path | Notes |
|--------|------|-------|
| `GET` | `/v1/health` | Public |
| `GET` | `/v1/entitlement` | Bearer Firebase ID token |
| `POST` | `/v1/subscriptions/razorpay/monthly` | Starts Razorpay subscription |
| `GET` | `/v1/content/story` | Free |
| `GET`/`POST` | `/v1/chamatkars` | Free read; write needs auth |

Equivalent `/api/v1/*` routes are also mounted.

## Local development

1. Backend:
   ```bash
   cd backend
   cp .env.example .env
   npm install
   npm run dev
   ```
2. Frontend:
   ```bash
   cd frontend
   flutter pub get
   flutter run
   ```
3. When Firebase is configured:
   ```bash
   flutter run \
     --dart-define=FIREBASE_CONFIGURED=true \
     --dart-define=API_BASE_URL=http://10.0.2.2:4000
   ```

See [`frontend/README.md`](frontend/README.md) and [`backend/README.md`](backend/README.md) for secrets and AWS/Firebase setup.
