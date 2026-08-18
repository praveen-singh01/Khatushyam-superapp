import "dotenv/config";
import mongoose from "mongoose";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createApp } from "../src/app.js";
import type { AppEnv } from "../src/config/env.js";
import { User } from "../src/modules/auth/user.model.js";
import { createRazorpayGateway } from "../src/modules/subscriptions/razorpay.gateway.js";
import { createS3UploadPresigner } from "../src/modules/uploads/s3.presigner.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const defaultMediaRoot = path.resolve(__dirname, "../../khatu-shyam-content");

/**
 * Local-only API server with fake Google auth.
 * Use Authorization: Bearer free | Bearer premium | Bearer admin
 *
 * Does not call real Firebase/Razorpay unless LOCAL_USE_REAL_GATEWAYS=true.
 */
const env: AppEnv = {
  NODE_ENV: "development",
  PORT: Number(process.env.PORT ?? 4000),
  MONGODB_URI:
    process.env.MONGODB_URI ?? "mongodb://127.0.0.1:27017/khatu_shyam_local",
  APP_ORIGIN: "*",
  FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID ?? "local-dev",
  RAZORPAY_KEY_ID: process.env.RAZORPAY_KEY_ID ?? "rzp_test_local",
  RAZORPAY_KEY_SECRET: process.env.RAZORPAY_KEY_SECRET ?? "local_secret",
  RAZORPAY_PLAN_ID: process.env.RAZORPAY_PLAN_ID ?? "plan_local",
  RAZORPAY_WEBHOOK_SECRET:
    process.env.RAZORPAY_WEBHOOK_SECRET ?? "local_webhook_secret",
  TRIAL_DURATION_HOURS: Number(process.env.TRIAL_DURATION_HOURS ?? 24),
  TRIAL_AMOUNT_INR: Number(process.env.TRIAL_AMOUNT_INR ?? 3),
  AWS_REGION: process.env.AWS_REGION ?? "ap-south-1",
  S3_MEDIA_BUCKET: process.env.S3_MEDIA_BUCKET ?? "khatu-shyam-local",
  CLOUDFRONT_BASE_URL:
    process.env.CLOUDFRONT_BASE_URL ?? "https://cdn.example.com",
  MEDIA_LOCAL_ROOT: process.env.MEDIA_LOCAL_ROOT ?? defaultMediaRoot,
  ADMIN_EMAILS: [
    process.env.ADMIN_EMAILS,
    "admin@local.test",
    "premium@local.test",
  ]
    .filter(Boolean)
    .join(","),
  PREMIUM_TEST_EMAILS:
    process.env.PREMIUM_TEST_EMAILS ?? "reviewer@yaaro.online",
  APP_FREE_MODE: process.env.APP_FREE_MODE !== "false",
};

await mongoose.connect(env.MONGODB_URI);

const useRealGateways = process.env.LOCAL_USE_REAL_GATEWAYS === "true";

const app = createApp({
  env,
  identityVerifier: {
    async verify(token) {
      const profiles = {
        admin: {
          uid: "local-admin",
          email: "admin@local.test",
          name: "Local Admin",
          signInProvider: "google.com" as const,
          subscriptionStatus: "active" as const,
        },
        premium: {
          uid: "local-premium",
          email: "premium@local.test",
          name: "Local Premium",
          signInProvider: "google.com" as const,
          subscriptionStatus: "active" as const,
        },
        free: {
          uid: "local-free",
          email: "free@local.test",
          name: "Local Free",
          signInProvider: "google.com" as const,
          subscriptionStatus: "inactive" as const,
        },
      };

      const profile = profiles[token as keyof typeof profiles];
      if (!profile) {
        throw new Error(
          "Use Bearer free, Bearer premium, or Bearer admin in local-dev",
        );
      }

      // Keep Mongo entitlement in sync for local fake tokens.
      // Do not put the same path in both $set and $setOnInsert (Mongo rejects it).
      await User.findOneAndUpdate(
        { firebaseUid: profile.uid },
        {
          $set: {
            email: profile.email,
            displayName: profile.name,
            subscriptionStatus: profile.subscriptionStatus,
            ...(token === "admin" ? { role: "admin" as const } : {}),
          },
          $setOnInsert: {
            ...(token === "admin" ? {} : { role: "user" as const }),
          },
        },
        { upsert: true },
      );

      return {
        uid: profile.uid,
        email: profile.email,
        name: profile.name,
        signInProvider: profile.signInProvider,
      };
    },
  },
  subscriptionGateway: useRealGateways
    ? createRazorpayGateway({
        keyId: env.RAZORPAY_KEY_ID,
        keySecret: env.RAZORPAY_KEY_SECRET,
      })
    : {
        async createMonthlySubscription() {
          return { id: `sub_local_${Date.now()}`, shortUrl: null };
        },
        async cancelSubscription() {},
      },
  uploadPresigner: useRealGateways
    ? createS3UploadPresigner(env.AWS_REGION)
    : {
        async createUploadUrl({ key }) {
          return `https://s3.example.com/local/${key}?signed=1`;
        },
      },
});

app.listen(env.PORT, () => {
  console.info(`Local fake-auth API on http://127.0.0.1:${env.PORT}`);
  console.info(
    "Auth: Authorization: Bearer free | Bearer premium | Bearer admin",
  );
});
