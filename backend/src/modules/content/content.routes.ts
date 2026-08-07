import { Router, type RequestHandler } from "express";

export function createContentRouter(
  authenticate: RequestHandler,
  requirePremium: RequestHandler,
): Router {
  const router = Router();

  router.get("/story", (_req, res) => {
    res.json({
      title: {
        hi: "खाटू श्याम बाबा की कथा",
        en: "The story of Khatu Shyam Baba",
      },
      videoKey: "public/story/khatu-shyam-introduction.mp4",
      access: "free",
    });
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

  return router;
}
