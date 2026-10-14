import type { AuthenticatedUser } from "../../shared/types.js";
import type { UserDocument } from "./user.model.js";

type LeanUser = UserDocument & { _id: { toString(): string } };

export function serializeAuthUser(user: LeanUser): AuthenticatedUser {
  return {
    id: user._id.toString(),
    firebaseUid: user.firebaseUid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoUrl,
    phone: user.phone ?? null,
    onboardingCompleted: Boolean(user.onboardingCompleted),
    role: user.role,
    subscriptionStatus: user.subscriptionStatus,
    trialUsed: Boolean(user.trialUsed),
    currentPlan: user.currentPlan ?? null,
    subscriptionExpiresAt: user.subscriptionExpiresAt
      ? new Date(user.subscriptionExpiresAt).toISOString()
      : null,
  };
}

/** Normalize Indian mobile input to digits-only (+91 stripped). */
export function normalizePhone(raw: string): string {
  let digits = raw.replace(/\D/g, "");
  if (digits.length === 12 && digits.startsWith("91")) {
    digits = digits.slice(2);
  }
  if (digits.length === 11 && digits.startsWith("0")) {
    digits = digits.slice(1);
  }
  return digits;
}

export function isValidPhone(digits: string): boolean {
  return /^[6-9]\d{9}$/.test(digits);
}
