import { createHmac, timingSafeEqual } from "node:crypto";
import { Router, } from "express";
import { z } from "zod";
import { entitlementFromUser } from "../../shared/ports.js";
import { User } from "../auth/user.model.js";
const startSchema = z.object({
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
function razorpayPlanIdFor(plan, options) {
    if (plan === "weekly" && options.weeklyPlanId) {
        return options.weeklyPlanId;
    }
    return options.planId;
}
async function startSubscription(options, plan, req, res, next) {
    try {
        if (req.user.subscriptionStatus === "active") {
            res.status(409).json({ error: "SUBSCRIPTION_ALREADY_ACTIVE" });
            return;
        }
        const trialUsed = Boolean(req.user.trialUsed);
        if (plan === "trial_monthly" && trialUsed) {
            res.status(400).json({ error: "TRIAL_ALREADY_USED" });
            return;
        }
        if (plan !== "trial_monthly" && !trialUsed) {
            // First-time users must take the intro trial path.
            res.status(400).json({ error: "TRIAL_REQUIRED" });
            return;
        }
        const subscription = await options.gateway.createMonthlySubscription({
            planId: razorpayPlanIdFor(plan, options),
            userId: req.user.id,
        });
        await User.findByIdAndUpdate(req.user.id, {
            subscriptionStatus: "pending",
            razorpaySubscriptionId: subscription.id,
            currentPlan: plan,
            // Starting trial permanently consumes eligibility.
            ...(plan === "trial_monthly" ? { trialUsed: true } : {}),
        });
        res.status(201).json(entitlementFromUser({
            ...req.user,
            subscriptionStatus: "pending",
            trialUsed: plan === "trial_monthly" ? true : trialUsed,
            currentPlan: plan,
        }, plan, {
            subscriptionId: subscription.id,
            keyId: options.keyId,
        }));
    }
    catch (error) {
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
    // Backward-compatible aliases → monthly (post-trial) or trial if eligible.
    router.post("/razorpay/monthly", options.authenticate, (req, res, next) => {
        const plan = req.user.trialUsed
            ? "monthly"
            : "trial_monthly";
        void startSubscription(options, plan, req, res, next);
    });
    router.post("/create", options.authenticate, (req, res, next) => {
        const plan = req.user.trialUsed
            ? "monthly"
            : "trial_monthly";
        void startSubscription(options, plan, req, res, next);
    });
    return router;
}
