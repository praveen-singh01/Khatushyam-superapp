import { Router, type RequestHandler } from "express";
import { z } from "zod";
import { User } from "./user.model.js";

const tokenSchema = z.object({
  token: z.string().min(20).max(4096),
});

export function createAuthRouter(authenticate: RequestHandler): Router {
  const router = Router();

  router.get("/me", authenticate, (req, res) => {
    res.json({ user: req.user });
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
