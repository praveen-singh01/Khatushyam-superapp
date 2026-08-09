export function offersForUser(user) {
    const trialEligible = !user.trialUsed;
    if (trialEligible) {
        return [
            {
                id: "trial_monthly",
                trialPriceInr: 3,
                priceInr: 199,
                period: "month",
            },
        ];
    }
    return [
        {
            id: "weekly",
            priceInr: 49,
            period: "week",
        },
        {
            id: "monthly",
            priceInr: 199,
            period: "month",
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
