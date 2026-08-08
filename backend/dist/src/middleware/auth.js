import { User } from "../modules/auth/user.model.js";
function parseAdminEmails(raw) {
    if (!raw)
        return new Set();
    return new Set(raw
        .split(",")
        .map((email) => email.trim().toLowerCase())
        .filter(Boolean));
}
async function resolveUser(verifier, token, adminEmails) {
    const identity = await verifier.verify(token);
    if (identity.signInProvider !== "google.com") {
        const error = new Error("GOOGLE_SIGN_IN_REQUIRED");
        error.code = "GOOGLE_SIGN_IN_REQUIRED";
        throw error;
    }
    if (!identity.email) {
        const error = new Error("GOOGLE_EMAIL_REQUIRED");
        error.code = "GOOGLE_EMAIL_REQUIRED";
        throw error;
    }
    const email = identity.email.toLowerCase();
    const shouldBeAdmin = adminEmails.has(email);
    const setFields = {
        email,
        displayName: identity.name,
        photoUrl: identity.picture,
    };
    if (shouldBeAdmin) {
        setFields.role = "admin";
    }
    const user = await User.findOneAndUpdate({ firebaseUid: identity.uid }, {
        $set: setFields,
        $setOnInsert: {
            subscriptionStatus: "inactive",
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
    };
}
export function authenticate(verifier, options = {}) {
    const adminEmails = parseAdminEmails(options.adminEmails);
    return async (req, res, next) => {
        try {
            const header = req.header("authorization");
            const token = header?.startsWith("Bearer ") ? header.slice(7) : undefined;
            if (!token) {
                res.status(401).json({ error: "AUTH_REQUIRED" });
                return;
            }
            req.user = await resolveUser(verifier, token, adminEmails);
            next();
        }
        catch (error) {
            const code = error instanceof Error && "code" in error
                ? String(error.code)
                : undefined;
            if (code === "GOOGLE_SIGN_IN_REQUIRED") {
                res.status(403).json({ error: "GOOGLE_SIGN_IN_REQUIRED" });
                return;
            }
            if (code === "GOOGLE_EMAIL_REQUIRED") {
                res.status(403).json({ error: "GOOGLE_EMAIL_REQUIRED" });
                return;
            }
            res.status(401).json({ error: "INVALID_AUTH_TOKEN" });
        }
    };
}
/** Attaches req.user when a valid Bearer token is present; never blocks the request. */
export function optionalAuthenticate(verifier, options = {}) {
    const adminEmails = parseAdminEmails(options.adminEmails);
    return async (req, _res, next) => {
        try {
            const header = req.header("authorization");
            const token = header?.startsWith("Bearer ") ? header.slice(7) : undefined;
            if (token) {
                req.user = await resolveUser(verifier, token, adminEmails);
            }
        }
        catch {
            // Public feed stays available even with a bad/expired token.
        }
        next();
    };
}
export const requirePremium = (req, res, next) => {
    if (req.user?.subscriptionStatus !== "active") {
        res.status(402).json({
            error: "PREMIUM_REQUIRED",
            subscriptionStatus: req.user?.subscriptionStatus ?? "inactive",
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
