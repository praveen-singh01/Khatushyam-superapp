import type {
  AuthenticatedUser,
  SubscriptionPlanOffer,
} from "./types.js";

export interface SubscriptionCreateResult {
  id: string;
}

export interface SubscriptionGateway {
  createMonthlySubscription(input: {
    planId: string;
    userId: string;
    /** Optional one-time addon in INR (e.g. ₹3 intro trial). */
    trialAddonInr?: number;
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

export function offersForUser(user: AuthenticatedUser) {
  const trialEligible = !user.trialUsed;
  if (trialEligible) {
    return [
      {
        id: "trial_monthly" as const,
        trialPriceInr: 3,
        priceInr: 199,
        period: "month" as const,
      },
    ];
  }
  return [
    {
      id: "weekly" as const,
      priceInr: 49,
      period: "week" as const,
    },
    {
      id: "monthly" as const,
      priceInr: 199,
      period: "month" as const,
    },
  ];
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
  const trialUsed = Boolean(user.trialUsed);
  const trialEligible = !trialUsed;
  const { freeMode: _freeMode, ...rest } = extras;
  const activePlan =
    (user.currentPlan as SubscriptionPlanOffer | null | undefined) ??
    (isPremium || user.subscriptionStatus === "pending" ? "monthly" : null);

  return {
    isPremium,
    planId:
      isPremium || user.subscriptionStatus === "pending"
        ? activePlan ?? planId
        : null,
    expiresAt: null as string | null,
    source: freeMode
      ? ("manual" as const)
      : user.subscriptionStatus === "inactive" ||
          user.subscriptionStatus === "cancelled"
        ? ("none" as const)
        : ("razorpay" as const),
    subscriptionStatus: freeMode ? ("active" as const) : user.subscriptionStatus,
    trialUsed,
    trialEligible,
    offers: offersForUser({ ...user, trialUsed }),
    ...rest,
  };
}
