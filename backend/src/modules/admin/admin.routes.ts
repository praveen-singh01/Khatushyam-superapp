import { randomUUID } from "node:crypto";
import { Router, type RequestHandler } from "express";
import { z } from "zod";
import { User } from "../auth/user.model.js";
import { ContentAsset } from "../content/content-asset.model.js";
import {
  ContentCategory,
  categoryExists,
  categoryResponse,
  listCategoriesByType,
} from "../content/content-category.model.js";
import {
  DEFAULT_LIVE_TITLE,
  LIVE_STREAM_KEY,
  LiveStream,
  extractYoutubeVideoId,
  toLiveStreamResponse,
} from "../content/live-stream.model.js";
import { Chamatkar } from "../chamatkars/chamatkar.model.js";
import type { UploadPresigner } from "../../shared/ports.js";

const subscriptionStatusSchema = z.enum([
  "inactive",
  "pending",
  "active",
  "halted",
  "cancelled",
]);

const roleSchema = z.enum(["user", "admin"]);

const contentTypeSchema = z.enum(["wallpaper", "ringtone"]);
const contentStatusSchema = z.enum(["draft", "published", "archived"]);

const slugSchema = z
  .string()
  .min(2)
  .max(64)
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/);

const contentFieldsSchema = z.object({
  slug: z
    .string()
    .min(2)
    .max(120)
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
  type: contentTypeSchema,
  category: slugSchema,
  title: z.object({
    hi: z.string().min(1).max(200),
    en: z.string().min(1).max(200),
  }),
  fileKey: z.string().min(3).max(500),
  format: z.string().min(2).max(16),
  width: z.number().int().positive().optional(),
  height: z.number().int().positive().optional(),
  durationSeconds: z.number().positive().optional(),
  license: z.string().max(200).optional(),
  attribution: z.string().max(500).optional(),
  premium: z.boolean().default(true),
  source: z.string().max(64).optional(),
  status: contentStatusSchema.default("published"),
});

const createContentSchema = contentFieldsSchema;
const updateContentSchema = contentFieldsSchema.partial().omit({ slug: true });

const createCategorySchema = z.object({
  type: contentTypeSchema,
  slug: slugSchema,
  label: z
    .object({
      hi: z.string().min(1).max(120),
      en: z.string().min(1).max(120),
    })
    .optional(),
});

const updateUserSchema = z
  .object({
    role: roleSchema.optional(),
    subscriptionStatus: subscriptionStatusSchema.optional(),
    displayName: z.string().min(1).max(120).optional(),
  })
  .refine(
    (value) =>
      value.role !== undefined ||
      value.subscriptionStatus !== undefined ||
      value.displayName !== undefined,
    { message: "At least one field is required" },
  );

const libraryPresignSchema = z.object({
  type: contentTypeSchema,
  category: slugSchema,
  contentType: z.enum([
    "image/jpeg",
    "image/png",
    "image/webp",
    "audio/mpeg",
    "audio/mp4",
    "audio/x-m4a",
    "audio/m4a",
  ]),
  fileName: z.string().min(1).max(200).optional(),
});

const liveStreamUpdateSchema = z
  .object({
    isLive: z.boolean(),
    /** 11-char video ID or full YouTube URL. Null clears the ID when going offline. */
    youtubeVideoId: z.union([z.string().min(1).max(500), z.null()]).optional(),
    title: z
      .object({
        hi: z.string().min(1).max(200),
        en: z.string().min(1).max(200),
      })
      .optional(),
  })
  .superRefine((value, ctx) => {
    if (value.isLive) {
      if (value.youtubeVideoId == null || value.youtubeVideoId === "") {
        ctx.addIssue({
          code: "custom",
          path: ["youtubeVideoId"],
          message: "youtubeVideoId is required when isLive is true",
        });
        return;
      }
      if (!extractYoutubeVideoId(value.youtubeVideoId)) {
        ctx.addIssue({
          code: "custom",
          path: ["youtubeVideoId"],
          message: "Invalid YouTube video ID or URL",
        });
      }
    } else if (
      value.youtubeVideoId != null &&
      value.youtubeVideoId !== "" &&
      !extractYoutubeVideoId(value.youtubeVideoId)
    ) {
      ctx.addIssue({
        code: "custom",
        path: ["youtubeVideoId"],
        message: "Invalid YouTube video ID or URL",
      });
    }
  });

const extensionByContentType = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "audio/mpeg": "mp3",
  "audio/mp4": "m4a",
  "audio/x-m4a": "m4a",
  "audio/m4a": "m4a",
} as const;

interface AdminRouterOptions {
  authenticate: RequestHandler;
  requireAdmin: RequestHandler;
  bucket: string;
  cloudFrontBaseUrl: string;
  presigner: UploadPresigner;
}

function assetResponse(
  doc: {
    _id: { toString(): string };
    slug: string;
    type: string;
    category: string;
    title: { hi: string; en: string };
    fileKey: string;
    format: string;
    width?: number;
    height?: number;
    durationSeconds?: number;
    license?: string;
    attribution?: string;
    premium: boolean;
    source?: string;
    status: string;
    uploadedBy?: string;
    createdAt?: Date;
    updatedAt?: Date;
  },
  cloudFrontBaseUrl: string,
) {
  const base = cloudFrontBaseUrl.replace(/\/$/, "");
  return {
    id: doc._id.toString(),
    slug: doc.slug,
    type: doc.type,
    category: doc.category,
    title: doc.title,
    fileKey: doc.fileKey,
    url: `${base}/${doc.fileKey}`,
    format: doc.format,
    width: doc.width,
    height: doc.height,
    durationSeconds: doc.durationSeconds,
    license: doc.license,
    attribution: doc.attribution,
    premium: doc.premium,
    source: doc.source,
    status: doc.status,
    uploadedBy: doc.uploadedBy,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
}

export function createAdminRouter(options: AdminRouterOptions): Router {
  const router = Router();
  router.use(options.authenticate, options.requireAdmin);

  router.get("/stats", async (_req, res, next) => {
    try {
      const categories = await listCategoriesByType();
      const [
        userCount,
        premiumCount,
        adminCount,
        contentCount,
        wallpaperCount,
        ringtoneCount,
        chamatkarCount,
      ] = await Promise.all([
        User.countDocuments(),
        User.countDocuments({ subscriptionStatus: "active" }),
        User.countDocuments({ role: "admin" }),
        ContentAsset.countDocuments(),
        ContentAsset.countDocuments({ type: "wallpaper" }),
        ContentAsset.countDocuments({ type: "ringtone" }),
        Chamatkar.countDocuments(),
      ]);

      res.json({
        users: { total: userCount, premium: premiumCount, admins: adminCount },
        content: {
          total: contentCount,
          wallpapers: wallpaperCount,
          ringtones: ringtoneCount,
        },
        categories: {
          total: categories.items.length,
          wallpapers: categories.byType.wallpaper.length,
          ringtones: categories.byType.ringtone.length,
        },
        chamatkars: { total: chamatkarCount },
      });
    } catch (error) {
      next(error);
    }
  });

  router.get("/categories", async (req, res, next) => {
    try {
      const type =
        typeof req.query.type === "string" ? req.query.type.trim() : "";
      const listed = await listCategoriesByType();
      const items =
        type === "wallpaper" || type === "ringtone"
          ? listed.items.filter((item) => item.type === type)
          : listed.items;
      res.json({
        items,
        byType: listed.byType,
      });
    } catch (error) {
      next(error);
    }
  });

  router.post("/categories", async (req, res, next) => {
    try {
      await listCategoriesByType();
      const input = createCategorySchema.parse(req.body);
      const slug = input.slug.toLowerCase();
      const existing = await ContentCategory.findOne({
        type: input.type,
        slug,
      }).lean();
      if (existing) {
        res.status(409).json({ error: "CATEGORY_EXISTS" });
        return;
      }

      const label = input.label ?? {
        en: slug
          .split("-")
          .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
          .join(" "),
        hi: slug,
      };

      const created = await ContentCategory.create({
        type: input.type,
        slug,
        label,
      });

      res.status(201).json({ item: categoryResponse(created.toObject()) });
    } catch (error) {
      next(error);
    }
  });

  router.delete("/categories/:id", async (req, res, next) => {
    try {
      const category = await ContentCategory.findById(req.params.id);
      if (!category) {
        res.status(404).json({ error: "CATEGORY_NOT_FOUND" });
        return;
      }

      const inUse = await ContentAsset.countDocuments({
        type: category.type,
        category: category.slug,
        status: { $ne: "archived" },
      });
      if (inUse > 0) {
        res.status(409).json({
          error: "CATEGORY_IN_USE",
          assetCount: inUse,
        });
        return;
      }

      await category.deleteOne();
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  });

  router.get("/users", async (req, res, next) => {
    try {
      const q = typeof req.query.q === "string" ? req.query.q.trim() : "";
      const role =
        typeof req.query.role === "string" ? req.query.role.trim() : "";
      const subscriptionStatus =
        typeof req.query.subscriptionStatus === "string"
          ? req.query.subscriptionStatus.trim()
          : "";
      const limit = Math.min(
        Math.max(Number(req.query.limit ?? 50) || 50, 1),
        100,
      );
      const page = Math.max(Number(req.query.page ?? 1) || 1, 1);

      const filter: Record<string, unknown> = {};
      if (q) {
        filter.$or = [
          { email: { $regex: q, $options: "i" } },
          { displayName: { $regex: q, $options: "i" } },
        ];
      }
      if (role === "user" || role === "admin") {
        filter.role = role;
      }
      if (
        subscriptionStatus &&
        [
          "inactive",
          "pending",
          "active",
          "halted",
          "cancelled",
        ].includes(subscriptionStatus)
      ) {
        filter.subscriptionStatus = subscriptionStatus;
      }

      const [items, total] = await Promise.all([
        User.find(filter)
          .sort({ createdAt: -1 })
          .skip((page - 1) * limit)
          .limit(limit)
          .select(
            "firebaseUid email displayName photoUrl role subscriptionStatus razorpaySubscriptionId createdAt updatedAt",
          )
          .lean(),
        User.countDocuments(filter),
      ]);

      res.json({
        items: items.map((user) => ({
          id: user._id.toString(),
          firebaseUid: user.firebaseUid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          role: user.role ?? "user",
          subscriptionStatus: user.subscriptionStatus,
          razorpaySubscriptionId: user.razorpaySubscriptionId,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
        })),
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit) || 1,
      });
    } catch (error) {
      next(error);
    }
  });

  router.patch("/users/:id", async (req, res, next) => {
    try {
      const input = updateUserSchema.parse(req.body);
      const user = await User.findById(req.params.id);
      if (!user) {
        res.status(404).json({ error: "USER_NOT_FOUND" });
        return;
      }

      if (input.role === "user" && user.role === "admin") {
        const adminCount = await User.countDocuments({ role: "admin" });
        if (adminCount <= 1) {
          res.status(400).json({ error: "LAST_ADMIN_REQUIRED" });
          return;
        }
      }

      if (input.role !== undefined) user.role = input.role;
      if (input.subscriptionStatus !== undefined) {
        user.subscriptionStatus = input.subscriptionStatus;
      }
      if (input.displayName !== undefined) {
        user.displayName = input.displayName;
      }
      await user.save();

      res.json({
        user: {
          id: user.id,
          firebaseUid: user.firebaseUid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          role: user.role,
          subscriptionStatus: user.subscriptionStatus,
          razorpaySubscriptionId: user.razorpaySubscriptionId,
        },
      });
    } catch (error) {
      next(error);
    }
  });

  router.get("/content", async (req, res, next) => {
    try {
      const type =
        typeof req.query.type === "string" ? req.query.type.trim() : "";
      const category =
        typeof req.query.category === "string"
          ? req.query.category.trim()
          : "";
      const status =
        typeof req.query.status === "string" ? req.query.status.trim() : "";
      const q = typeof req.query.q === "string" ? req.query.q.trim() : "";
      const limit = Math.min(
        Math.max(Number(req.query.limit ?? 50) || 50, 1),
        100,
      );
      const page = Math.max(Number(req.query.page ?? 1) || 1, 1);

      const filter: Record<string, unknown> = {};
      if (type === "wallpaper" || type === "ringtone") filter.type = type;
      if (category) filter.category = category;
      if (status === "draft" || status === "published" || status === "archived") {
        filter.status = status;
      }
      if (q) {
        filter.$or = [
          { slug: { $regex: q, $options: "i" } },
          { "title.en": { $regex: q, $options: "i" } },
          { "title.hi": { $regex: q, $options: "i" } },
        ];
      }

      const [items, total, categories] = await Promise.all([
        ContentAsset.find(filter)
          .sort({ createdAt: -1 })
          .skip((page - 1) * limit)
          .limit(limit)
          .lean(),
        ContentAsset.countDocuments(filter),
        listCategoriesByType(),
      ]);

      res.json({
        items: items.map((item) =>
          assetResponse(item, options.cloudFrontBaseUrl),
        ),
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit) || 1,
        categories: categories.byType,
      });
    } catch (error) {
      next(error);
    }
  });

  router.post("/content", async (req, res, next) => {
    try {
      const input = createContentSchema.parse(req.body);
      if (!(await categoryExists(input.type, input.category))) {
        res.status(400).json({ error: "INVALID_CATEGORY" });
        return;
      }
      const existing = await ContentAsset.findOne({ slug: input.slug }).lean();
      if (existing) {
        res.status(409).json({ error: "CONTENT_SLUG_EXISTS" });
        return;
      }

      const created = await ContentAsset.create({
        ...input,
        uploadedBy: req.user!.id,
      });

      res.status(201).json({
        item: assetResponse(created.toObject(), options.cloudFrontBaseUrl),
      });
    } catch (error) {
      next(error);
    }
  });

  router.patch("/content/:id", async (req, res, next) => {
    try {
      const input = updateContentSchema.parse(req.body);
      const asset = await ContentAsset.findById(req.params.id);
      if (!asset) {
        res.status(404).json({ error: "CONTENT_NOT_FOUND" });
        return;
      }

      if (input.type !== undefined || input.category !== undefined) {
        const nextType = input.type ?? asset.type;
        const nextCategory = input.category ?? asset.category;
        if (!(await categoryExists(nextType, nextCategory))) {
          res.status(400).json({ error: "INVALID_CATEGORY" });
          return;
        }
      }

      Object.assign(asset, input);
      await asset.save();

      res.json({
        item: assetResponse(asset.toObject(), options.cloudFrontBaseUrl),
      });
    } catch (error) {
      next(error);
    }
  });

  router.delete("/content/:id", async (req, res, next) => {
    try {
      const asset = await ContentAsset.findById(req.params.id);
      if (!asset) {
        res.status(404).json({ error: "CONTENT_NOT_FOUND" });
        return;
      }
      asset.status = "archived";
      await asset.save();
      res.json({
        item: assetResponse(asset.toObject(), options.cloudFrontBaseUrl),
      });
    } catch (error) {
      next(error);
    }
  });

  router.get("/live", async (_req, res, next) => {
    try {
      const doc = await LiveStream.findOne({ key: LIVE_STREAM_KEY }).lean();
      if (!doc) {
        res.json({
          live: {
            isLive: false,
            youtubeVideoId: null,
            title: { ...DEFAULT_LIVE_TITLE },
            embedUrl: null,
            updatedAt: null,
            // Public app view (only live when flagged + video present).
            public: toLiveStreamResponse({
              isLive: false,
              youtubeVideoId: null,
              title: { ...DEFAULT_LIVE_TITLE },
            }),
          },
        });
        return;
      }
      res.json({
        live: {
          isLive: doc.isLive,
          youtubeVideoId: doc.youtubeVideoId,
          title: doc.title,
          embedUrl: doc.youtubeVideoId
            ? `https://www.youtube.com/embed/${doc.youtubeVideoId}`
            : null,
          updatedAt: doc.updatedAt ?? null,
          public: toLiveStreamResponse(doc),
        },
      });
    } catch (error) {
      next(error);
    }
  });

  router.put("/live", async (req, res, next) => {
    try {
      const input = liveStreamUpdateSchema.parse(req.body);
      let youtubeVideoId: string | null | undefined;
      if (input.youtubeVideoId === null) {
        youtubeVideoId = null;
      } else if (typeof input.youtubeVideoId === "string") {
        youtubeVideoId = extractYoutubeVideoId(input.youtubeVideoId);
        if (!youtubeVideoId) {
          res.status(400).json({ error: "INVALID_YOUTUBE_URL" });
          return;
        }
      }

      const existing = await LiveStream.findOne({ key: LIVE_STREAM_KEY });
      const nextVideoId =
        youtubeVideoId !== undefined
          ? youtubeVideoId
          : (existing?.youtubeVideoId ?? null);

      if (input.isLive && !nextVideoId) {
        res.status(400).json({ error: "YOUTUBE_VIDEO_ID_REQUIRED" });
        return;
      }

      const $set: Record<string, unknown> = {
        key: LIVE_STREAM_KEY,
        isLive: input.isLive,
        updatedBy: req.user!.id,
      };
      if (youtubeVideoId !== undefined) {
        $set.youtubeVideoId = youtubeVideoId;
      }
      if (input.title) {
        $set.title = input.title;
      }

      const $setOnInsert: Record<string, unknown> = {};
      if (!("title" in $set)) {
        $setOnInsert.title = { ...DEFAULT_LIVE_TITLE };
      }
      if (!("youtubeVideoId" in $set)) {
        $setOnInsert.youtubeVideoId = null;
      }

      const doc = await LiveStream.findOneAndUpdate(
        { key: LIVE_STREAM_KEY },
        {
          $set,
          ...(Object.keys($setOnInsert).length > 0 ? { $setOnInsert } : {}),
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      );
      const saved = doc.toObject();

      res.json({
        live: {
          isLive: saved.isLive,
          youtubeVideoId: saved.youtubeVideoId,
          title: saved.title,
          embedUrl: saved.youtubeVideoId
            ? `https://www.youtube.com/embed/${saved.youtubeVideoId}`
            : null,
          updatedAt: saved.updatedAt ?? null,
          public: toLiveStreamResponse(saved),
        },
      });
    } catch (error) {
      next(error);
    }
  });

  router.post("/uploads/presign", async (req, res, next) => {
    try {
      const input = libraryPresignSchema.parse(req.body);
      if (!(await categoryExists(input.type, input.category))) {
        res.status(400).json({ error: "INVALID_CATEGORY" });
        return;
      }

      const isImage = input.contentType.startsWith("image/");
      if (input.type === "wallpaper" && !isImage) {
        res.status(400).json({ error: "WALLPAPER_REQUIRES_IMAGE" });
        return;
      }
      if (input.type === "ringtone" && isImage) {
        res.status(400).json({ error: "RINGTONE_REQUIRES_AUDIO" });
        return;
      }

      const ext = extensionByContentType[input.contentType];
      const folder = input.type === "wallpaper" ? "wallpapers" : "ringtones";
      const key = `khatu-shyam-content/${folder}/${input.category}/${randomUUID()}.${ext}`;
      const uploadUrl = await options.presigner.createUploadUrl({
        bucket: options.bucket,
        key,
        contentType: input.contentType,
        metadata: {
          uploadedBy: req.user!.id,
          type: input.type,
          category: input.category,
        },
        expiresInSeconds: 600,
      });

      res.json({
        key,
        uploadUrl,
        expiresInSeconds: 600,
        publicUrl: `${options.cloudFrontBaseUrl.replace(/\/$/, "")}/${key}`,
      });
    } catch (error) {
      next(error);
    }
  });

  return router;
}
