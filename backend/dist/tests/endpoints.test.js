import { createHmac } from "node:crypto";
import mongoose from "mongoose";
import request from "supertest";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { User } from "../src/modules/auth/user.model.js";
import { Chamatkar } from "../src/modules/chamatkars/chamatkar.model.js";
import { ContentAsset } from "../src/modules/content/content-asset.model.js";
import { ContentCategory } from "../src/modules/content/content-category.model.js";
import { LiveStream } from "../src/modules/content/live-stream.model.js";
import { Story } from "../src/modules/content/story.model.js";
import { Subscription } from "../src/modules/subscriptions/subscription.model.js";
import { validPaymentSignature, validWebhookSignature, } from "../src/modules/subscriptions/subscription.routes.js";
import { WebhookEvent } from "../src/modules/subscriptions/webhook-event.model.js";
const env = {
    NODE_ENV: "test",
    PORT: 4000,
    MONGODB_URI: process.env.MONGODB_URI?.replace(/\/[^/?]+(\?|$)/, "/khatu_shyam_test$1") ?? "mongodb://127.0.0.1:27017/khatu_shyam_test",
    APP_ORIGIN: "*",
    FIREBASE_PROJECT_ID: "test-project",
    RAZORPAY_KEY_ID: "rzp_test_key",
    RAZORPAY_KEY_SECRET: "test_secret",
    RAZORPAY_PLAN_ID: "plan_test",
    RAZORPAY_WEBHOOK_SECRET: "webhook_test",
    TRIAL_DURATION_HOURS: 24,
    TRIAL_AMOUNT_INR: 3,
    AWS_REGION: "ap-south-1",
    S3_MEDIA_BUCKET: "test-bucket",
    CLOUDFRONT_BASE_URL: "https://cdn.example.com",
    ADMIN_EMAILS: "admin@example.com",
    PREMIUM_TEST_EMAILS: "reviewer@example.com",
    APP_FREE_MODE: false,
};
function identityFor(token) {
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
            if (incoming === "admin") {
                return {
                    uid: "admin-user",
                    email: "admin@example.com",
                    name: "Admin Devotee",
                    signInProvider: "google.com",
                };
            }
            if (incoming === "reviewer") {
                return {
                    uid: "reviewer-user",
                    email: "reviewer@example.com",
                    name: "Play Reviewer",
                    signInProvider: "password",
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
        return { id: "sub_test_123", shortUrl: null };
    },
    async cancelSubscription() { },
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
}, 60000);
beforeEach(async () => {
    await Promise.all([
        User.deleteMany({}),
        Chamatkar.deleteMany({}),
        ContentAsset.deleteMany({}),
        ContentCategory.deleteMany({}),
        LiveStream.deleteMany({}),
        Story.deleteMany({}),
        WebhookEvent.deleteMany({}),
        Subscription.deleteMany({}),
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
        expect(response.body.chapters.length).toBeGreaterThan(0);
        expect(response.body.title.hi).toBeTruthy();
    });
    it("serves offline live darshan by default without auth", async () => {
        const response = await request(app).get("/v1/content/live");
        expect(response.status).toBe(200);
        expect(response.body).toMatchObject({
            isLive: false,
            youtubeVideoId: null,
            embedUrl: null,
            access: "free",
        });
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
    it("accepts Firebase password sign-in", async () => {
        const response = await request(app)
            .get("/v1/auth/me")
            .set("Authorization", "Bearer password");
        expect(response.status).toBe(200);
        expect(response.body.user.email).toBe("password@example.com");
        expect(response.body.user.role).toBe("user");
    });
    it("requires email on the identity", async () => {
        const response = await request(app)
            .get("/v1/auth/me")
            .set("Authorization", "Bearer no-email");
        expect(response.status).toBe(403);
        expect(response.body.error).toBe("EMAIL_REQUIRED");
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
            trialUsed: false,
            trialEligible: true,
        });
        expect(response.body.offers).toEqual([
            {
                id: "trial_monthly",
                priceInr: 199,
                period: "month",
                trialPriceInr: 3,
            },
        ]);
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
        expect(create.body.item.likeCount).toBe(0);
        expect(create.body.item.likedByMe).toBe(false);
        const list = await request(app).get("/v1/chamatkars");
        expect(list.status).toBe(200);
        expect(list.body.items).toHaveLength(1);
    });
    it("toggles likes for authenticated users", async () => {
        const create = await request(app)
            .post("/v1/chamatkars")
            .set("Authorization", "Bearer free")
            .send({
            title: "कृपा का अनुभव",
            story: "A long enough miracle story so that like toggle can be tested.",
            language: "hi",
        });
        const id = create.body.item.id;
        const liked = await request(app)
            .post(`/v1/chamatkars/${id}/like`)
            .set("Authorization", "Bearer free");
        expect(liked.status).toBe(200);
        expect(liked.body.item.likeCount).toBe(1);
        expect(liked.body.item.likedByMe).toBe(true);
        const authedList = await request(app)
            .get("/v1/chamatkars")
            .set("Authorization", "Bearer free");
        expect(authedList.body.items[0].likedByMe).toBe(true);
        const unliked = await request(app)
            .post(`/v1/chamatkars/${id}/like`)
            .set("Authorization", "Bearer free");
        expect(unliked.status).toBe(200);
        expect(unliked.body.item.likeCount).toBe(0);
        expect(unliked.body.item.likedByMe).toBe(false);
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
        expect(upload.body.key).toContain("khatu-shyam/private/users/");
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
            planId: "monthly",
            source: "razorpay",
            subscriptionStatus: "pending",
            subscriptionId: "sub_test_123",
            keyId: "rzp_test_key",
            trialUsed: false,
            trialEligible: true,
        });
        const user = await User.findOne({ firebaseUid: "free-user" });
        expect(user?.subscriptionStatus).toBe("pending");
        expect(user?.razorpaySubscriptionId).toBe("sub_test_123");
        expect(user?.trialUsed).toBe(false);
        expect(user?.currentPlan).toBe("monthly");
    });
    it("offers weekly and monthly after trial was used", async () => {
        await User.create({
            firebaseUid: "free-user",
            email: "free@example.com",
            subscriptionStatus: "cancelled",
            trialUsed: true,
        });
        const response = await request(app)
            .get("/v1/entitlement")
            .set("Authorization", "Bearer free");
        expect(response.status).toBe(200);
        expect(response.body.trialEligible).toBe(false);
        expect(response.body.offers).toEqual([
            { id: "weekly", priceInr: 49, period: "week" },
            { id: "monthly", priceInr: 199, period: "month" },
        ]);
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
        const currentEnd = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;
        const payload = {
            event: "subscription.activated",
            payload: {
                subscription: {
                    entity: {
                        id: "sub_webhook_1",
                        status: "active",
                        current_end: currentEnd,
                        notes: { user_id: "not-a-valid-objectid" },
                    },
                },
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
        expect(user?.subscriptionExpiresAt?.getTime()).toBeGreaterThan(Date.now());
        const entitlement = await request(app)
            .get("/v1/entitlement")
            .set("Authorization", "Bearer free");
        expect(entitlement.body.isPremium).toBe(true);
        const second = await request(app)
            .post("/v1/subscriptions/webhook")
            .set("Content-Type", "application/json")
            .set("x-razorpay-signature", signature)
            .set("x-razorpay-event-id", "evt_1")
            .send(raw);
        expect(second.body.duplicate).toBe(true);
        expect(await WebhookEvent.countDocuments()).toBe(1);
    });
    it("verifies checkout payment signature and unlocks premium", async () => {
        const start = await request(app)
            .post("/v1/subscriptions/razorpay/start")
            .set("Authorization", "Bearer free")
            .send({ plan: "trial_monthly" });
        expect(start.status).toBe(201);
        const subId = start.body.subscriptionId;
        const paymentId = "pay_test_1";
        const signature = createHmac("sha256", env.RAZORPAY_KEY_SECRET)
            .update(`${paymentId}|${subId}`)
            .digest("hex");
        const verified = await request(app)
            .post("/v1/subscriptions/verify")
            .set("Authorization", "Bearer free")
            .send({
            razorpaySubscriptionId: subId,
            razorpayPaymentId: paymentId,
            razorpaySignature: signature,
        });
        expect(verified.status).toBe(200);
        expect(verified.body.isPremium).toBe(true);
        expect(verified.body.subscriptionStatus).toBe("authenticated");
        expect(verified.body.trialUsed).toBe(true);
    });
    it("keeps premium until expiry after cancel; halt revokes immediately", async () => {
        const future = new Date(Date.now() + 7 * 86400000);
        const user = await User.create({
            firebaseUid: "free-user",
            email: "free@example.com",
            subscriptionStatus: "active",
            trialUsed: true,
            currentPlan: "monthly",
            subscriptionExpiresAt: future,
            razorpaySubscriptionId: "sub_cancel_1",
        });
        await Subscription.create({
            userId: user._id,
            plan: "monthly",
            isActive: true,
            isTrial: false,
            isTrialPeriod: false,
            startDate: new Date(),
            endDate: future,
            currentEnd: future,
            razorpaySubscriptionId: "sub_cancel_1",
            razorpayPlanId: "plan_test",
            paymentStatus: "completed",
            subscriptionStatus: "active",
            version: 1,
        });
        const cancelled = await request(app)
            .post("/v1/subscriptions/cancel")
            .set("Authorization", "Bearer free")
            .send({ reason: "testing" });
        expect(cancelled.status).toBe(200);
        expect(cancelled.body.subscriptionStatus).toBe("cancelled");
        expect(cancelled.body.isPremium).toBe(true);
        const haltPayload = {
            event: "subscription.halted",
            payload: {
                subscription: {
                    entity: {
                        id: "sub_cancel_1",
                        status: "halted",
                        notes: { user_id: user._id.toString() },
                    },
                },
            },
        };
        const raw = JSON.stringify(haltPayload);
        const signature = createHmac("sha256", env.RAZORPAY_WEBHOOK_SECRET)
            .update(raw)
            .digest("hex");
        await request(app)
            .post("/v1/subscriptions/webhook")
            .set("Content-Type", "application/json")
            .set("x-razorpay-signature", signature)
            .set("x-razorpay-event-id", "evt_halt_1")
            .send(raw);
        const afterHalt = await request(app)
            .get("/v1/entitlement")
            .set("Authorization", "Bearer free");
        expect(afterHalt.body.isPremium).toBe(false);
        expect(afterHalt.body.subscriptionStatus).toBe("halted");
    });
});
describe("webhook signature helper", () => {
    it("validates hmac signatures", () => {
        const raw = Buffer.from('{"ok":true}');
        const signature = createHmac("sha256", "secret").update(raw).digest("hex");
        expect(validWebhookSignature(raw, signature, "secret")).toBe(true);
        expect(validWebhookSignature(raw, "bad", "secret")).toBe(false);
        expect(validPaymentSignature({
            paymentId: "pay_1",
            subscriptionId: "sub_1",
            signature: createHmac("sha256", "secret")
                .update("pay_1|sub_1")
                .digest("hex"),
            keySecret: "secret",
        })).toBe(true);
    });
});
describe("admin dashboard APIs", () => {
    it("rejects non-admins from admin routes", async () => {
        const response = await request(app)
            .get("/v1/admin/stats")
            .set("Authorization", "Bearer free");
        expect(response.status).toBe(403);
        expect(response.body.error).toBe("ADMIN_REQUIRED");
    });
    it("promotes ADMIN_EMAILS users and serves admin stats", async () => {
        const me = await request(app)
            .get("/v1/auth/me")
            .set("Authorization", "Bearer admin");
        expect(me.status).toBe(200);
        expect(me.body.user.role).toBe("admin");
        const stats = await request(app)
            .get("/v1/admin/stats")
            .set("Authorization", "Bearer admin");
        expect(stats.status).toBe(200);
        expect(stats.body.users.total).toBe(1);
        expect(stats.body.users.admins).toBe(1);
        expect(stats.body.categories.wallpapers).toBeGreaterThan(0);
    });
    it("grants premium to PREMIUM_TEST_EMAILS on login", async () => {
        const me = await request(app)
            .get("/v1/auth/me")
            .set("Authorization", "Bearer reviewer");
        expect(me.status).toBe(200);
        expect(me.body.user.email).toBe("reviewer@example.com");
        expect(me.body.user.subscriptionStatus).toBe("active");
        expect(me.body.user.subscriptionExpiresAt).toBeTruthy();
        const status = await request(app)
            .get("/v1/subscriptions/status")
            .set("Authorization", "Bearer reviewer");
        expect(status.status).toBe(200);
        expect(status.body.isPremium).toBe(true);
    });
    it("creates and lists content categories", async () => {
        await request(app)
            .get("/v1/auth/me")
            .set("Authorization", "Bearer admin");
        const created = await request(app)
            .post("/v1/admin/categories")
            .set("Authorization", "Bearer admin")
            .send({
            type: "wallpaper",
            slug: "temple-night",
            label: { en: "Temple Night", hi: "मंदिर रात" },
        });
        expect(created.status).toBe(201);
        expect(created.body.item.slug).toBe("temple-night");
        const listed = await request(app)
            .get("/v1/admin/categories?type=wallpaper")
            .set("Authorization", "Bearer admin");
        expect(listed.status).toBe(200);
        expect(listed.body.byType.wallpaper).toContain("temple-night");
        expect(listed.body.byType.wallpaper).toContain("baba-darshan");
        const duplicate = await request(app)
            .post("/v1/admin/categories")
            .set("Authorization", "Bearer admin")
            .send({ type: "wallpaper", slug: "temple-night" });
        expect(duplicate.status).toBe(409);
        const removed = await request(app)
            .delete(`/v1/admin/categories/${created.body.item.id}`)
            .set("Authorization", "Bearer admin");
        expect(removed.status).toBe(204);
    });
    it("lists users and updates subscription status", async () => {
        await request(app)
            .get("/v1/auth/me")
            .set("Authorization", "Bearer free");
        await request(app)
            .get("/v1/auth/me")
            .set("Authorization", "Bearer admin");
        const list = await request(app)
            .get("/v1/admin/users")
            .set("Authorization", "Bearer admin");
        expect(list.status).toBe(200);
        expect(list.body.total).toBe(2);
        const freeUser = list.body.items.find((item) => item.email === "free@example.com");
        expect(freeUser).toBeTruthy();
        const patched = await request(app)
            .patch(`/v1/admin/users/${freeUser.id}`)
            .set("Authorization", "Bearer admin")
            .send({ subscriptionStatus: "active" });
        expect(patched.status).toBe(200);
        expect(patched.body.user.subscriptionStatus).toBe("active");
    });
    it("presigns library uploads and creates content assets", async () => {
        await request(app)
            .get("/v1/auth/me")
            .set("Authorization", "Bearer admin");
        const presign = await request(app)
            .post("/v1/admin/uploads/presign")
            .set("Authorization", "Bearer admin")
            .send({
            type: "wallpaper",
            category: "baba-darshan",
            contentType: "image/jpeg",
        });
        expect(presign.status).toBe(200);
        expect(presign.body.key).toContain("khatu-shyam/wallpapers/");
        expect(presign.body.uploadUrl).toContain("https://s3.example.com");
        const created = await request(app)
            .post("/v1/admin/content")
            .set("Authorization", "Bearer admin")
            .send({
            slug: "test-baba-darshan-01",
            type: "wallpaper",
            category: "baba-darshan",
            title: { hi: "परीक्षण", en: "Test wallpaper" },
            fileKey: presign.body.key,
            format: "jpg",
            width: 1080,
            height: 1920,
            premium: true,
            status: "published",
        });
        expect(created.status).toBe(201);
        expect(created.body.item.slug).toBe("test-baba-darshan-01");
        expect(created.body.item.url).toContain(presign.body.key);
        // Browse is free; premium is enforced on set/share actions in the app.
        const library = await request(app)
            .get("/v1/content/library?type=wallpaper")
            .set("Authorization", "Bearer premium");
        expect(library.status).toBe(200);
        expect(library.body.items).toHaveLength(1);
    });
    it("serves paginated posters to signed-in free users", async () => {
        await ContentAsset.create({
            slug: "daily-poster-01",
            type: "poster",
            category: "daily",
            title: { hi: "जय श्याम", en: "Jai Shyam" },
            fileKey: "khatu-shyam/posters/daily/daily-poster-01.jpg",
            format: "jpg",
            width: 1080,
            height: 1920,
            premium: false,
            status: "published",
        });
        await ContentAsset.create({
            slug: "daily-poster-02",
            type: "poster",
            category: "daily",
            title: { hi: "बाबा कृपा", en: "Baba Kripa" },
            fileKey: "khatu-shyam/posters/daily/daily-poster-02.jpg",
            format: "jpg",
            premium: false,
            status: "published",
        });
        const unauth = await request(app).get("/v1/content/posters");
        expect(unauth.status).toBe(401);
        const page = await request(app)
            .get("/v1/content/posters?limit=1")
            .set("Authorization", "Bearer free");
        expect(page.status).toBe(200);
        expect(page.body.items).toHaveLength(1);
        expect(page.body.hasMore).toBe(true);
        expect(page.body.nextCursor).toBeTruthy();
        expect(page.body.items[0].url).toContain("khatu-shyam/posters/");
        expect(page.headers["cache-control"]).toContain("max-age=30");
        const next = await request(app)
            .get(`/v1/content/posters?limit=1&cursor=${page.body.nextCursor}`)
            .set("Authorization", "Bearer free");
        expect(next.status).toBe(200);
        expect(next.body.items).toHaveLength(1);
        expect(next.body.items[0].id).not.toBe(page.body.items[0].id);
    });
    it("lets admins edit the public story content", async () => {
        await request(app)
            .get("/v1/auth/me")
            .set("Authorization", "Bearer admin");
        const saved = await request(app)
            .put("/v1/admin/story")
            .set("Authorization", "Bearer admin")
            .send({
            title: { hi: "नई कथा", en: "New Story" },
            summary: { hi: "सारांश", en: "Summary" },
            youtubeVideoId: null,
            chapters: [
                {
                    title: { hi: "अध्याय 1", en: "Chapter 1" },
                    body: {
                        hi: "यह पहला अध्याय है जिसमें श्याम बाबा की कथा है।",
                        en: "This is the first chapter of the Shyam story.",
                    },
                },
            ],
        });
        expect(saved.status).toBe(200);
        expect(saved.body.story.title).toEqual({ hi: "नई कथा", en: "New Story" });
        expect(saved.body.story.chapters).toHaveLength(1);
        const publicStory = await request(app).get("/v1/content/story");
        expect(publicStory.status).toBe(200);
        expect(publicStory.body.title.hi).toBe("नई कथा");
        expect(publicStory.body.chapters[0].title.en).toBe("Chapter 1");
    });
    it("lets admins start and stop live darshan for free clients", async () => {
        await request(app)
            .get("/v1/auth/me")
            .set("Authorization", "Bearer admin");
        const rejected = await request(app)
            .put("/v1/admin/live")
            .set("Authorization", "Bearer admin")
            .send({ isLive: true });
        expect(rejected.status).toBe(400);
        const started = await request(app)
            .put("/v1/admin/live")
            .set("Authorization", "Bearer admin")
            .send({
            isLive: true,
            youtubeVideoId: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            title: {
                hi: "लाइव आरती",
                en: "Live Aarti",
            },
        });
        expect(started.status).toBe(200);
        expect(started.body.live).toMatchObject({
            isLive: true,
            youtubeVideoId: "dQw4w9WgXcQ",
            embedUrl: "https://www.youtube.com/embed/dQw4w9WgXcQ",
            title: { hi: "लाइव आरती", en: "Live Aarti" },
            public: {
                isLive: true,
                youtubeVideoId: "dQw4w9WgXcQ",
                access: "free",
            },
        });
        const publicLive = await request(app).get("/v1/content/live");
        expect(publicLive.status).toBe(200);
        expect(publicLive.body.isLive).toBe(true);
        expect(publicLive.body.youtubeVideoId).toBe("dQw4w9WgXcQ");
        const stopped = await request(app)
            .put("/v1/admin/live")
            .set("Authorization", "Bearer admin")
            .send({ isLive: false });
        expect(stopped.status).toBe(200);
        expect(stopped.body.live.isLive).toBe(false);
        // Admin keeps the saved URL for quick re-enable; public clients see offline.
        expect(stopped.body.live.youtubeVideoId).toBe("dQw4w9WgXcQ");
        expect(stopped.body.live.public.isLive).toBe(false);
        const offline = await request(app).get("/v1/content/live");
        expect(offline.body.isLive).toBe(false);
    });
});
