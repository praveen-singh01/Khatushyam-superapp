import { createHmac } from "node:crypto";
import mongoose from "mongoose";
import request from "supertest";
import { createApp } from "../src/app.js";
import type { AppEnv } from "../src/config/env.js";
import { User } from "../src/modules/auth/user.model.js";
import { Chamatkar } from "../src/modules/chamatkars/chamatkar.model.js";
import { WebhookEvent } from "../src/modules/subscriptions/webhook-event.model.js";

const env: AppEnv = {
  NODE_ENV: "test",
  PORT: 4000,
  MONGODB_URI: "mongodb://127.0.0.1:27017/khatu_shyam_smoke",
  APP_ORIGIN: "*",
  FIREBASE_PROJECT_ID: "smoke-project",
  RAZORPAY_KEY_ID: "rzp_test_key",
  RAZORPAY_KEY_SECRET: "test_secret",
  RAZORPAY_PLAN_ID: "plan_test",
  RAZORPAY_WEBHOOK_SECRET: "webhook_test",
  AWS_REGION: "ap-south-1",
  S3_MEDIA_BUCKET: "smoke-bucket",
  CLOUDFRONT_BASE_URL: "https://cdn.example.com",
  ADMIN_EMAILS: "admin@smoke.test",
};

const app = createApp({
  env,
  identityVerifier: {
    async verify(token) {
      if (token === "premium") {
        return {
          uid: "smoke-premium",
          email: "premium@smoke.test",
          name: "Smoke Premium",
          signInProvider: "google.com",
        };
      }
      return {
        uid: "smoke-free",
        email: "free@smoke.test",
        name: "Smoke Free",
        signInProvider: "google.com",
      };
    },
  },
  subscriptionGateway: {
    async createMonthlySubscription() {
      return { id: "sub_smoke_1" };
    },
  },
  uploadPresigner: {
    async createUploadUrl() {
      return "https://s3.example.com/smoke-upload";
    },
  },
});

async function check(
  name: string,
  run: () => Promise<{ status: number; body?: unknown }>,
) {
  const result = await run();
  const ok = result.status >= 200 && result.status < 400;
  console.log(
    `${ok ? "PASS" : "FAIL"} ${name} -> ${result.status}`,
    typeof result.body === "object" ? JSON.stringify(result.body) : "",
  );
  if (!ok) process.exitCode = 1;
}

await mongoose.connect(env.MONGODB_URI);
await Promise.all([
  User.deleteMany({}),
  Chamatkar.deleteMany({}),
  WebhookEvent.deleteMany({}),
]);

await check("GET /health", async () => request(app).get("/health"));
await check("GET /v1/health", async () => request(app).get("/v1/health"));
await check("GET /v1/content/story", async () =>
  request(app).get("/v1/content/story"),
);
await check("GET /v1/chamatkars", async () => request(app).get("/v1/chamatkars"));
await check("GET /v1/entitlement (401 without auth)", async () => {
  const response = await request(app).get("/v1/entitlement");
  return {
    status: response.status === 401 ? 200 : response.status,
    body: response.body,
  };
});
await check("GET /v1/auth/me", async () =>
  request(app).get("/v1/auth/me").set("Authorization", "Bearer free"),
);
await check("GET /v1/entitlement", async () =>
  request(app).get("/v1/entitlement").set("Authorization", "Bearer free"),
);
await check("PUT /v1/auth/fcm-token", async () =>
  request(app)
    .put("/v1/auth/fcm-token")
    .set("Authorization", "Bearer free")
    .send({ token: "fcm-smoke-token-1234567890" }),
);
await check("POST /v1/chamatkars", async () =>
  request(app)
    .post("/v1/chamatkars")
    .set("Authorization", "Bearer free")
    .send({
      title: "Smoke miracle",
      story: "A long enough smoke-test miracle story for local verification.",
      language: "en",
    }),
);
await check("GET /v1/content/premium-manifest (402 free)", async () => {
  const response = await request(app)
    .get("/v1/content/premium-manifest")
    .set("Authorization", "Bearer free");
  return {
    status: response.status === 402 ? 200 : response.status,
    body: response.body,
  };
});
await check("POST /v1/subscriptions/razorpay/monthly", async () =>
  request(app)
    .post("/v1/subscriptions/razorpay/monthly")
    .set("Authorization", "Bearer free"),
);

await User.create({
  firebaseUid: "smoke-premium",
  email: "premium@smoke.test",
  subscriptionStatus: "active",
  razorpaySubscriptionId: "sub_smoke_premium",
});

await check("GET /v1/content/premium-manifest (premium)", async () =>
  request(app)
    .get("/v1/content/premium-manifest")
    .set("Authorization", "Bearer premium"),
);
await check("POST /v1/uploads/presign", async () =>
  request(app)
    .post("/v1/uploads/presign")
    .set("Authorization", "Bearer premium")
    .send({ contentType: "image/jpeg", purpose: "poster_photo" }),
);

const payload = {
  event: "subscription.activated",
  payload: {
    subscription: { entity: { id: "sub_smoke_1", status: "active" } },
  },
};
const raw = JSON.stringify(payload);
const signature = createHmac("sha256", env.RAZORPAY_WEBHOOK_SECRET)
  .update(raw)
  .digest("hex");

await check("POST /v1/subscriptions/webhook", async () =>
  request(app)
    .post("/v1/subscriptions/webhook")
    .set("Content-Type", "application/json")
    .set("x-razorpay-signature", signature)
    .set("x-razorpay-event-id", "evt_smoke_1")
    .send(raw),
);

await mongoose.disconnect();
console.log(
  process.exitCode ? "Smoke checks finished with failures" : "All smoke checks passed",
);
