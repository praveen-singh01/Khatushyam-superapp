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
    async createMonthlySubscription({ planId, userId, trialAddonInr }) {
      const payload: {
        plan_id: string;
        total_count: number;
        customer_notify: 0 | 1;
        notes: { userId: string };
        addons?: Array<{
          item: {
            name: string;
            amount: number;
            currency: string;
          };
        }>;
      } = {
        plan_id: planId,
        total_count: 120,
        customer_notify: 1,
        notes: { userId },
      };

      // ₹3 (or other) charged upfront, then recurring plan amount.
      if (trialAddonInr && trialAddonInr > 0) {
        payload.addons = [
          {
            item: {
              name: "Intro trial",
              amount: Math.round(trialAddonInr * 100),
              currency: "INR",
            },
          },
        ];
      }

      const subscription = await razorpay.subscriptions.create(payload);
      return { id: subscription.id };
    },
  };
}
