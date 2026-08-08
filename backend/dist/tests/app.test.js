import request from "supertest";
import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
const env = {
    NODE_ENV: "test",
    PORT: 4000,
    MONGODB_URI: "mongodb://unused/test",
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
const app = createApp({
    env,
    identityVerifier: {
        verify: async () => ({
            uid: "firebase-user",
            email: "devotee@example.com",
            signInProvider: "google.com",
        }),
    },
});
describe("public API", () => {
    it("reports health on Flutter and legacy paths", async () => {
        const legacy = await request(app).get("/health");
        const flutter = await request(app).get("/v1/health");
        expect(legacy.status).toBe(200);
        expect(flutter.status).toBe(200);
        expect(legacy.body).toEqual({ status: "ok" });
        expect(flutter.body).toEqual({ status: "ok" });
    });
    it("serves the free story without authentication", async () => {
        const response = await request(app).get("/v1/content/story");
        expect(response.status).toBe(200);
        expect(response.body.access).toBe("free");
    });
    it("rejects entitlement without authentication", async () => {
        const response = await request(app).get("/v1/entitlement");
        expect(response.status).toBe(401);
        expect(response.body.error).toBe("AUTH_REQUIRED");
    });
    it("rejects a paid feature without authentication", async () => {
        const response = await request(app).get("/v1/content/premium-manifest");
        expect(response.status).toBe(401);
        expect(response.body.error).toBe("AUTH_REQUIRED");
    });
});
