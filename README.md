# Khatu Shyam Superapp

Flutter client + Node.js API for the Khatu Shyam Baba experience.

## Layout

| Path | Role |
|------|------|
| [`frontend/`](frontend/) | Flutter Android/iOS app (Hindi-first) |
| [`backend/`](backend/) | Node.js + MongoDB API on AWS |
| [`admin/`](admin/) | Web admin dashboard (content + users) |
| [`khatu-shyam-content/`](khatu-shyam-content/) | Offline S3-ready media pack |

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

1. Backend (fake Google auth):
   ```bash
   cd backend
   cp .env.example .env
   npm install
   npm run local
   ```
2. Admin dashboard:
   ```bash
   cd admin
   cp .env.example .env
   npm install
   npm run dev
   ```
   Sign in with token `admin` at http://127.0.0.1:5173
3. Frontend:
   ```bash
   cd frontend
   flutter pub get
   flutter run
   ```
4. When Firebase is configured:
   ```bash
   flutter run \
     --dart-define=FIREBASE_CONFIGURED=true \
     --dart-define=API_BASE_URL=http://10.0.2.2:4000
   ```

See [`frontend/README.md`](frontend/README.md), [`backend/README.md`](backend/README.md), and [`admin/README.md`](admin/README.md) for secrets and AWS/Firebase setup.

### Admin access

- Add admin emails to backend `ADMIN_EMAILS` (comma-separated). Admin dashboard uses Firebase email/password for those accounts.
- Those users receive `role: admin` on login and can call `/v1/admin/*`.
- Seed the content catalog from `khatu-shyam-content/metadata.json`:
  ```bash
  cd backend && npm run seed:content
  ```

## Content library

Local S3-ready media pack lives in [`khatu-shyam-content/`](khatu-shyam-content/) (wallpapers + ringtones + `metadata.json`). Binary media is gitignored; regenerate with `python3 khatu-shyam-content/scripts/seed_library.py`.
