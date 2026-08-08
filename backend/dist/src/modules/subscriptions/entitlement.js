export function toEntitlement(user, planId, extras = {}) {
    const isPremium = user.subscriptionStatus === "active";
    return {
        isPremium,
        planId: isPremium || user.subscriptionStatus === "pending" ? planId : null,
        expiresAt: null,
        source: user.subscriptionStatus === "inactive" ||
            user.subscriptionStatus === "cancelled"
            ? "none"
            : "razorpay",
        subscriptionStatus: user.subscriptionStatus,
        ...extras,
    };
}
