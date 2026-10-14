import { Schema, model } from "mongoose";
const eventSchema = new Schema({
    title: { type: String, required: true, trim: true, maxlength: 160 },
    city: { type: String, required: true, trim: true, maxlength: 80 },
    dateLabel: { type: String, required: true, trim: true, maxlength: 80 },
    venue: { type: String, required: true, trim: true, maxlength: 160 },
    status: {
        type: String,
        enum: ["published", "hidden"],
        default: "published",
    },
    sortOrder: { type: Number, default: 0 },
}, { timestamps: true });
eventSchema.index({ status: 1, sortOrder: 1, createdAt: -1 });
export const Event = model("Event", eventSchema);
export const DEFAULT_EVENTS = [
    {
        title: "Phalgun Mela — Khatu Dham",
        city: "Khatu (Sikar)",
        dateLabel: "Phalgun Gyaras · Mandir parisar",
        venue: "Shri Khatu Shyam Ji Mandir",
        sortOrder: 10,
    },
    {
        title: "Raat bhar Kirtan",
        city: "Sikar",
        dateLabel: "Har Shaniwar · Shaam 8 baje",
        venue: "Shyam Mandir Chowk",
        sortOrder: 20,
    },
    {
        title: "Bhajan Sandhya",
        city: "Jaipur",
        dateLabel: "Agle Raviwaar · Shaam 6 baje",
        venue: "Community Hall, C-Scheme",
        sortOrder: 30,
    },
    {
        title: "Ghar Kirtan — Shyam Naam",
        city: "Delhi",
        dateLabel: "Mahina ki pehli Ekadashi",
        venue: "Sector 12, Rohini",
        sortOrder: 40,
    },
    {
        title: "Nagar Sankirtan",
        city: "Ringas",
        dateLabel: "Amavasya ki subah · 6 baje",
        venue: "Bus Stand se Mandir marg",
        sortOrder: 50,
    },
    {
        title: "Bal Bhakt Sammelan",
        city: "Jaipur",
        dateLabel: "Agle Mahine · Dopahar 2 baje",
        venue: "Shyam Bhawan, Tonk Road",
        sortOrder: 60,
    },
];
