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

      const identity = await verifier.verify(token);
      if (identity.signInProvider !== "google.com") {
        res.status(403).json({ error: "GOOGLE_SIGN_IN_REQUIRED" });
        return;
      }
      if (!identity.email) {
        res.status(403).json({ error: "GOOGLE_EMAIL_REQUIRED" });
        return;
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
            ...(shouldBeAdmin ? {} : { role: "user" as UserRole }),
          },
        },
        { new: true, upsert: true },
      ).lean();

      req.user = {
        id: user._id.toString(),
        firebaseUid: user.firebaseUid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        role: (user.role as UserRole | undefined) ?? "user",
        subscriptionStatus: user.subscriptionStatus,
      };
      next();
    } catch {
      res.status(401).json({ error: "INVALID_AUTH_TOKEN" });
    }
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
