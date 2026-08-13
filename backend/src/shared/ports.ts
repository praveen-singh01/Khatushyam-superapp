import { userIsPremium } from "../modules/subscriptions/premium.js";
import type {
  AuthenticatedUser,
  SubscriptionPlanOffer,
} from "./types.js";

export interface SubscriptionCreateResult {
  id: string;
  shortUrl?: string | null;
}

export interface SubscriptionGateway {
  createMonthlySubscription(input: {
    planId: string;
    userId: string;
    planOffer: SubscriptionPlanOffer | "weekly" | "monthly";
    isTrial: boolean;
    /** One-time addon in INR (e.g. ₹3 intro trial). */
    trialAddonInr?: number;
    /** Unix seconds — first recurring charge after trial window. */
    startAtUnix?: number;
    totalCount?: number;
  }): Promise<SubscriptionCreateResult>;

  cancelSubscription(input: {
    razorpaySubscriptionId: string;
    cancelAtCycleEnd?: boolean;
  }): Promise<void>;
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
  // First-time: ₹3 intro trial → then ₹199/month.
  // After trial used (cancel/expiry): ₹49/week + ₹199/month only.
  if (!user.trialUsed) {
    return [
      {
        id: "trial_monthly" as const,
        priceInr: 199,
        period: "month" as const,
        trialPriceInr: 3,
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
    mongoSubscriptionId?: string;
  } = {},
) {
  const freeMode = extras.freeMode === true;
  const isPremium = userIsPremium(user, freeMode);
  const trialUsed = Boolean(user.trialUsed);
  const trialEligible = !trialUsed;
  const { freeMode: _freeMode, ...rest } = extras;
  const activePlan =
    (user.currentPlan as SubscriptionPlanOffer | null | undefined) ??
    (isPremium || user.subscriptionStatus === "pending" ? "monthly" : null);

  const expiresAt = user.subscriptionExpiresAt ?? null;
  let daysRemaining: number | null = null;
  if (isPremium && expiresAt) {
    const ms = new Date(expiresAt).getTime() - Date.now();
    daysRemaining = Math.max(0, Math.ceil(ms / (24 * 60 * 60 * 1000)));
  } else if (isPremium && freeMode) {
    daysRemaining = null;
  }

  return {
    isPremium,
    planId:
      isPremium || user.subscriptionStatus === "pending"
        ? (activePlan ?? planId)
        : null,
    expiresAt,
    daysRemaining,
    source: freeMode
      ? ("manual" as const)
      : user.subscriptionStatus === "inactive" ||
          (user.subscriptionStatus === "cancelled" && !isPremium)
        ? ("none" as const)
        : ("razorpay" as const),
    subscriptionStatus: freeMode ? ("active" as const) : user.subscriptionStatus,
    trialUsed,
    trialEligible,
    offers: offersForUser({ ...user, trialUsed }),
    ...rest,
  };
}
