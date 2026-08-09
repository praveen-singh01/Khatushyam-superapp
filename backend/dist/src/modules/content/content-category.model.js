import { Schema, model } from "mongoose";
const contentCategorySchema = new Schema({
    type: {
        type: String,
        enum: ["wallpaper", "ringtone", "poster"],
        required: true,
        index: true,
    },
    slug: { type: String, required: true, trim: true, lowercase: true },
    label: {
        hi: { type: String, required: true, trim: true },
        en: { type: String, required: true, trim: true },
    },
}, { timestamps: true });
contentCategorySchema.index({ type: 1, slug: 1 }, { unique: true });
export const ContentCategory = model("ContentCategory", contentCategorySchema);
const DEFAULT_CATEGORIES = [
    {
        type: "wallpaper",
        slug: "baba-darshan",
        label: { en: "Baba Darshan", hi: "बाबा दर्शन" },
    },
    {
        type: "wallpaper",
        slug: "khatu-temple",
        label: { en: "Khatu Temple", hi: "खाटू मंदिर" },
    },
    {
        type: "wallpaper",
        slug: "festival",
        label: { en: "Festival", hi: "त्योहार" },
    },
    {
        type: "wallpaper",
        slug: "ekadashi",
        label: { en: "Ekadashi", hi: "एकादशी" },
    },
    {
        type: "wallpaper",
        slug: "quotes",
        label: { en: "Quotes", hi: "उद्धरण" },
    },
    {
        type: "ringtone",
        slug: "jai-shree-shyam",
        label: { en: "Jai Shree Shyam", hi: "जय श्री श्याम" },
    },
    {
        type: "ringtone",
        slug: "shyam-mantra",
        label: { en: "Shyam Mantra", hi: "श्याम मंत्र" },
    },
    {
        type: "ringtone",
        slug: "bhajan",
        label: { en: "Bhajan", hi: "भजन" },
    },
    {
        type: "ringtone",
        slug: "notification",
        label: { en: "Notification", hi: "सूचना" },
    },
    {
        type: "poster",
        slug: "daily",
        label: { en: "Daily Posters", hi: "दैनिक पोस्टर" },
    },
];
export async function ensureDefaultCategories() {
    for (const category of DEFAULT_CATEGORIES) {
        await ContentCategory.updateOne({ type: category.type, slug: category.slug }, { $setOnInsert: category }, { upsert: true });
    }
}
export function categoryResponse(doc) {
    return {
        id: doc._id.toString(),
        type: doc.type,
        slug: doc.slug,
        label: doc.label,
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
    };
}
export async function listCategoriesByType() {
    await ensureDefaultCategories();
    const items = await ContentCategory.find()
        .sort({ type: 1, slug: 1 })
        .lean();
    const wallpaper = items
        .filter((item) => item.type === "wallpaper")
        .map((item) => item.slug);
    const ringtone = items
        .filter((item) => item.type === "ringtone")
        .map((item) => item.slug);
    const poster = items
        .filter((item) => item.type === "poster")
        .map((item) => item.slug);
    return {
        items: items.map(categoryResponse),
        byType: { wallpaper, ringtone, poster },
    };
}
export async function categoryExists(type, slug) {
    await ensureDefaultCategories();
    const found = await ContentCategory.findOne({ type, slug }).lean();
    return Boolean(found);
}
