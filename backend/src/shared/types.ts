export type SubscriptionStatus =
  | "inactive"
  | "pending"
  | "active"
  | "halted"
  | "cancelled";

export type UserRole = "user" | "admin";

export interface AuthenticatedUser {
  id: string;
  firebaseUid: string;
  email: string;
  displayName?: string;
  photoUrl?: string;
  role: UserRole;
  subscriptionStatus: SubscriptionStatus;
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
