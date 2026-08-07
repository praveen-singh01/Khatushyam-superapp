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
npm test        # 22 integration tests (local Mongo)
npm run smoke   # prints PASS/FAIL for every route
npm run local   # http://127.0.0.1:4000 with Bearer free|premium
```

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
