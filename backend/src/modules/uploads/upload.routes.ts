import { randomUUID } from "node:crypto";
import { Router, type RequestHandler } from "express";
import { z } from "zod";
import { s3UserUploadKey } from "../../shared/media-paths.js";
import type { UploadPresigner } from "../../shared/ports.js";

const uploadSchema = z.object({
  contentType: z.enum(["image/jpeg", "image/png", "image/webp"]),
  purpose: z.enum(["profile_photo", "poster_photo"]),
});

const extensionByType = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
} as const;

interface UploadRouterOptions {
  authenticate: RequestHandler;
  requirePremium: RequestHandler;
  bucket: string;
  presigner: UploadPresigner;
}

export function createUploadRouter(options: UploadRouterOptions): Router {
  const router = Router();

  router.post(
    "/presign",
    options.authenticate,
    options.requirePremium,
    async (req, res, next) => {
      try {
        const input = uploadSchema.parse(req.body);
        const key = s3UserUploadKey(
          req.user!.id,
          input.purpose,
          `${randomUUID()}.${extensionByType[input.contentType]}`,
        );
        const uploadUrl = await options.presigner.createUploadUrl({
          bucket: options.bucket,
          key,
          contentType: input.contentType,
          metadata: { owner: req.user!.id, purpose: input.purpose },
          expiresInSeconds: 300,
        });
        res.json({ key, uploadUrl, expiresInSeconds: 300 });
      } catch (error) {
        next(error);
      }
    },
  );

  return router;
}
