import "dotenv/config";
import mongoose from "mongoose";
import { createApp } from "../src/app.js";
import type { AppEnv } from "../src/config/env.js";
import { createRazorpayGateway } from "../src/modules/subscriptions/razorpay.gateway.js";
import { createS3UploadPresigner } from "../src/modules/uploads/s3.presigner.js";

/**
 * Local-only API server with fake Google auth.
 * Use Authorization: Bearer free | Bearer premium
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
  AWS_REGION: process.env.AWS_REGION ?? "ap-south-1",
  S3_MEDIA_BUCKET: process.env.S3_MEDIA_BUCKET ?? "khatu-shyam-local",
  CLOUDFRONT_BASE_URL:
    process.env.CLOUDFRONT_BASE_URL ?? "https://cdn.example.com",
};

await mongoose.connect(env.MONGODB_URI);

const useRealGateways = process.env.LOCAL_USE_REAL_GATEWAYS === "true";

const app = createApp({
  env,
  identityVerifier: {
    async verify(token) {
      if (token === "premium") {
        return {
          uid: "local-premium",
          email: "premium@local.test",
          name: "Local Premium",
          signInProvider: "google.com",
        };
      }
      if (token !== "free" && token !== "premium") {
        throw new Error("Use Bearer free or Bearer premium in local-dev");
      }
      return {
        uid: "local-free",
        email: "free@local.test",
        name: "Local Free",
        signInProvider: "google.com",
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
          return { id: `sub_local_${Date.now()}` };
        },
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
  console.info("Auth: Authorization: Bearer free | Bearer premium");
});
