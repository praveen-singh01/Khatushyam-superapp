import cors from "cors";
import express, {
  type ErrorRequestHandler,
  type RequestHandler,
} from "express";
import helmet from "helmet";
import { existsSync } from "node:fs";
import { pinoHttp } from "pino-http";
import { ZodError } from "zod";
import type { AppEnv } from "./config/env.js";
import {
  authenticate,
  optionalAuthenticate,
  requireAdmin,
  requirePremium,
} from "./middleware/auth.js";
import { createAdminRouter } from "./modules/admin/admin.routes.js";
import { createAuthRouter } from "./modules/auth/auth.routes.js";
import { createChamatkarRouter } from "./modules/chamatkars/chamatkar.routes.js";
import { createContentRouter } from "./modules/content/content.routes.js";
import { createLegalRouter } from "./modules/legal/legal.routes.js";
import { createEntitlementRouter } from "./modules/subscriptions/entitlement.routes.js";
import { createSubscriptionRouter } from "./modules/subscriptions/subscription.routes.js";
import { createRazorpayWebhookHandler } from "./modules/subscriptions/webhook.handler.js";
import { createUploadRouter } from "./modules/uploads/upload.routes.js";
import type { SubscriptionGateway, UploadPresigner } from "./shared/ports.js";
import type { IdentityVerifier } from "./shared/types.js";

export interface AppDependencies {
  env: AppEnv;
  identityVerifier: IdentityVerifier;
  subscriptionGateway: SubscriptionGateway;
  uploadPresigner: UploadPresigner;
}

export function createApp({
  env,
  identityVerifier,
  subscriptionGateway,
  uploadPresigner,
}: AppDependencies) {
  const app = express();
  const auth: RequestHandler = authenticate(identityVerifier, {
    adminEmails: env.ADMIN_EMAILS,
  });
  const subscriptionRouter = createSubscriptionRouter({
    authenticate: auth,
    keyId: env.RAZORPAY_KEY_ID,
    keySecret: env.RAZORPAY_KEY_SECRET,
    planId: env.RAZORPAY_PLAN_ID,
    weeklyPlanId: env.RAZORPAY_PLAN_ID_WEEKLY,
    gateway: subscriptionGateway,
    trialDurationHours: env.TRIAL_DURATION_HOURS,
    trialAmountInr: env.TRIAL_AMOUNT_INR,
    freeMode: env.APP_FREE_MODE,
  });
  const webhookHandler = createRazorpayWebhookHandler(
    env.RAZORPAY_WEBHOOK_SECRET,
  );

  app.disable("x-powered-by");
  // Nginx terminates TLS and forwards X-Forwarded-Proto — needed for https media URLs.
  app.set("trust proxy", 1);
  app.use(helmet());
  app.use(cors({ origin: env.APP_ORIGIN === "*" ? true : env.APP_ORIGIN }));
  if (env.NODE_ENV !== "test") {
    app.use(pinoHttp());
  }

  // Raw body must be preserved for Razorpay signature verification.
  const rawJson = express.raw({
    type: () => true,
    limit: "1mb",
  });
  app.post("/v1/subscriptions/webhook", rawJson, webhookHandler);
  app.post("/api/v1/subscriptions/webhook", rawJson, webhookHandler);

  app.use(express.json({ limit: "1mb" }));

  // Local content pack (wallpapers/ringtones) — production uses CloudFront/S3.
  if (env.MEDIA_LOCAL_ROOT && existsSync(env.MEDIA_LOCAL_ROOT)) {
    app.use(
      "/khatu-shyam-content",
      express.static(env.MEDIA_LOCAL_ROOT, {
        maxAge: "1h",
        fallthrough: true,
      }),
    );
  }

  const health: RequestHandler = (_req, res) => {
    res.json({ status: "ok" });
  };
  app.get("/health", health);
  app.get("/v1/health", health);

  const premiumGate: RequestHandler = env.APP_FREE_MODE
    ? (_req, _res, next) => next()
    : requirePremium;

  const entitlementRouter = createEntitlementRouter(auth, env.RAZORPAY_PLAN_ID, {
    freeMode: env.APP_FREE_MODE,
  });
  const authRouter = createAuthRouter(auth);
  const optionalAuth: RequestHandler = optionalAuthenticate(identityVerifier, {
    adminEmails: env.ADMIN_EMAILS,
  });
  const chamatkarRouter = createChamatkarRouter(auth, optionalAuth);
  const contentRouter = createContentRouter(
    auth,
    premiumGate,
    env.CLOUDFRONT_BASE_URL,
    { useRequestHostForMedia: Boolean(env.MEDIA_LOCAL_ROOT) },
  );
  const uploadRouter = createUploadRouter({
    authenticate: auth,
    requirePremium: premiumGate,
    bucket: env.S3_MEDIA_BUCKET,
    cloudFrontBaseUrl: env.CLOUDFRONT_BASE_URL,
    presigner: uploadPresigner,
  });
  const legalRouter = createLegalRouter({
    authenticate: auth,
    requireAdmin,
  });
  const adminRouter = createAdminRouter({
    authenticate: auth,
    requireAdmin,
    bucket: env.S3_MEDIA_BUCKET,
    cloudFrontBaseUrl: env.CLOUDFRONT_BASE_URL,
    presigner: uploadPresigner,
  });

  app.use("/v1/subscriptions", subscriptionRouter);
  app.use("/api/v1/subscriptions", subscriptionRouter);
  app.use("/v1/entitlement", entitlementRouter);
  app.use("/api/v1/entitlement", entitlementRouter);
  app.use("/v1/auth", authRouter);
  app.use("/api/v1/auth", authRouter);
  app.use("/v1/chamatkars", chamatkarRouter);
  app.use("/api/v1/chamatkars", chamatkarRouter);
  app.use("/v1/content", contentRouter);
  app.use("/api/v1/content", contentRouter);
  app.use("/v1/uploads", uploadRouter);
  app.use("/api/v1/uploads", uploadRouter);
  app.use("/v1/legal", legalRouter);
  app.use("/api/v1/legal", legalRouter);
  app.use("/v1/admin", adminRouter);
  app.use("/api/v1/admin", adminRouter);

  app.use((_req, res) => {
    res.status(404).json({ error: "NOT_FOUND" });
  });

  const errorHandler: ErrorRequestHandler = (error, req, res, _next) => {
    if (env.NODE_ENV !== "test") {
      req.log?.error({ err: error }, "request failed");
    }
    if (error instanceof ZodError) {
      res.status(400).json({
        error: "VALIDATION_ERROR",
        issues: error.issues,
      });
      return;
    }
    res.status(500).json({ error: "INTERNAL_SERVER_ERROR" });
  };
  app.use(errorHandler);

  return app;
}
