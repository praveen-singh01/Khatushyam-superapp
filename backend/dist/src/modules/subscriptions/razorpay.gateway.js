import Razorpay from "razorpay";
export function createRazorpayGateway(input) {
    const razorpay = new Razorpay({
        key_id: input.keyId,
        key_secret: input.keySecret,
    });
    return {
        async createMonthlySubscription({ planId, userId }) {
            const subscription = await razorpay.subscriptions.create({
                plan_id: planId,
                total_count: 120,
                customer_notify: 1,
                notes: { userId },
            });
            return { id: subscription.id };
        },
    };
}
