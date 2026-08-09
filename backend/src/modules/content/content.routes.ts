import { Router, type Request, type RequestHandler } from "express";
import { Types } from "mongoose";
import { ContentAsset } from "./content-asset.model.js";
import {
  DEFAULT_LIVE_TITLE,
  LIVE_STREAM_KEY,
  LiveStream,
  toLiveStreamResponse,
} from "./live-stream.model.js";
import { isS3MediaKey } from "../../shared/media-paths.js";
import {
  DEFAULT_STORY,
  STORY_KEY,
  Story,
  toStoryResponse,
} from "./story.model.js";

const LIBRARY_TYPES = new Set(["wallpaper", "ringtone", "poster"]);
const POSTERS_PAGE_MAX = 50;
const POSTERS_PAGE_DEFAULT = 20;

function parseLimit(raw: unknown, fallback: number, max: number): number {
  const n = typeof raw === "string" ? Number.parseInt(raw, 10) : Number.NaN;
  if (!Number.isFinite(n) || n < 1) return fallback;
  return Math.min(n, max);
}

export function createContentRouter(
  authenticate: RequestHandler,
  requirePremium: RequestHandler,
  cloudFrontBaseUrl: string,
  options: { useRequestHostForMedia?: boolean } = {},
): Router {
  const router = Router();
  const cdnBase = cloudFrontBaseUrl.replace(/\/$/, "");

  const mediaBaseFor = (req: Request): string => {
    if (options.useRequestHostForMedia) {
      const host = req.get("host");
      if (host) {
        const proto = req.protocol === "https" ? "https" : "http";
        return `${proto}://${host}`;
      }
    }
    return cdnBase;
  };

  const publicUrlFor = (req: Request, fileKey: string): string => {
    const base = isS3MediaKey(fileKey) ? cdnBase : mediaBaseFor(req);
    return `${base}/${fileKey}`;
  };

  router.get("/story", async (_req, res, next) => {
    try {
      const doc = await Story.findOne({ key: STORY_KEY }).lean();
      if (!doc) {
        res.json(
          toStoryResponse({
            ...DEFAULT_STORY,
            chapters: [...DEFAULT_STORY.chapters],
          }),
        );
        return;
      }
      res.json(toStoryResponse(doc));
    } catch (error) {
      next(error);
    }
  });

  /** Free Live Darshan config — backend-controlled YouTube embed. */
  router.get("/live", async (_req, res, next) => {
    try {
      const doc = await LiveStream.findOne({ key: LIVE_STREAM_KEY }).lean();
      if (!doc) {
        res.json(
          toLiveStreamResponse({
            isLive: false,
            youtubeVideoId: null,
            title: { ...DEFAULT_LIVE_TITLE },
          }),
        );
        return;
      }
      res.json(toLiveStreamResponse(doc));
    } catch (error) {
      next(error);
    }
  });

  router.get("/premium-manifest", authenticate, requirePremium, (_req, res) => {
    res.json({
      features: [
        "calendar",
        "aarti_alarms",
        "events",
        "singers",
        "temple_status",
        "travel_guides",
        "bhajans",
        "personalized_posters",
        "wallpapers",
        "ringtones",
        "caller_tunes",
      ],
    });
  });

  /**
   * Paginated, lean posters feed for the app tab.
   * Query: limit (default 20, max 50), cursor (ISO date or ObjectId), category.
   * Response fields are minimal for list + editor.
   */
  router.get("/posters", authenticate, async (req, res, next) => {
    try {
      const limit = parseLimit(
        req.query.limit,
        POSTERS_PAGE_DEFAULT,
        POSTERS_PAGE_MAX,
      );
      const category =
        typeof req.query.category === "string"
          ? req.query.category.trim()
          : "";
      const cursorRaw =
        typeof req.query.cursor === "string" ? req.query.cursor.trim() : "";

      const filter: Record<string, unknown> = {
        type: "poster",
        status: "published",
      };
      if (category) filter.category = category;

      if (cursorRaw) {
        if (Types.ObjectId.isValid(cursorRaw)) {
          filter._id = { $lt: new Types.ObjectId(cursorRaw) };
        } else {
          const cursorDate = new Date(cursorRaw);
          if (!Number.isNaN(cursorDate.getTime())) {
            filter.createdAt = { $lt: cursorDate };
          }
        }
      }

      const docs = await ContentAsset.find(filter)
        .select({
          slug: 1,
          title: 1,
          category: 1,
          fileKey: 1,
          width: 1,
          height: 1,
          createdAt: 1,
        })
        .sort({ createdAt: -1, _id: -1 })
        .limit(limit + 1)
        .lean();

      const page = docs.slice(0, limit);
      const hasMore = docs.length > limit;
      const last = page[page.length - 1];
      const nextCursor =
        hasMore && last
          ? String(last._id)
          : null;

      res.setHeader("Cache-Control", "private, max-age=30");
      res.json({
        items: page.map((item) => ({
          id: item.slug,
          title: item.title,
          category: item.category,
          url: publicUrlFor(req, item.fileKey),
          width: item.width ?? null,
          height: item.height ?? null,
          createdAt: item.createdAt ?? null,
        })),
        nextCursor,
        hasMore,
      });
    } catch (error) {
      next(error);
    }
  });

  router.get("/library", authenticate, requirePremium, async (req, res, next) => {
    try {
      const type =
        typeof req.query.type === "string" ? req.query.type.trim() : "";
      const category =
        typeof req.query.category === "string"
          ? req.query.category.trim()
          : "";

      const filter: Record<string, unknown> = { status: "published" };
      if (LIBRARY_TYPES.has(type)) filter.type = type;
      if (category) filter.category = category;

      // Posters should use /v1/content/posters (paginated). Keep library lean.
      if (type === "poster") {
        const limit = parseLimit(req.query.limit, POSTERS_PAGE_DEFAULT, POSTERS_PAGE_MAX);
        const docs = await ContentAsset.find(filter)
          .select({
            slug: 1,
            title: 1,
            category: 1,
            fileKey: 1,
            format: 1,
            width: 1,
            height: 1,
            premium: 1,
            createdAt: 1,
          })
          .sort({ createdAt: -1, _id: -1 })
          .limit(limit)
          .lean();
        res.json({
          items: docs.map((item) => ({
            id: item.slug,
            type: "poster" as const,
            category: item.category,
            title: item.title,
            url: publicUrlFor(req, item.fileKey),
            format: item.format,
            width: item.width,
            height: item.height,
            premium: item.premium,
          })),
        });
        return;
      }

      const items = await ContentAsset.find(filter)
        .sort({ category: 1, createdAt: -1 })
        .lean();

      res.json({
        items: items.map((item) => ({
          id: item.slug,
          type: item.type,
          category: item.category,
          title: item.title,
          fileKey: item.fileKey,
          url: publicUrlFor(req, item.fileKey),
          format: item.format,
          width: item.width,
          height: item.height,
          durationSeconds: item.durationSeconds,
          premium: item.premium,
        })),
      });
    } catch (error) {
      next(error);
    }
  });

  return router;
}
