import { Schema, model } from "mongoose";
const contentAssetSchema = new Schema({
    slug: { type: String, required: true, unique: true, trim: true, index: true },
    type: {
        type: String,
        enum: ["wallpaper", "ringtone"],
        required: true,
        index: true,
    },
    category: { type: String, required: true, trim: true, index: true },
    title: {
        hi: { type: String, required: true, trim: true },
        en: { type: String, required: true, trim: true },
    },
    fileKey: { type: String, required: true, trim: true },
    format: { type: String, required: true, trim: true },
    width: Number,
    height: Number,
    durationSeconds: Number,
    license: String,
    attribution: String,
    premium: { type: Boolean, default: true, index: true },
    source: String,
    status: {
        type: String,
        enum: ["draft", "published", "archived"],
        default: "published",
        index: true,
    },
    uploadedBy: String,
}, { timestamps: true });
contentAssetSchema.index({ type: 1, category: 1, status: 1, createdAt: -1 });
export const ContentAsset = model("ContentAsset", contentAssetSchema);
