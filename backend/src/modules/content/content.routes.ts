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
import {
  DEFAULT_TRAVEL_GUIDES,
  TRAVEL_GUIDES_KEY,
  TravelGuides,
  toTravelGuidesResponse,
} from "./travel-guide.model.js";
import {
  Event,
  DEFAULT_EVENTS,
} from "./event.model.js";

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

  /**
   * Public HTML shell for in-app YouTube playback.
   * Mobile WebViews often hit error 153 when embedding without a real HTTPS
   * document origin — this page is served from our domain so Referer is valid.
   */
  router.get("/youtube-embed/:videoId", (req, res) => {
    const videoId = String(req.params.videoId ?? "");
    if (!/^[a-zA-Z0-9_-]{6,20}$/.test(videoId)) {
      res.status(400).type("text/plain").send("Invalid video id");
      return;
    }
    const autoplay = req.query.autoplay !== "0";
    // Default unmuted; pass mute=1 only when caller explicitly wants silent autoplay.
    const mute = req.query.mute === "1";
    const loop = req.query.loop === "1";
    const host = req.get("x-forwarded-host") || req.get("host") || "baba.yaaro.online";
    const proto =
      req.get("x-forwarded-proto") === "http" ? "http" : "https";
    const origin = `${proto}://${host}`;

    res.status(200);
    res.setHeader("Content-Type", "text/html; charset=utf-8");
    res.setHeader("Cache-Control", "no-store");
    res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
    // Allow WebView / iframe clients to load this shell (helmet defaults block).
    res.removeHeader("Cross-Origin-Resource-Policy");
    res.removeHeader("Cross-Origin-Opener-Policy");
    res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");
    // Override helmet CSP so the YouTube iframe / IFrame API can load.
    res.setHeader(
      "Content-Security-Policy",
      [
        "default-src 'none'",
        "script-src 'unsafe-inline' https://www.youtube.com https://www.youtube-nocookie.com https://s.ytimg.com",
        "style-src 'unsafe-inline'",
        "img-src https: data:",
        "media-src https: blob:",
        "frame-src https://www.youtube.com https://www.youtube-nocookie.com",
        "connect-src https://www.youtube.com https://www.youtube-nocookie.com https://s.ytimg.com",
        "worker-src blob:",
        "child-src blob: https://www.youtube.com",
        "base-uri 'none'",
      ].join("; "),
    );
    res.send(`<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <title>YouTube</title>
  <style>
    html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
    #player { position: absolute; inset: 0; width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="player"></div>
  <script>
    var YT_VIDEO_ID = ${JSON.stringify(videoId)};
    var YT_ORIGIN = ${JSON.stringify(origin)};
    var YT_AUTOPLAY = ${autoplay ? "true" : "false"};
    var YT_MUTE = ${mute ? "true" : "false"};
    var YT_LOOP = ${loop ? "true" : "false"};
    var ytPlayer = null;

    function pauseYt() {
      try { if (ytPlayer && ytPlayer.pauseVideo) ytPlayer.pauseVideo(); } catch (e) {}
    }

    function onYouTubeIframeAPIReady() {
      ytPlayer = new YT.Player('player', {
        width: '100%',
        height: '100%',
        videoId: YT_VIDEO_ID,
        host: 'https://www.youtube.com',
        playerVars: {
          autoplay: YT_AUTOPLAY ? 1 : 0,
          mute: YT_MUTE ? 1 : 0,
          playsinline: 1,
          rel: 0,
          modestbranding: 1,
          controls: 1,
          fs: 1,
          origin: YT_ORIGIN,
          enablejsapi: 1,
          loop: YT_LOOP ? 1 : 0,
          playlist: YT_LOOP ? YT_VIDEO_ID : undefined
        },
        events: {
          onReady: function (event) {
            try {
              if (!YT_MUTE) event.target.unMute();
              if (YT_AUTOPLAY) {
                event.target.playVideo();
                // Some WebViews ignore first unmuted autoplay — retry once.
                setTimeout(function () {
                  try {
                    if (!YT_MUTE) event.target.unMute();
                    event.target.setVolume(100);
                    if (event.target.getPlayerState && event.target.getPlayerState() !== 1) {
                      event.target.playVideo();
                    }
                  } catch (e) {}
                }, 400);
              }
            } catch (e) {}
          },
          onError: function () {
            document.body.setAttribute('data-yt-error', '1');
            document.body.innerText = 'Video unavailable';
          }
        }
      });
    }

    var tag = document.createElement('script');
    tag.src = 'https://www.youtube.com/iframe_api';
    document.head.appendChild(tag);
  </script>
</body>
</html>`);
  });

  /** Travel guides — admin CMS list (Hinglish / localized steps). */
  router.get("/travel-guides", async (_req, res, next) => {
    try {
      const doc = await TravelGuides.findOne({ key: TRAVEL_GUIDES_KEY }).lean();
      if (!doc) {
        res.json(
          toTravelGuidesResponse({
            guides: DEFAULT_TRAVEL_GUIDES.map((g) => ({
              ...g,
              fromCity: { ...g.fromCity },
              title: { ...g.title },
              steps: g.steps.map((s) => ({ ...s })),
            })),
          }),
        );
        return;
      }
      res.json(toTravelGuidesResponse(doc));
    } catch (error) {
      next(error);
    }
  });

  /** Community / temple events for the Events tab. */
  router.get("/events", async (_req, res, next) => {
    try {
      const docs = await Event.find({ status: "published" })
        .sort({ sortOrder: 1, createdAt: -1 })
        .lean();
      const items =
        docs.length > 0
          ? docs
          : DEFAULT_EVENTS.map((e, i) => ({
              _id: `default-${i}`,
              ...e,
              status: "published" as const,
            }));
      res.json({
        items: items.map((e) => ({
          id: String(e._id),
          title: e.title,
          city: e.city,
          dateLabel: e.dateLabel,
          venue: e.venue,
        })),
      });
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

  // Browse is free (wallpapers/ringtones/etc). Premium is enforced on
  // set/share actions in the app, not on listing media.
  router.get("/library", authenticate, async (req, res, next) => {
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
