import { createHmac } from "node:crypto";
import mongoose from "mongoose";
import request from "supertest";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import type { AppEnv } from "../src/config/env.js";
import { User } from "../src/modules/auth/user.model.js";
import { Chamatkar } from "../src/modules/chamatkars/chamatkar.model.js";
import { validWebhookSignature } from "../src/modules/subscriptions/subscription.routes.js";
import { WebhookEvent } from "../src/modules/subscriptions/webhook-event.model.js";
import type { IdentityVerifier } from "../src/shared/types.js";

const env: AppEnv = {
  NODE_ENV: "test",
  PORT: 4000,
  MONGODB_URI: "mongodb://127.0.0.1:27017/khatu_shyam_test",
  APP_ORIGIN: "*",
  FIREBASE_PROJECT_ID: "test-project",
  RAZORPAY_KEY_ID: "rzp_test_key",
  RAZORPAY_KEY_SECRET: "test_secret",
  RAZORPAY_PLAN_ID: "plan_test",
  RAZORPAY_WEBHOOK_SECRET: "webhook_test",
  AWS_REGION: "ap-south-1",
  S3_MEDIA_BUCKET: "test-bucket",
  CLOUDFRONT_BASE_URL: "https://cdn.example.com",
};

function identityFor(token: string): IdentityVerifier {
  return {
    async verify(incoming) {
      if (incoming === "bad") {
        throw new Error("invalid");
      }
      if (incoming === "password") {
        return {
          uid: "password-user",
          email: "password@example.com",
          signInProvider: "password",
        };
      }
      if (incoming === "no-email") {
        return {
          uid: "no-email-user",
          signInProvider: "google.com",
        };
      }
      if (incoming === "premium") {
        return {
          uid: "premium-user",
          email: "premium@example.com",
          name: "Premium Devotee",
          picture: "https://cdn.example.com/premium.jpg",
          signInProvider: "google.com",
        };
      }
      return {
        uid: "free-user",
        email: "free@example.com",
        name: "Free Devotee",
        signInProvider: "google.com",
      };
    },
  };
}

const fakeGateway = {
  async createMonthlySubscription() {
    return { id: "sub_test_123" };
  },
};

const fakePresigner = {
  async createUploadUrl() {
    return "https://s3.example.com/upload?signed=1";
  },
};

const app = createApp({
  env,
  identityVerifier: identityFor("token"),
  subscriptionGateway: fakeGateway,
  uploadPresigner: fakePresigner,
});

beforeAll(async () => {
  await mongoose.connect(env.MONGODB_URI);
});

beforeEach(async () => {
  await Promise.all([
    User.deleteMany({}),
    Chamatkar.deleteMany({}),
    WebhookEvent.deleteMany({}),
  ]);
});

afterAll(async () => {
  await mongoose.disconnect();
});

describe("health and public content", () => {
  it("responds on /health and /v1/health", async () => {
    const a = await request(app).get("/health");
    const b = await request(app).get("/v1/health");
    expect(a.status).toBe(200);
    expect(b.body).toEqual({ status: "ok" });
  });

  it("serves free story without auth", async () => {
    const response = await request(app).get("/v1/content/story");
    expect(response.status).toBe(200);
    expect(response.body.access).toBe("free");
  });

  it("returns 404 for unknown routes", async () => {
    const response = await request(app).get("/v1/missing");
    expect(response.status).toBe(404);
    expect(response.body.error).toBe("NOT_FOUND");
  });
});

describe("authentication guards", () => {
  it("requires bearer token", async () => {
    const response = await request(app).get("/v1/entitlement");
    expect(response.status).toBe(401);
    expect(response.body.error).toBe("AUTH_REQUIRED");
  });

  it("rejects invalid tokens", async () => {
    const response = await request(app)
      .get("/v1/entitlement")
      .set("Authorization", "Bearer bad");
    expect(response.status).toBe(401);
    expect(response.body.error).toBe("INVALID_AUTH_TOKEN");
  });

  it("requires Google sign-in", async () => {
    const response = await request(app)
      .get("/v1/auth/me")
      .set("Authorization", "Bearer password");
    expect(response.status).toBe(403);
    expect(response.body.error).toBe("GOOGLE_SIGN_IN_REQUIRED");
  });

  it("requires Google email", async () => {
    const response = await request(app)
      .get("/v1/auth/me")
      .set("Authorization", "Bearer no-email");
    expect(response.status).toBe(403);
    expect(response.body.error).toBe("GOOGLE_EMAIL_REQUIRED");
  });
});

describe("auth and entitlement", () => {
  it("upserts the user and returns /auth/me", async () => {
    const response = await request(app)
      .get("/v1/auth/me")
      .set("Authorization", "Bearer free");
    expect(response.status).toBe(200);
    expect(response.body.user.email).toBe("free@example.com");
    expect(response.body.user.subscriptionStatus).toBe("inactive");
    expect(await User.countDocuments()).toBe(1);
  });

  it("returns free entitlement for inactive users", async () => {
    const response = await request(app)
      .get("/v1/entitlement")
      .set("Authorization", "Bearer free");
    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      isPremium: false,
      planId: null,
      source: "none",
      subscriptionStatus: "inactive",
    });
  });

  it("stores FCM tokens", async () => {
    await request(app)
      .get("/v1/auth/me")
      .set("Authorization", "Bearer free");
    const response = await request(app)
      .put("/v1/auth/fcm-token")
      .set("Authorization", "Bearer free")
      .send({ token: "fcm-device-token-1234567890" });
    expect(response.status).toBe(204);
    const user = await User.findOne({ firebaseUid: "free-user" });
    expect(user?.fcmTokens).toContain("fcm-device-token-1234567890");
  });

  it("rejects invalid FCM payloads", async () => {
    const response = await request(app)
      .put("/v1/auth/fcm-token")
      .set("Authorization", "Bearer free")
      .send({ token: "short" });
    expect(response.status).toBe(400);
    expect(response.body.error).toBe("VALIDATION_ERROR");
  });
});

describe("chamatkars", () => {
  it("lists empty feed publicly", async () => {
    const response = await request(app).get("/v1/chamatkars");
    expect(response.status).toBe(200);
    expect(response.body.items).toEqual([]);
    expect(response.body.nextCursor).toBeNull();
  });

  it("creates and lists a miracle story", async () => {
    const create = await request(app)
      .post("/v1/chamatkars")
      .set("Authorization", "Bearer free")
      .send({
        title: "श्याम बाबा का चमत्कार",
        story: "This is a sufficiently long miracle story for validation.",
        language: "hi",
      });
    expect(create.status).toBe(201);
    expect(create.body.item.title).toContain("श्याम");

    const list = await request(app).get("/v1/chamatkars");
    expect(list.status).toBe(200);
    expect(list.body.items).toHaveLength(1);
  });

  it("rejects short chamatkar stories", async () => {
    const response = await request(app)
      .post("/v1/chamatkars")
      .set("Authorization", "Bearer free")
      .send({ title: "Too short", story: "short", language: "en" });
    expect(response.status).toBe(400);
  });
});

describe("premium gates", () => {
  it("blocks premium content for free users", async () => {
    const response = await request(app)
      .get("/v1/content/premium-manifest")
      .set("Authorization", "Bearer free");
    expect(response.status).toBe(402);
    expect(response.body.error).toBe("PREMIUM_REQUIRED");
  });

  it("blocks uploads for free users", async () => {
    const response = await request(app)
      .post("/v1/uploads/presign")
      .set("Authorization", "Bearer free")
      .send({ contentType: "image/jpeg", purpose: "poster_photo" });
    expect(response.status).toBe(402);
  });

  it("allows premium content and uploads for active subscribers", async () => {
    await User.create({
      firebaseUid: "premium-user",
      email: "premium@example.com",
      displayName: "Premium Devotee",
      subscriptionStatus: "active",
      razorpaySubscriptionId: "sub_existing",
    });

    const manifest = await request(app)
      .get("/v1/content/premium-manifest")
      .set("Authorization", "Bearer premium");
    expect(manifest.status).toBe(200);
    expect(manifest.body.features).toContain("wallpapers");

    const entitlement = await request(app)
      .get("/v1/entitlement")
      .set("Authorization", "Bearer premium");
    expect(entitlement.body.isPremium).toBe(true);
    expect(entitlement.body.source).toBe("razorpay");

    const upload = await request(app)
      .post("/v1/uploads/presign")
      .set("Authorization", "Bearer premium")
      .send({ contentType: "image/png", purpose: "profile_photo" });
    expect(upload.status).toBe(200);
    expect(upload.body.uploadUrl).toContain("https://s3.example.com");
    expect(upload.body.key).toContain("private/users/");
  });
});

describe("subscriptions and webhooks", () => {
  it("starts a monthly Razorpay subscription", async () => {
    const response = await request(app)
      .post("/v1/subscriptions/razorpay/monthly")
      .set("Authorization", "Bearer free");
    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({
      isPremium: false,
      planId: "plan_test",
      source: "razorpay",
      subscriptionStatus: "pending",
      subscriptionId: "sub_test_123",
      keyId: "rzp_test_key",
    });
    const user = await User.findOne({ firebaseUid: "free-user" });
    expect(user?.subscriptionStatus).toBe("pending");
    expect(user?.razorpaySubscriptionId).toBe("sub_test_123");
  });

  it("rejects starting another plan when already active", async () => {
    await User.create({
      firebaseUid: "premium-user",
      email: "premium@example.com",
      subscriptionStatus: "active",
      razorpaySubscriptionId: "sub_existing",
    });
    const response = await request(app)
      .post("/v1/subscriptions/razorpay/monthly")
      .set("Authorization", "Bearer premium");
    expect(response.status).toBe(409);
  });

  it("rejects invalid webhook signatures", async () => {
    const response = await request(app)
      .post("/v1/subscriptions/webhook")
      .set("Content-Type", "application/json")
      .set("x-razorpay-signature", "nope")
      .send(JSON.stringify({ event: "subscription.activated" }));
    expect(response.status).toBe(400);
  });

  it("activates subscription from a signed webhook and stays idempotent", async () => {
    await User.create({
      firebaseUid: "free-user",
      email: "free@example.com",
      subscriptionStatus: "pending",
      razorpaySubscriptionId: "sub_webhook_1",
    });

    const payload = {
      event: "subscription.activated",
      payload: {
        subscription: { entity: { id: "sub_webhook_1", status: "active" } },
      },
    };
    const raw = JSON.stringify(payload);
    const signature = createHmac("sha256", env.RAZORPAY_WEBHOOK_SECRET)
      .update(raw)
      .digest("hex");

    const first = await request(app)
      .post("/v1/subscriptions/webhook")
      .set("Content-Type", "application/json")
      .set("x-razorpay-signature", signature)
      .set("x-razorpay-event-id", "evt_1")
      .send(raw);
    expect(first.status).toBe(200);

    const user = await User.findOne({ razorpaySubscriptionId: "sub_webhook_1" });
    expect(user?.subscriptionStatus).toBe("active");

    const second = await request(app)
      .post("/v1/subscriptions/webhook")
      .set("Content-Type", "application/json")
      .set("x-razorpay-signature", signature)
      .set("x-razorpay-event-id", "evt_1")
      .send(raw);
    expect(second.body.duplicate).toBe(true);
    expect(await WebhookEvent.countDocuments()).toBe(1);
  });
});

describe("webhook signature helper", () => {
  it("validates hmac signatures", () => {
    const raw = Buffer.from('{"ok":true}');
    const signature = createHmac("sha256", "secret").update(raw).digest("hex");
    expect(validWebhookSignature(raw, signature, "secret")).toBe(true);
    expect(validWebhookSignature(raw, "bad", "secret")).toBe(false);
  });
});
