import { Schema, model } from "mongoose";

interface WebhookEventDocument {
  provider: "razorpay";
  eventId: string;
  eventType: string;
}

const webhookEventSchema = new Schema<WebhookEventDocument>(
  {
    provider: { type: String, enum: ["razorpay"], required: true },
    eventId: { type: String, required: true },
    eventType: { type: String, required: true },
  },
  { timestamps: true },
);

webhookEventSchema.index({ provider: 1, eventId: 1 }, { unique: true });

export const WebhookEvent = model<WebhookEventDocument>(
  "WebhookEvent",
  webhookEventSchema,
);
