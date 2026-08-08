import { Schema, model } from "mongoose";
const webhookEventSchema = new Schema({
    provider: { type: String, enum: ["razorpay"], required: true },
    eventId: { type: String, required: true },
    eventType: { type: String, required: true },
}, { timestamps: true });
webhookEventSchema.index({ provider: 1, eventId: 1 }, { unique: true });
export const WebhookEvent = model("WebhookEvent", webhookEventSchema);
