import { createHmac, timingSafeEqual } from "node:crypto";
import { Router, type NextFunction, type Request, type RequestHandler, type Response } from "express";
import type { SubscriptionGateway } from "../../shared/ports.js";
import { entitlementFromUser } from "../../shared/ports.js";
import { User } from "../auth/user.model.js";

interface SubscriptionRouterOptions {
  authenticate: RequestHandler;
  keyId: string;
  planId: string;
  gateway: SubscriptionGateway;
}

export function validWebhookSignature(
  rawBody: Buffer,
  signature: string | undefined,
  secret: string,
): boolean {
  if (!signature) return false;
  const expected = createHmac("sha256", secret).update(rawBody).digest("hex");
  const actualBuffer = Buffer.from(signature);
  const expectedBuffer = Buffer.from(expected);
  return (
    actualBuffer.length === expectedBuffer.length &&
    timingSafeEqual(actualBuffer, expectedBuffer)
  );
}

async function startMonthlySubscription(
  options: SubscriptionRouterOptions,
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    if (req.user!.subscriptionStatus === "active") {
      res.status(409).json({ error: "SUBSCRIPTION_ALREADY_ACTIVE" });
      return;
    }

    const subscription = await options.gateway.createMonthlySubscription({
      planId: options.planId,
      userId: req.user!.id,
    });
    await User.findByIdAndUpdate(req.user!.id, {
      subscriptionStatus: "pending",
      razorpaySubscriptionId: subscription.id,
    });
    res.status(201).json(
      entitlementFromUser(
        {
          ...req.user!,
          subscriptionStatus: "pending",
        },
        options.planId,
        {
          subscriptionId: subscription.id,
          keyId: options.keyId,
        },
      ),
    );
  } catch (error) {
    next(error);
  }
}

export function createSubscriptionRouter(
  options: SubscriptionRouterOptions,
): Router {
  const router = Router();

  router.post(
    "/razorpay/monthly",
    options.authenticate,
    (req, res, next) =>
      void startMonthlySubscription(options, req, res, next),
  );

  router.post("/create", options.authenticate, (req, res, next) =>
    void startMonthlySubscription(options, req, res, next),
  );

  return router;
}
