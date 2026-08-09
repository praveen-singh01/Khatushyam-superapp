export type SubscriptionStatus =
  | "inactive"
  | "pending"
  | "active"
  | "halted"
  | "cancelled";

export type UserRole = "user" | "admin";

export type SubscriptionPlanOffer = "trial_monthly" | "weekly" | "monthly";

export interface AuthenticatedUser {
  id: string;
  firebaseUid: string;
  email: string;
  displayName?: string;
  photoUrl?: string;
  role: UserRole;
  subscriptionStatus: SubscriptionStatus;
  /** Once true, the ₹3 intro trial must never be offered again. */
  trialUsed: boolean;
  currentPlan?: SubscriptionPlanOffer | null;
}

export interface VerifiedIdentity {
  uid: string;
  email?: string;
  name?: string;
  picture?: string;
  signInProvider?: string;
}

export interface IdentityVerifier {
  verify(token: string): Promise<VerifiedIdentity>;
}
