# Production readiness checklist

What you need to provide / set up before go-live.

## 1. Firebase (required)

- [ ] Firebase project created
- [ ] Authentication → Sign-in method → **Google** enabled
- [ ] Cloud Messaging enabled
- [ ] Service account JSON for Admin SDK (or AWS IAM workload identity + ADC)
- [ ] Android: `google-services.json`, SHA-1/SHA-256 for debug + release keystores
- [ ] iOS: `GoogleService-Info.plist`, URL schemes for Google Sign-In
- [ ] FlutterFire: run `flutterfire configure` in `frontend/`

Give the engineering team:

- Firebase project ID
- Admin credentials path / secret (never commit JSON to git)
- Android OAuth client IDs / SHA fingerprints
- iOS client ID / reversed client ID

## 2. MongoDB (required)

- [ ] MongoDB Atlas cluster (or AWS DocumentDB / self-managed) in `ap-south-1` preferred
- [ ] Database user + password
- [ ] Network access: allow AWS ECS/EC2 / NAT IPs only (not `0.0.0.0/0` in prod)

Give:

- `MONGODB_URI` connection string

## 3. Razorpay (required)

- [ ] Razorpay account (live mode when ready)
- [ ] Monthly subscription **Plan ID** created in INR
- [ ] API Key ID + Key Secret (live)
- [ ] Webhook URL pointed at `https://<api-domain>/v1/subscriptions/webhook`
- [ ] Webhook secret
- [ ] Events enabled: `subscription.activated`, `subscription.charged`, `subscription.halted`, `subscription.cancelled`

Give:

- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_PLAN_ID`
- `RAZORPAY_WEBHOOK_SECRET`
- Exact monthly price (e.g. ₹49 / ₹99)

## 4. AWS (required)

- [ ] AWS account + IAM permissions
- [ ] S3 bucket for media (private), region `ap-south-1`
- [ ] CloudFront distribution in front of S3 (public story/bhajan assets)
- [ ] ECS/Fargate (or EC2) + ALB + HTTPS certificate (ACM)
- [ ] Secrets Manager / SSM for env secrets
- [ ] Task role with `s3:PutObject` / `GetObject` on the media bucket

Give:

- AWS account ID / access for deploy role
- `S3_MEDIA_BUCKET`
- `CLOUDFRONT_BASE_URL`
- Domain name for API (e.g. `api.yourdomain.com`)

## 5. App store / legal (required before public launch)

- [ ] Google Play developer account
- [ ] Apple Developer account
- [ ] Privacy policy URL (Hindi + English)
- [ ] Terms of use
- [ ] Content licensing for bhajans, wallpapers, ringtones, story video
- [ ] Support email / WhatsApp number for Tier-2/3 users

## 6. Optional but recommended

- [ ] Sentry (or similar) DSN for API + Flutter crash reporting
- [ ] Analytics (Firebase Analytics / Mixpanel)
- [ ] Staging environment (separate Firebase + Razorpay test keys + staging Mongo)

## 7. Khoje (Story) + Samuday (Chamatkar) — product ready

These free tabs are API-backed for launch:

| Tab | Ship with | Still optional later |
|-----|-----------|----------------------|
| **खोजें / Story** | 5 Hindi/EN chapters from `GET /v1/content/story`, chapter reader UI | Admin CMS for chapters, `youtubeVideoId` when you have a video |
| **समुदाय / Chamatkar** | List + create + like toggle + share copy, cursor pagination | Comments, moderation queue, report flow |

Ops:

- [ ] Seed a few real devotee posts (or leave empty — empty state is handled)
- [ ] Set `ADMIN_EMAILS` so admins can hide abusive posts later via admin tools
- [ ] (Optional) Set `youtubeVideoId` on story JSON when intro video is ready

## 8. Flutter store build

```bash
cd frontend
flutter build appbundle \
  --dart-define=API_BASE_URL=https://api.yourdomain.com \
  --dart-define=FIREBASE_CONFIGURED=true \
  --dart-define=USE_BACKEND_API=true
```

- [ ] Release keystore + `key.properties` (Android currently signs debug for local release runs)
- [ ] Cleartext HTTP is **debug-only**; release requires HTTPS API
- [ ] Apple `DEVELOPMENT_TEAM` + App Store listing assets

## Local verification already done

```bash
cd backend
npm test          # endpoint/integration tests
npm run smoke     # hits all routes against local Mongo with fakes
npm run local     # fake-auth server on :4000 (Bearer free|premium)
```

### Endpoint matrix verified locally

| Endpoint | Result |
|----------|--------|
| `GET /health`, `GET /v1/health` | 200 |
| `GET /v1/content/story` | 200 free |
| `GET /v1/chamatkars` | 200 (+ `likeCount` / `likedByMe`) |
| `POST /v1/chamatkars` | 201 with Google auth |
| `POST /v1/chamatkars/:id/like` | 200 toggle |
| `GET /v1/auth/me` | 200 upsert user |
| `PUT /v1/auth/fcm-token` | 204 |
| `GET /v1/entitlement` | 401 unauth / 200 auth |
| `GET /v1/content/premium-manifest` | 402 free / 200 premium |
| `POST /v1/subscriptions/razorpay/monthly` | 201 pending |
| `POST /v1/subscriptions/webhook` | 200 signed + idempotent |
| `POST /v1/uploads/presign` | 402 free / 200 premium |