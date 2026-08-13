import { Schema, model, type Types } from "mongoose";
import type { SubscriptionPlanOffer } from "../../shared/types.js";

export type LocalSubscriptionStatus =
  | "created"
  | "authenticated"
  | "active"
  | "pending"
  | "halted"
  | "cancelled"
  | "completed";

export interface SubscriptionDocument {
  userId: Types.ObjectId;
  plan: SubscriptionPlanOffer | "monthly" | "weekly";
  isActive: boolean;
  isTrial: boolean;
  isTrialPeriod: boolean;
  startDate: Date;
  endDate: Date;
  trialStartTime?: Date | null;
  trialExpiryTime?: Date | null;
  currentEnd?: Date | null;
  razorpaySubscriptionId: string;
  razorpayPlanId: string;
  razorpayPaymentId?: string | null;
  razorpaySignature?: string | null;
  paymentStatus: "pending" | "completed" | "failed";
  subscriptionStatus: LocalSubscriptionStatus;
  cancelledAt?: Date | null;
  version: number;
  createdAt?: Date;
  updatedAt?: Date;
}

const subscriptionSchema = new Schema<SubscriptionDocument>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    plan: {
      type: String,
      enum: ["trial_monthly", "weekly", "monthly"],
      required: true,
    },
    isActive: { type: Boolean, default: false, index: true },
    isTrial: { type: Boolean, default: false },
    isTrialPeriod: { type: Boolean, default: false },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true, index: true },
    trialStartTime: { type: Date, default: null },
    trialExpiryTime: { type: Date, default: null },
    currentEnd: { type: Date, default: null },
    razorpaySubscriptionId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    razorpayPlanId: { type: String, required: true },
    razorpayPaymentId: { type: String, default: null },
    razorpaySignature: { type: String, default: null },
    paymentStatus: {
      type: String,
      enum: ["pending", "completed", "failed"],
      default: "pending",
      index: true,
    },
    subscriptionStatus: {
      type: String,
      enum: [
        "created",
        "authenticated",
        "active",
        "pending",
        "halted",
        "cancelled",
        "completed",
      ],
      default: "created",
      index: true,
    },
    cancelledAt: { type: Date, default: null },
    version: { type: Number, default: 1 },
  },
  { timestamps: true },
);

subscriptionSchema.index({ userId: 1, isActive: 1, endDate: -1 });

export const Subscription = model<SubscriptionDocument>(
  "Subscription",
  subscriptionSchema,
);
