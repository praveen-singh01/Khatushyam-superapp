import { createHmac } from "node:crypto";
import type { RequestHandler } from "express";
import { User } from "../auth/user.model.js";
import { validWebhookSignature } from "./subscription.routes.js";
import { WebhookEvent } from "./webhook-event.model.js";

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

      const payload = JSON.parse(rawBody.toString("utf8")) as {
        event: string;
        payload?: {
          subscription?: {
            entity?: { id?: string; status?: string };
          };
        };
      };
      const eventId =
        req.header("x-razorpay-event-id") ??
        createHmac("sha256", webhookSecret).update(rawBody).digest("hex");

      const duplicate = await WebhookEvent.exists({
        provider: "razorpay",
        eventId,
      });
      if (duplicate) {
        res.status(200).json({ received: true, duplicate: true });
        return;
      }

      const subscription = payload.payload?.subscription?.entity;
      const mappedStatus = {
        "subscription.activated": "active",
        "subscription.charged": "active",
        "subscription.halted": "halted",
        "subscription.cancelled": "cancelled",
      }[payload.event];

      if (subscription?.id && mappedStatus) {
        await User.findOneAndUpdate(
          { razorpaySubscriptionId: subscription.id },
          { subscriptionStatus: mappedStatus },
        );
      }
      await WebhookEvent.create({
        provider: "razorpay",
        eventId,
        eventType: payload.event,
      });
      res.status(200).json({ received: true });
    } catch (error) {
      next(error);
    }
  };
}
