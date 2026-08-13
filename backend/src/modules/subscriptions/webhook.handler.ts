import { createHmac } from "node:crypto";
import type { RequestHandler } from "express";
import { Types } from "mongoose";
import { User } from "../auth/user.model.js";
import {
  periodDaysForPlan,
  unixToDate,
} from "./premium.js";
import { Subscription } from "./subscription.model.js";
import { validWebhookSignature } from "./subscription.routes.js";
import { WebhookEvent } from "./webhook-event.model.js";

type RazorpayEntity = Record<string, unknown>;

function asEntity(value: unknown): RazorpayEntity | null {
  return value && typeof value === "object"
    ? (value as RazorpayEntity)
    : null;
}

function getString(obj: RazorpayEntity | null, key: string): string {
  const v = obj?.[key];
  return typeof v === "string" ? v : "";
}

function getNumber(obj: RazorpayEntity | null, key: string): number | null {
  const v = obj?.[key];
  return typeof v === "number" && Number.isFinite(v) ? v : null;
}

function getNotes(entity: RazorpayEntity | null): RazorpayEntity | null {
  return asEntity(entity?.notes);
}

function extractSubscription(payload: RazorpayEntity): RazorpayEntity | null {
  const sub = asEntity(payload.payload);
  const entityWrap = asEntity(sub?.subscription);
  return asEntity(entityWrap?.entity) ?? asEntity(sub?.subscription);
}

function extractPayment(payload: RazorpayEntity): RazorpayEntity | null {
  const p = asEntity(payload.payload);
  const entityWrap = asEntity(p?.payment);
  return asEntity(entityWrap?.entity) ?? asEntity(p?.payment);
}

async function findSubscription(razorpaySubscriptionId: string) {
  return Subscription.findOne({ razorpaySubscriptionId });
}

async function resolveUserId(input: {
  notesUserId?: string;
  razorpaySubscriptionId?: string;
}): Promise<string | null> {
  if (
    input.notesUserId &&
    Types.ObjectId.isValid(input.notesUserId) &&
    String(new Types.ObjectId(input.notesUserId)) === input.notesUserId
  ) {
    return input.notesUserId;
  }
  if (!input.razorpaySubscriptionId) return null;
  const sub = await findSubscription(input.razorpaySubscriptionId);
  if (sub?.userId) return sub.userId.toString();
  const legacy = await User.findOne({
    razorpaySubscriptionId: input.razorpaySubscriptionId,
  }).lean();
  return legacy?._id?.toString() ?? null;
}

async function syncUserFromSubscription(input: {
  userId: string;
  status: "authenticated" | "active" | "halted" | "cancelled" | "pending";
  expiresAt?: Date | null;
  trialUsed?: boolean;
  razorpaySubscriptionId?: string;
  currentPlan?: "weekly" | "monthly" | null;
}) {
  const update: Record<string, unknown> = {
    subscriptionStatus: input.status,
  };
  if (input.expiresAt !== undefined) {
    update.subscriptionExpiresAt = input.expiresAt;
  }
  if (input.trialUsed !== undefined) {
    update.trialUsed = input.trialUsed;
  }
  if (input.razorpaySubscriptionId) {
    update.razorpaySubscriptionId = input.razorpaySubscriptionId;
  }
  if (input.currentPlan !== undefined) {
    update.currentPlan = input.currentPlan;
  }
  await User.findByIdAndUpdate(input.userId, { $set: update });
}

export function createRazorpayWebhookHandler(
  webhookSecret: string,
): RequestHandler {
  return async (req, res, next) => {
    try {
      const rawBody = Buffer.isBuffer(req.body)
        ? req.body
        : Buffer.from(typeof req.body === "string" ? req.body : "");

      if (
        !validWebhookSignature(
          rawBody,
          req.header("x-razorpay-signature"),
          webhookSecret,
        )
      ) {
        res.status(400).json({ error: "INVALID_WEBHOOK_SIGNATURE" });
        return;
      }

      const eventId =
        req.header("x-razorpay-event-id") ??
        createHmac("sha256", webhookSecret).update(rawBody).digest("hex");

      // Insert-first idempotency (Mitro pattern) — unique index rejects races.
      try {
        await WebhookEvent.create({
          provider: "razorpay",
          eventId,
          eventType: "pending",
        });
      } catch (error) {
        const code = (error as { code?: number }).code;
        if (code === 11000) {
          res.status(200).json({ received: true, duplicate: true });
          return;
        }
        throw error;
      }

      const payload = JSON.parse(rawBody.toString("utf8")) as RazorpayEntity;
      const event = getString(payload, "event");

      await WebhookEvent.updateOne(
        { provider: "razorpay", eventId },
        { $set: { eventType: event || "unknown" } },
      );

      switch (event) {
        case "payment.captured":
          await handlePaymentCaptured(payload);
          break;
        case "payment.failed":
          await handlePaymentFailed(payload);
          break;
        case "subscription.authenticated":
          await handleSubscriptionAuthenticated(payload);
          break;
        case "subscription.activated":
          await handleSubscriptionActivated(payload);
          break;
        case "subscription.charged":
          await handleSubscriptionCharged(payload);
          break;
        case "subscription.pending":
          await handleSubscriptionStatusOnly(payload, "pending");
          break;
        case "subscription.halted":
          await handleSubscriptionHalted(payload);
          break;
        case "subscription.cancelled":
          await handleSubscriptionCancelled(payload);
          break;
        case "subscription.completed":
          await handleSubscriptionStatusOnly(payload, "completed");
          break;
        case "subscription.updated":
          await handleSubscriptionUpdated(payload);
          break;
        default:
          break;
      }

      res.status(200).json({ received: true });
    } catch (error) {
      next(error);
    }
  };
}

async function handlePaymentCaptured(payload: RazorpayEntity) {
  const payment = extractPayment(payload);
  if (!payment) return;
  const paymentId = getString(payment, "id");
  const amount = getNumber(payment, "amount") ?? 0;
  const notes = getNotes(payment);
  const notesUserId = getString(notes, "user_id");
  // Recurring payments often lack notes — fall back via subscription entity if present.
  const subEntity = extractSubscription(payload);
  const razorpaySubscriptionId = getString(subEntity, "id");
  const subNotes = getNotes(subEntity);
  const userId = await resolveUserId({
    notesUserId: notesUserId || getString(subNotes, "user_id"),
    razorpaySubscriptionId,
  });
  if (!userId) return;

  let sub = razorpaySubscriptionId
    ? await findSubscription(razorpaySubscriptionId)
    : null;
  if (!sub) {
    sub = await Subscription.findOne({
      userId,
      subscriptionStatus: { $in: ["created", "authenticated", "pending"] },
    }).sort({ createdAt: -1 });
  }
  if (!sub) return;

  const now = new Date();
  const isTrialPayment = amount > 0 && amount <= 400; // ≤ ₹4 in paise
  let premiumExpiresAt = sub.endDate;
  if (
    isTrialPayment &&
    sub.trialExpiryTime &&
    now.getTime() < sub.trialExpiryTime.getTime()
  ) {
    premiumExpiresAt = sub.trialExpiryTime;
  } else if (sub.currentEnd) {
    premiumExpiresAt = sub.currentEnd;
  }

  sub.razorpayPaymentId = paymentId || sub.razorpayPaymentId;
  sub.paymentStatus = "completed";
  sub.isActive = true;
  sub.subscriptionStatus = "active";
  sub.version += 1;
  await sub.save();

  await syncUserFromSubscription({
    userId,
    status: "active",
    expiresAt: premiumExpiresAt,
    trialUsed: isTrialPayment || sub.isTrial ? true : undefined,
    razorpaySubscriptionId: sub.razorpaySubscriptionId,
    currentPlan: sub.plan === "weekly" ? "weekly" : "monthly",
  });
}

async function handlePaymentFailed(payload: RazorpayEntity) {
  const payment = extractPayment(payload);
  const subEntity = extractSubscription(payload);
  const razorpaySubscriptionId = getString(subEntity, "id");
  const notes = getNotes(subEntity) ?? getNotes(payment);
  const userId = await resolveUserId({
    notesUserId: getString(notes, "user_id"),
    razorpaySubscriptionId,
  });
  if (!razorpaySubscriptionId) return;
  const sub = await findSubscription(razorpaySubscriptionId);
  if (!sub) return;
  sub.paymentStatus = "failed";
  sub.version += 1;
  await sub.save();
  if (userId && !sub.isActive) {
    await syncUserFromSubscription({
      userId,
      status: "pending",
      razorpaySubscriptionId,
    });
  }
}

async function handleSubscriptionAuthenticated(payload: RazorpayEntity) {
  const entity = extractSubscription(payload);
  if (!entity) return;
  const razorpaySubscriptionId = getString(entity, "id");
  const notes = getNotes(entity);
  const userId = await resolveUserId({
    notesUserId: getString(notes, "user_id"),
    razorpaySubscriptionId,
  });
  const sub = await findSubscription(razorpaySubscriptionId);
  if (!sub) return;
  sub.subscriptionStatus = "authenticated";
  sub.version += 1;
  await sub.save();
  if (userId) {
    await syncUserFromSubscription({
      userId,
      status: "authenticated",
      razorpaySubscriptionId,
    });
  }
}

async function handleSubscriptionActivated(payload: RazorpayEntity) {
  const entity = extractSubscription(payload);
  if (!entity) return;
  const razorpaySubscriptionId = getString(entity, "id");
  const notes = getNotes(entity);
  let userId = await resolveUserId({
    notesUserId: getString(notes, "user_id"),
    razorpaySubscriptionId,
  });
  if (!userId && razorpaySubscriptionId) {
    const legacy = await User.findOne({ razorpaySubscriptionId }).lean();
    userId = legacy?._id?.toString() ?? null;
  }
  const sub = await findSubscription(razorpaySubscriptionId);
  const currentEnd = unixToDate(getNumber(entity, "current_end"));
  const now = new Date();
  const fallbackEnd =
    currentEnd ??
    new Date(now.getTime() + periodDaysForPlan("monthly") * 86400000);

  if (sub) {
    sub.isActive = true;
    sub.subscriptionStatus = "active";
    if (currentEnd) {
      sub.currentEnd = currentEnd;
      sub.endDate = currentEnd;
    }
    sub.version += 1;
    await sub.save();
  }
  if (!userId) return;

  await syncUserFromSubscription({
    userId,
    status: "active",
    expiresAt: sub ? (currentEnd ?? sub.endDate ?? now) : fallbackEnd,
    trialUsed: sub?.isTrial ? true : undefined,
    razorpaySubscriptionId,
    currentPlan: sub?.plan === "weekly" ? "weekly" : "monthly",
  });
}

async function handleSubscriptionCharged(payload: RazorpayEntity) {
  const entity = extractSubscription(payload);
  if (!entity) return;
  const razorpaySubscriptionId = getString(entity, "id");
  const notes = getNotes(entity);
  let userId = await resolveUserId({
    notesUserId: getString(notes, "user_id"),
    razorpaySubscriptionId,
  });
  if (!userId && razorpaySubscriptionId) {
    const legacy = await User.findOne({ razorpaySubscriptionId }).lean();
    userId = legacy?._id?.toString() ?? null;
  }
  const sub = await findSubscription(razorpaySubscriptionId);
  if (!userId) return;

  let currentEnd = unixToDate(getNumber(entity, "current_end"));
  if (!currentEnd) {
    const days = periodDaysForPlan(
      sub?.plan === "weekly" ? "weekly" : "monthly",
    );
    currentEnd = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
  }

  if (sub) {
    sub.isActive = true;
    sub.isTrialPeriod = false;
    sub.subscriptionStatus = "active";
    sub.paymentStatus = "completed";
    sub.currentEnd = currentEnd;
    sub.endDate = currentEnd;
    sub.version += 1;
    await sub.save();
  }

  await syncUserFromSubscription({
    userId,
    status: "active",
    expiresAt: currentEnd,
    trialUsed: true,
    razorpaySubscriptionId,
    currentPlan: sub?.plan === "weekly" ? "weekly" : "monthly",
  });
}

async function handleSubscriptionHalted(payload: RazorpayEntity) {
  const entity = extractSubscription(payload);
  if (!entity) return;
  const razorpaySubscriptionId = getString(entity, "id");
  const notes = getNotes(entity);
  let userId = await resolveUserId({
    notesUserId: getString(notes, "user_id"),
    razorpaySubscriptionId,
  });
  if (!userId && razorpaySubscriptionId) {
    const legacy = await User.findOne({ razorpaySubscriptionId }).lean();
    userId = legacy?._id?.toString() ?? null;
  }
  const sub = await findSubscription(razorpaySubscriptionId);
  const now = new Date();
  if (sub) {
    sub.isActive = false;
    sub.subscriptionStatus = "halted";
    sub.version += 1;
    await sub.save();
  }
  if (userId) {
    // Halt = revoke premium immediately (Mitro).
    await syncUserFromSubscription({
      userId,
      status: "halted",
      expiresAt: now,
      razorpaySubscriptionId,
    });
  }
}

async function handleSubscriptionCancelled(payload: RazorpayEntity) {
  const entity = extractSubscription(payload);
  if (!entity) return;
  const razorpaySubscriptionId = getString(entity, "id");
  const notes = getNotes(entity);
  let userId = await resolveUserId({
    notesUserId: getString(notes, "user_id"),
    razorpaySubscriptionId,
  });
  if (!userId && razorpaySubscriptionId) {
    const legacy = await User.findOne({ razorpaySubscriptionId }).lean();
    userId = legacy?._id?.toString() ?? null;
  }
  const sub = await findSubscription(razorpaySubscriptionId);
  const now = new Date();
  if (!userId) return;

  if (!sub) {
    // Legacy user-only: revoke immediately on cancel webhook.
    await syncUserFromSubscription({
      userId,
      status: "cancelled",
      expiresAt: now,
      trialUsed: true,
      razorpaySubscriptionId,
    });
    return;
  }

  const keepUntil =
    (sub.currentEnd && sub.currentEnd.getTime() > now.getTime()
      ? sub.currentEnd
      : null) ??
    (sub.endDate.getTime() > now.getTime() ? sub.endDate : null) ??
    (sub.isTrialPeriod &&
    sub.trialExpiryTime &&
    sub.trialExpiryTime.getTime() > now.getTime()
      ? sub.trialExpiryTime
      : null);

  const stillActive = Boolean(keepUntil);
  sub.subscriptionStatus = "cancelled";
  sub.cancelledAt = now;
  sub.isActive = stillActive;
  sub.version += 1;
  await sub.save();

  if (stillActive && keepUntil) {
    // Keep premium until cycle/trial end — isPremium stays true via expiresAt.
    await syncUserFromSubscription({
      userId,
      status: "cancelled",
      expiresAt: keepUntil,
      trialUsed: true,
      razorpaySubscriptionId,
    });
  } else {
    await syncUserFromSubscription({
      userId,
      status: "cancelled",
      expiresAt: now,
      trialUsed: true,
      razorpaySubscriptionId,
    });
  }
}

async function handleSubscriptionStatusOnly(
  payload: RazorpayEntity,
  status: "pending" | "completed",
) {
  const entity = extractSubscription(payload);
  if (!entity) return;
  const razorpaySubscriptionId = getString(entity, "id");
  const sub = await findSubscription(razorpaySubscriptionId);
  if (!sub) return;
  sub.subscriptionStatus = status;
  if (status === "completed") {
    sub.isActive = false;
  }
  sub.version += 1;
  await sub.save();
}

async function handleSubscriptionUpdated(payload: RazorpayEntity) {
  const entity = extractSubscription(payload);
  if (!entity) return;
  const razorpaySubscriptionId = getString(entity, "id");
  const status = getString(entity, "status");
  const sub = await findSubscription(razorpaySubscriptionId);
  if (!sub || !status) return;
  if (
    status === "active" ||
    status === "authenticated" ||
    status === "pending" ||
    status === "halted" ||
    status === "cancelled" ||
    status === "completed"
  ) {
    sub.subscriptionStatus = status;
    sub.version += 1;
    await sub.save();
  }
}
