import { Schema, model } from "mongoose";
/** Singleton key for the active Khatu Shyam Live Darshan config. */
export const LIVE_STREAM_KEY = "khatu-shyam-live";
const liveStreamSchema = new Schema({
    key: {
        type: String,
        required: true,
        unique: true,
        default: LIVE_STREAM_KEY,
        trim: true,
    },
    isLive: { type: Boolean, default: false, index: true },
    youtubeVideoId: { type: String, default: null, trim: true },
    title: {
        hi: {
            type: String,
            required: true,
            trim: true,
            default: "खाटू श्याम लाइव दर्शन",
        },
        en: {
            type: String,
            required: true,
            trim: true,
            default: "Khatu Shyam Live Darshan",
        },
    },
    updatedBy: String,
}, { timestamps: true });
export const LiveStream = model("LiveStream", liveStreamSchema);
export const DEFAULT_LIVE_TITLE = {
    hi: "खाटू श्याम लाइव दर्शन",
    en: "Khatu Shyam Live Darshan",
};
/** Accepts an 11-char ID or common YouTube watch/live/embed/youtu.be URLs. */
export function extractYoutubeVideoId(input) {
    const trimmed = input.trim();
    if (/^[a-zA-Z0-9_-]{11}$/.test(trimmed))
        return trimmed;
    try {
        const url = new URL(trimmed);
        const host = url.hostname.replace(/^www\./, "");
        if (host === "youtu.be") {
            const id = url.pathname.split("/").filter(Boolean)[0] ?? "";
            return /^[a-zA-Z0-9_-]{11}$/.test(id) ? id : null;
        }
        if (host === "youtube.com" || host === "m.youtube.com" || host === "music.youtube.com") {
            const fromQuery = url.searchParams.get("v");
            if (fromQuery && /^[a-zA-Z0-9_-]{11}$/.test(fromQuery)) {
                return fromQuery;
            }
            const parts = url.pathname.split("/").filter(Boolean);
            for (let i = 0; i < parts.length - 1; i += 1) {
                if ((parts[i] === "live" || parts[i] === "embed" || parts[i] === "shorts") &&
                    /^[a-zA-Z0-9_-]{11}$/.test(parts[i + 1])) {
                    return parts[i + 1];
                }
            }
        }
    }
    catch {
        // Not a URL.
    }
    return null;
}
export function toLiveStreamResponse(doc) {
    const videoId = doc.isLive && doc.youtubeVideoId ? doc.youtubeVideoId : null;
    return {
        isLive: Boolean(doc.isLive && videoId),
        youtubeVideoId: videoId,
        title: doc.title,
        embedUrl: videoId
            ? `https://www.youtube.com/embed/${videoId}`
            : null,
        access: "free",
        updatedAt: doc.updatedAt ?? null,
    };
}
