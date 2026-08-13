import { createHmac, timingSafeEqual } from "node:crypto";
import { Router, } from "express";
import { z } from "zod";
import { entitlementFromUser } from "../../shared/ports.js";
import { User } from "../auth/user.model.js";
import { periodDaysForPlan, userIsPremium, } from "./premium.js";
import { Subscription } from "./subscription.model.js";
const startSchema = z.object({
    plan: z.enum(["trial_monthly", "weekly", "monthly"]),
});
const verifySchema = z.object({
    razorpaySubscriptionId: z.string().min(1),
    razorpayPaymentId: z.string().min(1),
    razorpaySignature: z.string().min(1),
    /** Optional Mongo subscription _id from create response. */
    subscriptionId: z.string().optional(),
});
const cancelSchema = z.object({
    reason: z.string().trim().max(500).optional(),
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
export function validPaymentSignature(input) {
    const data = `${input.paymentId}|${input.subscriptionId}`;
    const expected = createHmac("sha256", input.keySecret)
        .update(data)
        .digest("hex");
    const actualBuffer = Buffer.from(input.signature);
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
        const user = req.user;
        if (userIsPremium(user, options.freeMode)) {
            res.status(409).json({ error: "SUBSCRIPTION_ALREADY_ACTIVE" });
            return;
        }
        // Block duplicate in-flight / active period subscriptions.
        const existingOpen = await Subscription.countDocuments({
            userId: user.id,
            subscriptionStatus: {
                $in: ["created", "authenticated", "active", "pending"],
            },
            endDate: { $gte: new Date() },
        });
        if (existingOpen > 0) {
            res.status(409).json({ error: "SUBSCRIPTION_ALREADY_ACTIVE" });
            return;
        }
        const plan = resolvePlan(requestedPlan);
        const trialUsed = Boolean(user.trialUsed);
        const isTrial = !trialUsed && plan === "monthly";
        const trialAddonInr = isTrial ? options.trialAmountInr : undefined;
        const now = new Date();
        const trialExpiry = isTrial
            ? new Date(now.getTime() + options.trialDurationHours * 60 * 60 * 1000)
            : null;
        const startAtUnix = trialExpiry
            ? Math.floor(trialExpiry.getTime() / 1000)
            : undefined;
        const durationDays = periodDaysForPlan(plan);
        const provisionalEnd = isTrial
            ? trialExpiry
            : new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);
        const razorpayPlanId = razorpayPlanIdFor(plan, options);
        const created = await options.gateway.createMonthlySubscription({
            planId: razorpayPlanId,
            userId: user.id,
            planOffer: isTrial ? "trial_monthly" : plan,
            isTrial,
            trialAddonInr,
            startAtUnix,
            totalCount: 120,
        });
        const offerPlan = isTrial
            ? "trial_monthly"
            : plan;
        const doc = await Subscription.create({
            userId: user.id,
            plan: offerPlan,
            isActive: false,
            isTrial,
            isTrialPeriod: isTrial,
            startDate: now,
            endDate: provisionalEnd,
            trialStartTime: isTrial ? now : null,
            trialExpiryTime: trialExpiry,
            currentEnd: null,
            razorpaySubscriptionId: created.id,
            razorpayPlanId,
            paymentStatus: "pending",
            subscriptionStatus: "created",
            version: 1,
        });
        await User.findByIdAndUpdate(user.id, {
            subscriptionStatus: "pending",
            razorpaySubscriptionId: created.id,
            currentPlan: plan,
            // trialUsed set on verify / successful charge — not on checkout start.
        });
        res.status(201).json(entitlementFromUser({
            ...user,
            subscriptionStatus: "pending",
            trialUsed,
            currentPlan: plan,
        }, plan, {
            subscriptionId: created.id,
            keyId: options.keyId,
            mongoSubscriptionId: doc._id.toString(),
            freeMode: options.freeMode,
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
async function verifyPayment(options, req, res, next) {
    try {
        const parsed = verifySchema.safeParse(req.body ?? {});
        if (!parsed.success) {
            res.status(400).json({ error: "INVALID_VERIFY_PAYLOAD" });
            return;
        }
        const { razorpaySubscriptionId, razorpayPaymentId, razorpaySignature, } = parsed.data;
        if (!validPaymentSignature({
            paymentId: razorpayPaymentId,
            subscriptionId: razorpaySubscriptionId,
            signature: razorpaySignature,
            keySecret: options.keySecret,
        })) {
            res.status(400).json({ error: "INVALID_PAYMENT_SIGNATURE" });
            return;
        }
        const user = req.user;
        const sub = await Subscription.findOne({
            userId: user.id,
            razorpaySubscriptionId,
        });
        if (!sub) {
            res.status(404).json({ error: "SUBSCRIPTION_NOT_FOUND" });
            return;
        }
        // Idempotent success
        if (sub.paymentStatus === "completed" &&
            sub.razorpayPaymentId === razorpayPaymentId) {
            const fresh = await User.findById(user.id).lean();
            res.json(entitlementFromUser({
                ...user,
                subscriptionStatus: fresh?.subscriptionStatus ?? "authenticated",
                trialUsed: Boolean(fresh?.trialUsed ?? user.trialUsed),
                currentPlan: fresh?.currentPlan ?? user.currentPlan,
                subscriptionExpiresAt: fresh?.subscriptionExpiresAt
                    ? new Date(fresh.subscriptionExpiresAt).toISOString()
                    : user.subscriptionExpiresAt,
            }, resolvePlan(fresh?.currentPlan ?? "monthly"), { freeMode: options.freeMode }));
            return;
        }
        if (sub.paymentStatus !== "pending") {
            res.status(400).json({ error: "PAYMENT_ALREADY_PROCESSED" });
            return;
        }
        const now = new Date();
        let premiumExpiresAt = sub.endDate;
        if (sub.isTrial &&
            sub.trialExpiryTime &&
            now.getTime() < sub.trialExpiryTime.getTime()) {
            premiumExpiresAt = sub.trialExpiryTime;
        }
        else if (sub.currentEnd) {
            premiumExpiresAt = sub.currentEnd;
        }
        sub.isActive = true;
        sub.razorpayPaymentId = razorpayPaymentId;
        sub.razorpaySignature = razorpaySignature;
        sub.paymentStatus = "completed";
        sub.subscriptionStatus = "authenticated";
        sub.version += 1;
        await sub.save();
        await User.findByIdAndUpdate(user.id, {
            subscriptionStatus: "authenticated",
            trialUsed: sub.isTrial ? true : user.trialUsed,
            subscriptionExpiresAt: premiumExpiresAt,
            razorpaySubscriptionId,
            currentPlan: resolvePlan(sub.plan),
        });
        res.json(entitlementFromUser({
            ...user,
            subscriptionStatus: "authenticated",
            trialUsed: sub.isTrial ? true : user.trialUsed,
            currentPlan: resolvePlan(sub.plan),
            subscriptionExpiresAt: premiumExpiresAt.toISOString(),
        }, resolvePlan(sub.plan), { freeMode: options.freeMode }));
    }
    catch (error) {
        next(error);
    }
}
async function cancelSubscription(options, req, res, next) {
    try {
        cancelSchema.parse(req.body ?? {});
        const user = req.user;
        const now = new Date();
        const sub = await Subscription.findOne({
            userId: user.id,
            isActive: true,
            endDate: { $gte: now },
        }).sort({ endDate: -1 });
        if (!sub) {
            res.status(404).json({ error: "NO_ACTIVE_SUBSCRIPTION" });
            return;
        }
        try {
            await options.gateway.cancelSubscription({
                razorpaySubscriptionId: sub.razorpaySubscriptionId,
                cancelAtCycleEnd: true,
            });
        }
        catch (error) {
            // Still mark local cancel; Razorpay may already be cancelled.
            console.error("Razorpay cancel failed", error);
        }
        sub.subscriptionStatus = "cancelled";
        sub.cancelledAt = now;
        sub.version += 1;
        // Keep isActive until cycle end (Mitro cancel_at_cycle_end).
        if (sub.endDate.getTime() <= now.getTime()) {
            sub.isActive = false;
        }
        await sub.save();
        let expiresAt = sub.currentEnd ?? sub.endDate;
        if (sub.isTrialPeriod &&
            sub.trialExpiryTime &&
            now.getTime() < sub.trialExpiryTime.getTime()) {
            expiresAt = sub.trialExpiryTime;
        }
        await User.findByIdAndUpdate(user.id, {
            subscriptionStatus: "cancelled",
            subscriptionExpiresAt: expiresAt,
            trialUsed: true,
        });
        const fresh = await User.findById(user.id).lean();
        res.json({
            ...entitlementFromUser({
                ...user,
                subscriptionStatus: "cancelled",
                trialUsed: true,
                subscriptionExpiresAt: expiresAt.toISOString(),
                currentPlan: fresh?.currentPlan ?? user.currentPlan,
            }, resolvePlan(fresh?.currentPlan ?? "monthly"), { freeMode: options.freeMode }),
            message: expiresAt.getTime() > now.getTime()
                ? `Subscription cancelled. Premium access will end at ${expiresAt.toISOString()}`
                : "Subscription cancelled",
        });
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
    router.post("/razorpay/monthly", options.authenticate, (req, res, next) => {
        void startSubscription(options, "monthly", req, res, next);
    });
    router.post("/create", options.authenticate, (req, res, next) => {
        const parsed = startSchema.safeParse(req.body ?? { plan: "monthly" });
        const plan = parsed.success ? parsed.data.plan : "monthly";
        void startSubscription(options, plan, req, res, next);
    });
    router.post("/verify", options.authenticate, (req, res, next) => {
        void verifyPayment(options, req, res, next);
    });
    router.post("/cancel", options.authenticate, (req, res, next) => {
        void cancelSubscription(options, req, res, next);
    });
    router.get("/status", options.authenticate, (req, res) => {
        res.json(entitlementFromUser(req.user, options.planId, {
            freeMode: options.freeMode,
        }));
    });
    return router;
}
