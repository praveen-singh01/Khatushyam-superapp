import type { NextFunction, Request, RequestHandler, Response } from "express";
import type { IdentityVerifier, UserRole } from "../shared/types.js";
import { User } from "../modules/auth/user.model.js";

function parseAdminEmails(raw?: string): Set<string> {
  if (!raw) return new Set();
  return new Set(
    raw
      .split(",")
      .map((email) => email.trim().toLowerCase())
      .filter(Boolean),
  );
}

async function resolveUser(
  verifier: IdentityVerifier,
  token: string,
  adminEmails: Set<string>,
) {
  const identity = await verifier.verify(token);
  const allowedProviders = new Set(["google.com", "password"]);
  if (
    !identity.signInProvider ||
    !allowedProviders.has(identity.signInProvider)
  ) {
    const error = new Error("UNSUPPORTED_SIGN_IN_PROVIDER");
    (error as Error & { code: string }).code = "UNSUPPORTED_SIGN_IN_PROVIDER";
    throw error;
  }
  if (!identity.email) {
    const error = new Error("EMAIL_REQUIRED");
    (error as Error & { code: string }).code = "EMAIL_REQUIRED";
    throw error;
  }

  const email = identity.email.toLowerCase();
  const shouldBeAdmin = adminEmails.has(email);
  const setFields: {
    email: string;
    displayName?: string;
    photoUrl?: string;
    role?: UserRole;
  } = {
    email,
    displayName: identity.name,
    photoUrl: identity.picture,
  };
  if (shouldBeAdmin) {
    setFields.role = "admin";
  }

  const user = await User.findOneAndUpdate(
    { firebaseUid: identity.uid },
    {
      $set: setFields,
      $setOnInsert: {
        subscriptionStatus: "inactive",
        trialUsed: false,
        ...(shouldBeAdmin ? {} : { role: "user" as UserRole }),
      },
    },
    { new: true, upsert: true },
  ).lean();

  return {
    id: user._id.toString(),
    firebaseUid: user.firebaseUid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoUrl,
    role: (user.role as UserRole | undefined) ?? "user",
    subscriptionStatus: user.subscriptionStatus,
    trialUsed: Boolean(user.trialUsed),
    currentPlan: user.currentPlan ?? null,
  };
}

export function authenticate(
  verifier: IdentityVerifier,
  options: { adminEmails?: string } = {},
): RequestHandler {
  const adminEmails = parseAdminEmails(options.adminEmails);

  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const header = req.header("authorization");
      const token = header?.startsWith("Bearer ") ? header.slice(7) : undefined;
      if (!token) {
        res.status(401).json({ error: "AUTH_REQUIRED" });
        return;
      }

      req.user = await resolveUser(verifier, token, adminEmails);
      next();
    } catch (error) {
      const code =
        error instanceof Error && "code" in error
          ? String((error as Error & { code?: string }).code)
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
export function optionalAuthenticate(
  verifier: IdentityVerifier,
  options: { adminEmails?: string } = {},
): RequestHandler {
  const adminEmails = parseAdminEmails(options.adminEmails);

  return async (req: Request, _res: Response, next: NextFunction) => {
    try {
      const header = req.header("authorization");
      const token = header?.startsWith("Bearer ") ? header.slice(7) : undefined;
      if (token) {
        req.user = await resolveUser(verifier, token, adminEmails);
      }
    } catch {
      // Public feed stays available even with a bad/expired token.
    }
    next();
  };
}

export const requirePremium: RequestHandler = (req, res, next) => {
  if (req.user?.subscriptionStatus !== "active") {
    res.status(402).json({
      error: "PREMIUM_REQUIRED",
      subscriptionStatus: req.user?.subscriptionStatus ?? "inactive",
    });
    return;
  }
  next();
};

export const requireAdmin: RequestHandler = (req, res, next) => {
  if (req.user?.role !== "admin") {
    res.status(403).json({ error: "ADMIN_REQUIRED" });
    return;
  }
  next();
};
