export function offersForUser(user) {
    // First-time: ₹3 intro trial → then ₹199/month.
    // After trial used (cancel/expiry): ₹49/week + ₹199/month only.
    if (!user.trialUsed) {
        return [
            {
                id: "trial_monthly",
                priceInr: 199,
                period: "month",
                trialPriceInr: 3,
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
    const expiresAt = user.subscriptionExpiresAt ?? null;
    let daysRemaining = null;
    if (isPremium && expiresAt) {
        const ms = new Date(expiresAt).getTime() - Date.now();
        daysRemaining = Math.max(0, Math.ceil(ms / (24 * 60 * 60 * 1000)));
    }
    else if (isPremium && freeMode) {
        daysRemaining = null;
    }
    return {
        isPremium,
        planId: isPremium || user.subscriptionStatus === "pending"
            ? activePlan ?? planId
            : null,
        expiresAt,
        daysRemaining,
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
