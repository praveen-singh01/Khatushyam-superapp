import { createHmac, timingSafeEqual } from "node:crypto";
import { Router, } from "express";
import { z } from "zod";
import { entitlementFromUser } from "../../shared/ports.js";
import { User } from "../auth/user.model.js";
const startSchema = z.object({
    // trial_monthly kept as alias → monthly + ₹3 mandate addon
    plan: z.enum(["trial_monthly", "weekly", "monthly"]),
});
export function validWebhookSignature(rawBody, signature, secret) {
    if (!signature)
        return false;
    const expected = createHmac("sha256", secret).update(rawBody).digest("hex");
    const actualBuffer = Buffer.from(signature);
    const expectedBuffer = Buffer.from(expected);
    return (actualBuffer.length === expectedBuffer.length &&
        timingSafeEqual(actualBuffer, expectedBuffer));
}
function resolvePlan(plan) {
    return plan === "weekly" ? "weekly" : "monthly";
}
function razorpayPlanIdFor(plan, options) {
    if (plan === "weekly" && options.weeklyPlanId) {
        return options.weeklyPlanId;
    }
    return options.planId;
}
async function startSubscription(options, requestedPlan, req, res, next) {
    try {
        if (req.user.subscriptionStatus === "active") {
            res.status(409).json({ error: "SUBSCRIPTION_ALREADY_ACTIVE" });
            return;
        }
        const plan = resolvePlan(requestedPlan);
        const trialUsed = Boolean(req.user.trialUsed);
        // First checkout: ₹3 addon sets up UPI/card autopay mandate.
        const mandateAddonInr = trialUsed ? undefined : 3;
        const subscription = await options.gateway.createMonthlySubscription({
            planId: razorpayPlanIdFor(plan, options),
            userId: req.user.id,
            trialAddonInr: mandateAddonInr,
        });
        await User.findByIdAndUpdate(req.user.id, {
            subscriptionStatus: "pending",
            razorpaySubscriptionId: subscription.id,
            currentPlan: plan,
            // First mandate checkout permanently consumes the ₹3 intro.
            ...(!trialUsed ? { trialUsed: true } : {}),
        });
        res.status(201).json(entitlementFromUser({
            ...req.user,
            subscriptionStatus: "pending",
            trialUsed: true,
            currentPlan: plan,
        }, plan, {
            subscriptionId: subscription.id,
            keyId: options.keyId,
        }));
    }
    catch (error) {
        const razorpayError = error;
        if (razorpayError.statusCode && razorpayError.error?.description) {
            res.status(502).json({
                error: "RAZORPAY_ERROR",
                message: razorpayError.error.description,
                code: razorpayError.error.code,
            });
            return;
        }
        next(error);
    }
}
export function createSubscriptionRouter(options) {
    const router = Router();
    router.post("/razorpay/start", options.authenticate, (req, res, next) => {
        const parsed = startSchema.safeParse(req.body ?? {});
        if (!parsed.success) {
            res.status(400).json({ error: "INVALID_PLAN" });
            return;
        }
        void startSubscription(options, parsed.data.plan, req, res, next);
    });
    router.post("/razorpay/monthly", options.authenticate, (req, res, next) => {
        void startSubscription(options, "monthly", req, res, next);
    });
    router.post("/create", options.authenticate, (req, res, next) => {
        void startSubscription(options, "monthly", req, res, next);
    });
    return router;
}
