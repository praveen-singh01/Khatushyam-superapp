import Razorpay from "razorpay";
import type { SubscriptionGateway } from "../../shared/ports.js";

export function createRazorpayGateway(input: {
  keyId: string;
  keySecret: string;
}): SubscriptionGateway {
  const razorpay = new Razorpay({
    key_id: input.keyId,
    key_secret: input.keySecret,
  });

  return {
    async createMonthlySubscription({
      planId,
      userId,
      planOffer,
      isTrial,
      trialAddonInr,
      startAtUnix,
      totalCount = 120,
    }) {
      const payload: {
        plan_id: string;
        total_count: number;
        quantity: number;
        customer_notify: 0 | 1;
        notes: Record<string, string>;
        start_at?: number;
        addons?: Array<{
          item: {
            name: string;
            amount: number;
            currency: string;
          };
        }>;
      } = {
        plan_id: planId,
        total_count: totalCount,
        quantity: 1,
        customer_notify: 1,
        notes: {
          user_id: userId,
          plan_id: planOffer,
          is_trial: isTrial ? "true" : "false",
          app: "khatu-shyam",
        },
      };

      if (isTrial && startAtUnix && startAtUnix > 0) {
        payload.start_at = startAtUnix;
      }

      if (trialAddonInr && trialAddonInr > 0) {
        payload.addons = [
          {
            item: {
              name: isTrial ? "Trial Access Fee" : "Intro trial",
              amount: Math.round(trialAddonInr * 100),
              currency: "INR",
            },
          },
        ];
      }

      const subscription = await razorpay.subscriptions.create(payload);
      return {
        id: String(subscription.id),
        shortUrl:
          typeof subscription.short_url === "string"
            ? subscription.short_url
            : null,
      };
    },

    async cancelSubscription({
      razorpaySubscriptionId,
      cancelAtCycleEnd = true,
    }) {
      await razorpay.subscriptions.cancel(
        razorpaySubscriptionId,
        cancelAtCycleEnd ? 1 : 0,
      );
    },
  };
}
