import { Schema, model } from "mongoose";
/** Singleton key for Travel Guides CMS (admin-editable list). */
export const TRAVEL_GUIDES_KEY = "khatu-shyam-travel-guides";
const localizedSchema = new Schema({
    hi: { type: String, required: true, trim: true },
    en: { type: String, required: true, trim: true },
}, { _id: false });
const guideSchema = new Schema({
    id: { type: String, required: true, trim: true },
    fromCity: { type: localizedSchema, required: true },
    title: { type: localizedSchema, required: true },
    steps: {
        type: [localizedSchema],
        default: [],
        validate: {
            validator: (steps) => steps.length >= 1,
            message: "At least one step is required",
        },
    },
}, { _id: false });
const travelGuidesSchema = new Schema({
    key: {
        type: String,
        required: true,
        unique: true,
        default: TRAVEL_GUIDES_KEY,
        trim: true,
    },
    guides: {
        type: [guideSchema],
        default: [],
        validate: {
            validator: (guides) => guides.length >= 1,
            message: "At least one travel guide is required",
        },
    },
    updatedBy: String,
}, { timestamps: true });
export const TravelGuides = model("TravelGuides", travelGuidesSchema);
/** Sample: how to reach Khatu — Hinglish (admin can edit anytime). */
export const DEFAULT_TRAVEL_GUIDES = [
    {
        id: "how-to-reach-khatu",
        fromCity: {
            hi: "Delhi / Jaipur / Anywhere",
            en: "Delhi / Jaipur / Anywhere",
        },
        title: {
            hi: "Khatu kaise pahunchein",
            en: "Khatu kaise pahunchein",
        },
        steps: [
            {
                hi: "Sabse pehle nearest city decide karo — Delhi, Jaipur, ya Sikar. Train/bus tickets pehle book kar lo, specially weekends aur Gyaras pe.",
                en: "Sabse pehle nearest city decide karo — Delhi, Jaipur, ya Sikar. Train/bus tickets pehle book kar lo, specially weekends aur Gyaras pe.",
            },
            {
                hi: "Delhi se: New Delhi / Delhi Cantt se Sikar / Ringas side ki train lo. Jaipur se: Sindhi Camp se Sikar bus common hai.",
                en: "Delhi se: New Delhi / Delhi Cantt se Sikar / Ringas side ki train lo. Jaipur se: Sindhi Camp se Sikar bus common hai.",
            },
            {
                hi: "Sikar / Ringas se Khatu Shyam Ji ke liye direct bus ya shared taxi milti hai — 45–60 min lagte hain. Driver se ‘Khatu Mandir’ bol dena.",
                en: "Sikar / Ringas se Khatu Shyam Ji ke liye direct bus ya shared taxi milti hai — 45–60 min lagte hain. Driver se ‘Khatu Mandir’ bol dena.",
            },
            {
                hi: "Mandir campus ke paas parking / joota-stand / drinking water milta hai. Subah jaldi pahucho — bheed kam, darshan smooth.",
                en: "Mandir campus ke paas parking / joota-stand / drinking water milta hai. Subah jaldi pahucho — bheed kam, darshan smooth.",
            },
            {
                hi: "Tip: summer mein paani bottle + cap rakho. Wapas aate time same bus/taxi stand se return mil jayega. Jai Shree Shyam!",
                en: "Tip: summer mein paani bottle + cap rakho. Wapas aate time same bus/taxi stand se return mil jayega. Jai Shree Shyam!",
            },
        ],
    },
];
export function toTravelGuidesResponse(doc) {
    return {
        guides: doc.guides.map((g) => ({
            id: g.id,
            fromCity: g.fromCity,
            title: g.title,
            steps: g.steps,
        })),
        updatedAt: doc.updatedAt ?? null,
    };
}
