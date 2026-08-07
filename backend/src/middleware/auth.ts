import type { NextFunction, Request, RequestHandler, Response } from "express";
import type { IdentityVerifier } from "../shared/types.js";
import { User } from "../modules/auth/user.model.js";

export function authenticate(verifier: IdentityVerifier): RequestHandler {
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

      const user = await User.findOneAndUpdate(
        { firebaseUid: identity.uid },
        {
          $set: {
            email: identity.email,
            displayName: identity.name,
            photoUrl: identity.picture,
          },
          $setOnInsert: { subscriptionStatus: "inactive" },
        },
        { new: true, upsert: true },
      ).lean();

      req.user = {
        id: user._id.toString(),
        firebaseUid: user.firebaseUid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
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
