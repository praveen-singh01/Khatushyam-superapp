import { Router, type RequestHandler } from "express";
import { z } from "zod";
import { User } from "./user.model.js";
import {
  isValidPhone,
  normalizePhone,
  serializeAuthUser,
} from "./user.serialize.js";

const tokenSchema = z.object({
  token: z.string().min(20).max(4096),
});

const profileSchema = z.object({
  displayName: z.string().trim().min(1).max(120).optional(),
  photoUrl: z.string().url().max(2048).optional(),
  phone: z.string().trim().min(8).max(20).optional(),
});

const onboardingSchema = z.object({
  phone: z.string().trim().min(8).max(20),
  displayName: z.string().trim().min(1).max(120).optional(),
});

export function createAuthRouter(authenticate: RequestHandler): Router {
  const router = Router();

  router.get("/me", authenticate, (req, res) => {
    res.json({ user: req.user });
  });

  /** One-time onboarding — mobile number. Idempotent if already completed. */
  router.post("/onboarding", authenticate, async (req, res, next) => {
    try {
      const input = onboardingSchema.parse(req.body ?? {});
      const phone = normalizePhone(input.phone);
      if (!isValidPhone(phone)) {
        res.status(400).json({ error: "INVALID_PHONE" });
        return;
      }

      const existing = await User.findById(req.user!.id).lean();
      if (!existing) {
        res.status(404).json({ error: "USER_NOT_FOUND" });
        return;
      }

      const $set: Record<string, string | boolean> = {
        phone,
        onboardingCompleted: true,
      };
      if (input.displayName) {
        $set.displayName = input.displayName;
      }

      const user = await User.findByIdAndUpdate(
        req.user!.id,
        { $set },
        { new: true },
      ).lean();

      if (!user) {
        res.status(404).json({ error: "USER_NOT_FOUND" });
        return;
      }

      res.json({
        user: serializeAuthUser(
          user as Parameters<typeof serializeAuthUser>[0],
        ),
      });
    } catch (error) {
      next(error);
    }
  });

  router.patch("/me", authenticate, async (req, res, next) => {
    try {
      const input = profileSchema.parse(req.body ?? {});
      if (!input.displayName && !input.photoUrl && !input.phone) {
        res.status(400).json({ error: "NOTHING_TO_UPDATE" });
        return;
      }

      const $set: Record<string, string | boolean> = {};
      if (input.displayName) $set.displayName = input.displayName;
      if (input.photoUrl) $set.photoUrl = input.photoUrl;
      if (input.phone) {
        const phone = normalizePhone(input.phone);
        if (!isValidPhone(phone)) {
          res.status(400).json({ error: "INVALID_PHONE" });
          return;
        }
        $set.phone = phone;
      }

      const user = await User.findByIdAndUpdate(
        req.user!.id,
        { $set },
        { new: true },
      ).lean();
      if (!user) {
        res.status(404).json({ error: "USER_NOT_FOUND" });
        return;
      }
      res.json({
        user: serializeAuthUser(
          user as Parameters<typeof serializeAuthUser>[0],
        ),
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
