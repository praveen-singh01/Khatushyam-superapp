import type { AuthenticatedUser } from "./types.js";

export interface SubscriptionCreateResult {
  id: string;
}

export interface SubscriptionGateway {
  createMonthlySubscription(input: {
    planId: string;
    userId: string;
  }): Promise<SubscriptionCreateResult>;
}

export interface UploadPresigner {
  createUploadUrl(input: {
    bucket: string;
    key: string;
    contentType: string;
    metadata: Record<string, string>;
    expiresInSeconds: number;
  }): Promise<string>;
}

export function entitlementFromUser(
  user: AuthenticatedUser,
  planId: string,
  extras: {
    subscriptionId?: string;
    keyId?: string;
    freeMode?: boolean;
  } = {},
) {
  const freeMode = extras.freeMode === true;
  const isPremium = freeMode || user.subscriptionStatus === "active";
  const { freeMode: _freeMode, ...rest } = extras;
  return {
    isPremium,
    planId: isPremium || user.subscriptionStatus === "pending" ? planId : null,
    expiresAt: null as string | null,
    source: freeMode
      ? ("manual" as const)
      : user.subscriptionStatus === "inactive" ||
          user.subscriptionStatus === "cancelled"
        ? ("none" as const)
        : ("razorpay" as const),
    subscriptionStatus: freeMode ? ("active" as const) : user.subscriptionStatus,
    ...rest,
  };
}
