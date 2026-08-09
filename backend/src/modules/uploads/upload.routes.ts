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
  cloudFrontBaseUrl: string;
  presigner: UploadPresigner;
}

export function createUploadRouter(options: UploadRouterOptions): Router {
  const router = Router();

  router.post("/presign", options.authenticate, async (req, res, next) => {
    try {
      const input = uploadSchema.parse(req.body);

      // Poster uploads stay premium; profile photo is for all signed-in users.
      if (input.purpose === "poster_photo") {
        let allowed = false;
        options.requirePremium(req, res, () => {
          allowed = true;
        });
        if (!allowed) return;
      }

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
      const base = options.cloudFrontBaseUrl.replace(/\/$/, "");
      res.json({
        key,
        uploadUrl,
        publicUrl: `${base}/${key}`,
        expiresInSeconds: 300,
      });
    } catch (error) {
      next(error);
    }
  });

  return router;
}
