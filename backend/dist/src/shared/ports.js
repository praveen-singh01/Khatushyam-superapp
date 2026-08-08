export function entitlementFromUser(user, planId, extras = {}) {
    const freeMode = extras.freeMode === true;
    const isPremium = freeMode || user.subscriptionStatus === "active";
    const { freeMode: _freeMode, ...rest } = extras;
    return {
        isPremium,
        planId: isPremium || user.subscriptionStatus === "pending" ? planId : null,
        expiresAt: null,
        source: freeMode
            ? "manual"
            : user.subscriptionStatus === "inactive" ||
                user.subscriptionStatus === "cancelled"
                ? "none"
                : "razorpay",
        subscriptionStatus: freeMode ? "active" : user.subscriptionStatus,
        ...rest,
    };
}
