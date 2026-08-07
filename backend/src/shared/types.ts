export type SubscriptionStatus =
  | "inactive"
  | "pending"
  | "active"
  | "halted"
  | "cancelled";

export interface AuthenticatedUser {
  id: string;
  firebaseUid: string;
  email: string;
  displayName?: string;
  photoUrl?: string;
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
