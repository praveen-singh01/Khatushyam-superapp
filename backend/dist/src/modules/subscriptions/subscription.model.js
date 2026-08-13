import { Schema, model } from "mongoose";
const subscriptionSchema = new Schema({
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
}, { timestamps: true });
subscriptionSchema.index({ userId: 1, isActive: 1, endDate: -1 });
export const Subscription = model("Subscription", subscriptionSchema);
