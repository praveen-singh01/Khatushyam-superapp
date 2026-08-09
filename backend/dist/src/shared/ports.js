export function offersForUser(user) {
    // Always show ₹49 / ₹199. ₹3 is only a first-time Razorpay mandate addon.
    const mandateAddonInr = user.trialUsed ? undefined : 3;
    return [
        {
            id: "weekly",
            priceInr: 49,
            period: "week",
            ...(mandateAddonInr !== undefined ? { mandateAddonInr } : {}),
        },
        {
            id: "monthly",
            priceInr: 199,
            period: "month",
            ...(mandateAddonInr !== undefined ? { mandateAddonInr } : {}),
        },
    ];
}
export function entitlementFromUser(user, planId, extras = {}) {
    const freeMode = extras.freeMode === true;
    const isPremium = freeMode || user.subscriptionStatus === "active";
    const trialUsed = Boolean(user.trialUsed);
    const trialEligible = !trialUsed;
    const { freeMode: _freeMode, ...rest } = extras;
    const activePlan = user.currentPlan ??
        (isPremium || user.subscriptionStatus === "pending" ? "monthly" : null);
    return {
        isPremium,
        planId: isPremium || user.subscriptionStatus === "pending"
            ? activePlan ?? planId
            : null,
        expiresAt: null,
        source: freeMode
            ? "manual"
            : user.subscriptionStatus === "inactive" ||
                user.subscriptionStatus === "cancelled"
                ? "none"
                : "razorpay",
        subscriptionStatus: freeMode ? "active" : user.subscriptionStatus,
        trialUsed,
        trialEligible,
        offers: offersForUser({ ...user, trialUsed }),
        ...rest,
    };
}
