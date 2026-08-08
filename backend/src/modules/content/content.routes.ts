import { Router, type Request, type RequestHandler } from "express";
import { ContentAsset } from "./content-asset.model.js";
import {
  DEFAULT_LIVE_TITLE,
  LIVE_STREAM_KEY,
  LiveStream,
  toLiveStreamResponse,
} from "./live-stream.model.js";
import {
  DEFAULT_STORY,
  STORY_KEY,
  Story,
  toStoryResponse,
} from "./story.model.js";

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

  router.get("/story", async (_req, res, next) => {
    try {
      const doc = await Story.findOne({ key: STORY_KEY }).lean();
      if (!doc) {
        res.json(toStoryResponse({ ...DEFAULT_STORY, chapters: [...DEFAULT_STORY.chapters] }));
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

  router.get("/library", authenticate, requirePremium, async (req, res, next) => {
    try {
      const type =
        typeof req.query.type === "string" ? req.query.type.trim() : "";
      const category =
        typeof req.query.category === "string"
          ? req.query.category.trim()
          : "";

      const filter: Record<string, unknown> = { status: "published" };
      if (type === "wallpaper" || type === "ringtone") filter.type = type;
      if (category) filter.category = category;

      const items = await ContentAsset.find(filter)
        .sort({ category: 1, createdAt: -1 })
        .lean();

      const base = mediaBaseFor(req);
      res.json({
        items: items.map((item) => ({
          id: item.slug,
          type: item.type,
          category: item.category,
          title: item.title,
          fileKey: item.fileKey,
          url: `${base}/${item.fileKey}`,
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
