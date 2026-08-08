# Khatu Shyam API

Node.js API foundation for Firebase-authenticated users, free Story and
Chamatkar content, Razorpay subscriptions, premium entitlements, and S3 media
uploads.

## Requirements

- Node.js 22
- MongoDB
- Firebase project with Google Sign-In enabled
- Razorpay plan and webhook
- Private S3 bucket in `ap-south-1`

## Local setup

1. Copy `.env.example` to `.env` and provide development credentials.
2. Configure Application Default Credentials for Firebase Admin.
3. Run `npm install`.
4. Run `npm run local` for fake Google auth against local Mongo, or `npm run dev` for real Firebase once credentials exist.

### Verify endpoints

```bash
npm test         # integration tests (local Mongo)
npm run smoke    # prints PASS/FAIL for every route
npm run local    # http://127.0.0.1:4000 with Bearer free|premium|admin
npm run seed:content  # import khatu-shyam-content/metadata.json into Mongo
```

### Admin APIs

Require `role: admin` (auto-granted for emails in `ADMIN_EMAILS`):

| Method | Path | Notes |
|--------|------|-------|
| `GET` | `/v1/admin/stats` | User + content counts |
| `GET`/`PATCH` | `/v1/admin/users` | List / update role & subscription |
| `GET`/`POST`/`PATCH`/`DELETE` | `/v1/admin/content` | Library CRUD (delete archives) |
| `POST` | `/v1/admin/uploads/presign` | Presign S3 upload for wallpapers/ringtones |

Premium clients can list published assets at `GET /v1/content/library`.

See [`PRODUCTION_CHECKLIST.md`](PRODUCTION_CHECKLIST.md) for what is required to productionize.

## Access model

- Free: `GET /api/v1/content/story`, Chamatkar read/write.
- Paid: every utility and media endpoint uses Firebase authentication followed
  by `requirePremium`.
- Razorpay webhooks are signature-verified and idempotently reconcile the
  MongoDB subscription status.

## AWS deployment

Build the included Docker image and deploy it to ECS/Fargate behind an
Application Load Balancer. Store secrets in AWS Secrets Manager, use an IAM
task role for S3, and serve public media through CloudFront.
