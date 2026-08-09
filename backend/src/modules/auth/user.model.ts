import { Schema, model } from "mongoose";
import type {
  SubscriptionPlanOffer,
  SubscriptionStatus,
  UserRole,
} from "../../shared/types.js";

export interface UserDocument {
  firebaseUid: string;
  email: string;
  displayName?: string;
  photoUrl?: string;
  role: UserRole;
  fcmTokens: string[];
  subscriptionStatus: SubscriptionStatus;
  /** After first trial start/charge/cancel, never offer ₹3 trial again. */
  trialUsed: boolean;
  currentPlan?: SubscriptionPlanOffer | null;
  razorpaySubscriptionId?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

const userSchema = new Schema<UserDocument>(
  {
    firebaseUid: { type: String, required: true, unique: true, index: true },
    email: { type: String, required: true, lowercase: true, trim: true },
    displayName: String,
    photoUrl: String,
    role: {
      type: String,
      enum: ["user", "admin"],
      default: "user",
      index: true,
    },
    fcmTokens: { type: [String], default: [] },
    subscriptionStatus: {
      type: String,
      enum: ["inactive", "pending", "active", "halted", "cancelled"],
      default: "inactive",
      index: true,
    },
    trialUsed: { type: Boolean, default: false, index: true },
    currentPlan: {
      type: String,
      enum: ["trial_monthly", "weekly", "monthly"],
      required: false,
    },
    razorpaySubscriptionId: { type: String, sparse: true, index: true },
  },
  { timestamps: true },
);

export const User = model<UserDocument>("User", userSchema);
