import { Router, type Request, type RequestHandler } from "express";
import { ContentAsset } from "./content-asset.model.js";
import {
  DEFAULT_LIVE_TITLE,
  LIVE_STREAM_KEY,
  LiveStream,
  toLiveStreamResponse,
} from "./live-stream.model.js";

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

  router.get("/story", (_req, res) => {
    res.json({
      title: {
        hi: "खाटू श्याम बाबा की कथा",
        en: "The story of Khatu Shyam Baba",
      },
      summary: {
        hi: "महाभारत के बबरिक से खाटू धाम के श्याम बाबा तक — भक्ति की अमर कथा।",
        en: "From Barbarik of the Mahabharata to Shyam Baba of Khatu — an immortal story of devotion.",
      },
      chapters: [
        {
          title: { hi: "बबरिक की प्रतिज्ञा", en: "Barbarik's vow" },
          body: {
            hi: "महाभारत काल में बबरिक ने तीन बाणों से युद्ध जीतने की शक्ति पाई, फिर श्रीकृष्ण की इच्छा पर अपना शीश अर्पित कर दिया।",
            en: "In the Mahabharata age, Barbarik gained the power to win war with three arrows, then offered his head at Krishna's wish.",
          },
        },
        {
          title: { hi: "खाटू में विराजमान", en: "Enshrined at Khatu" },
          body: {
            hi: "भगवान की कृपा से उनका शीश राजस्थान के खाटू में विराजमान हुआ — आज करोड़ों भक्त श्याम बाबा के नाम से पुकारते हैं।",
            en: "By divine grace his head was enshrined at Khatu in Rajasthan — crores of devotees now call him Shyam Baba.",
          },
        },
      ],
      videoKey: "public/story/khatu-shyam-introduction.mp4",
      access: "free",
    });
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
