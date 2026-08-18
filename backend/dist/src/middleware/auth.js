import { User } from "../modules/auth/user.model.js";
import { computeIsPremium } from "../modules/subscriptions/premium.js";
function parseAdminEmails(raw) {
    if (!raw)
        return new Set();
    return new Set(raw
        .split(",")
        .map((email) => email.trim().toLowerCase())
        .filter(Boolean));
}
/** Far-future expiry for Play reviewer / QA premium backdoor accounts. */
const PREMIUM_TEST_EXPIRES_AT = new Date("2099-12-31T23:59:59.000Z");
async function resolveUser(verifier, token, adminEmails, premiumTestEmails) {
    const identity = await verifier.verify(token);
    const allowedProviders = new Set(["google.com", "password"]);
    if (!identity.signInProvider ||
        !allowedProviders.has(identity.signInProvider)) {
        const error = new Error("UNSUPPORTED_SIGN_IN_PROVIDER");
        error.code = "UNSUPPORTED_SIGN_IN_PROVIDER";
        throw error;
    }
    if (!identity.email) {
        const error = new Error("EMAIL_REQUIRED");
        error.code = "EMAIL_REQUIRED";
        throw error;
    }
    const email = identity.email.toLowerCase();
    const shouldBeAdmin = adminEmails.has(email);
    const shouldBePremium = premiumTestEmails.has(email);
    const setFields = {
        email,
        displayName: identity.name,
        photoUrl: identity.picture,
    };
    if (shouldBeAdmin) {
        setFields.role = "admin";
    }
    if (shouldBePremium) {
        setFields.subscriptionStatus = "active";
        setFields.currentPlan = "monthly";
        setFields.subscriptionExpiresAt = PREMIUM_TEST_EXPIRES_AT;
        setFields.trialUsed = true;
    }
    const user = await User.findOneAndUpdate({ firebaseUid: identity.uid }, {
        $set: setFields,
        $setOnInsert: {
            ...(shouldBePremium
                ? {}
                : {
                    subscriptionStatus: "inactive",
                    trialUsed: false,
                }),
            ...(shouldBeAdmin ? {} : { role: "user" }),
        },
    }, { new: true, upsert: true }).lean();
    return {
        id: user._id.toString(),
        firebaseUid: user.firebaseUid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        role: user.role ?? "user",
        subscriptionStatus: user.subscriptionStatus,
        trialUsed: Boolean(user.trialUsed),
        currentPlan: user.currentPlan ?? null,
        subscriptionExpiresAt: user.subscriptionExpiresAt
            ? new Date(user.subscriptionExpiresAt).toISOString()
            : null,
    };
}
export function authenticate(verifier, options = {}) {
    const adminEmails = parseAdminEmails(options.adminEmails);
    const premiumTestEmails = parseAdminEmails(options.premiumTestEmails);
    return async (req, res, next) => {
        try {
            const header = req.header("authorization");
            const token = header?.startsWith("Bearer ") ? header.slice(7) : undefined;
            if (!token) {
                res.status(401).json({ error: "AUTH_REQUIRED" });
                return;
            }
            req.user = await resolveUser(verifier, token, adminEmails, premiumTestEmails);
            next();
        }
        catch (error) {
            const code = error instanceof Error && "code" in error
                ? String(error.code)
                : undefined;
            if (code === "UNSUPPORTED_SIGN_IN_PROVIDER") {
                res.status(403).json({ error: "UNSUPPORTED_SIGN_IN_PROVIDER" });
                return;
            }
            if (code === "EMAIL_REQUIRED") {
                res.status(403).json({ error: "EMAIL_REQUIRED" });
                return;
            }
            res.status(401).json({ error: "INVALID_AUTH_TOKEN" });
        }
    };
}
/** Attaches req.user when a valid Bearer token is present; never blocks the request. */
export function optionalAuthenticate(verifier, options = {}) {
    const adminEmails = parseAdminEmails(options.adminEmails);
    const premiumTestEmails = parseAdminEmails(options.premiumTestEmails);
    return async (req, _res, next) => {
        try {
            const header = req.header("authorization");
            const token = header?.startsWith("Bearer ") ? header.slice(7) : undefined;
            if (token) {
                req.user = await resolveUser(verifier, token, adminEmails, premiumTestEmails);
            }
        }
        catch {
            // Public feed stays available even with a bad/expired token.
        }
        next();
    };
}
export const requirePremium = (req, res, next) => {
    const user = req.user;
    const premium = user
        ? computeIsPremium({
            subscriptionStatus: user.subscriptionStatus,
            subscriptionExpiresAt: user.subscriptionExpiresAt,
        })
        : false;
    if (!premium) {
        res.status(402).json({
            error: "PREMIUM_REQUIRED",
            subscriptionStatus: user?.subscriptionStatus ?? "inactive",
        });
        return;
    }
    next();
};
export const requireAdmin = (req, res, next) => {
    if (req.user?.role !== "admin") {
        res.status(403).json({ error: "ADMIN_REQUIRED" });
        return;
    }
    next();
};
