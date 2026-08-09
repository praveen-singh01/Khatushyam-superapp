import { Router, type RequestHandler } from "express";
import { z } from "zod";
import { User } from "./user.model.js";

const tokenSchema = z.object({
  token: z.string().min(20).max(4096),
});

const profileSchema = z.object({
  displayName: z.string().trim().min(1).max(120).optional(),
  photoUrl: z.string().url().max(2048).optional(),
});

export function createAuthRouter(authenticate: RequestHandler): Router {
  const router = Router();

  router.get("/me", authenticate, (req, res) => {
    res.json({ user: req.user });
  });

  router.patch("/me", authenticate, async (req, res, next) => {
    try {
      const input = profileSchema.parse(req.body ?? {});
      if (!input.displayName && !input.photoUrl) {
        res.status(400).json({ error: "NOTHING_TO_UPDATE" });
        return;
      }
      const user = await User.findByIdAndUpdate(
        req.user!.id,
        {
          $set: {
            ...(input.displayName ? { displayName: input.displayName } : {}),
            ...(input.photoUrl ? { photoUrl: input.photoUrl } : {}),
          },
        },
        { new: true },
      ).lean();
      if (!user) {
        res.status(404).json({ error: "USER_NOT_FOUND" });
        return;
      }
      res.json({
        user: {
          id: user._id.toString(),
          firebaseUid: user.firebaseUid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          role: user.role,
          subscriptionStatus: user.subscriptionStatus,
          trialUsed: Boolean(user.trialUsed),
          currentPlan: user.currentPlan ?? null,
          subscriptionExpiresAt: user.subscriptionExpiresAt
            ? new Date(user.subscriptionExpiresAt).toISOString()
            : null,
        },
      });
    } catch (error) {
      next(error);
    }
  });

  router.put("/fcm-token", authenticate, async (req, res, next) => {
    try {
      const { token } = tokenSchema.parse(req.body);
      await User.findByIdAndUpdate(req.user!.id, {
        $addToSet: { fcmTokens: token },
      });
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  });

  return router;
}
