import { Schema, model } from "mongoose";
/** Singleton key for the public Shyam Story (खोजें tab). */
export const STORY_KEY = "khatu-shyam-story";
const localizedSchema = new Schema({
    hi: { type: String, required: true, trim: true },
    en: { type: String, required: true, trim: true },
}, { _id: false });
const chapterSchema = new Schema({
    title: { type: localizedSchema, required: true },
    body: { type: localizedSchema, required: true },
}, { _id: false });
const storySchema = new Schema({
    key: {
        type: String,
        required: true,
        unique: true,
        default: STORY_KEY,
        trim: true,
    },
    title: { type: localizedSchema, required: true },
    summary: { type: localizedSchema, required: true },
    youtubeVideoId: { type: String, default: null, trim: true },
    chapters: {
        type: [chapterSchema],
        default: [],
        validate: {
            validator: (chapters) => chapters.length >= 1,
            message: "At least one chapter is required",
        },
    },
    updatedBy: String,
}, { timestamps: true });
export const Story = model("Story", storySchema);
export const DEFAULT_STORY = {
    title: {
        hi: "खाटू श्याम बाबा की कथा",
        en: "The story of Khatu Shyam Baba",
    },
    summary: {
        hi: "महाभारत के बबरिक से खाटू धाम के श्याम बाबा तक — भक्ति की अमर कथा। सरल अध्यायों में पढ़ें।",
        en: "From Barbarik of the Mahabharata to Shyam Baba of Khatu — an immortal story of devotion.",
    },
    youtubeVideoId: null,
    chapters: [
        {
            title: { hi: "बबरिक कौन थे?", en: "Who was Barbarik?" },
            body: {
                hi: "बबरिक घटोत्कच के पुत्र और भीम के पौत्र थे। बचपन से ही वे अपार शक्ति और अद्भुत धनुर्विद्या के धनी माने जाते थे। तीन बाणों से पूरे युद्ध को समाप्त करने की शक्ति उन्हें प्राप्त हुई — इसीलिए उन्हें तीन बाणधारी योद्धा कहा जाता है।",
                en: "Barbarik was the son of Ghatotkacha and grandson of Bhima. From childhood he was known for immense strength and archery. He received the power to end a war with three arrows — hence the three-arrow warrior.",
            },
        },
        {
            title: { hi: "तीन बाणों की शक्ति", en: "Power of three arrows" },
            body: {
                hi: "कहा जाता है कि उनका पहला बाण लक्ष्य चिन्हित करता, दूसरा उसे नष्ट करता, और तीसरा बाण वापस तरकश में लौट आता। महाभारत युद्ध में वे पांडवों की ओर से लड़ना चाहते थे, पर उनकी शक्ति इतनी प्रबल थी कि युद्ध का संतुलन बिगड़ सकता था।",
                en: "The first arrow marked the target, the second destroyed it, and the third returned to the quiver. He wished to fight for the Pandavas, but his power could unbalance the entire war.",
            },
        },
        {
            title: { hi: "शीश दान", en: "The sacrifice of the head" },
            body: {
                hi: "भगवान श्रीकृष्ण ने बबरिक की परीक्षा ली और युद्ध-भूमि से युद्ध देखने का वर माँगा। भक्त बबरिक ने कृष्ण की इच्छा पर अपना शीश अर्पित कर दिया। कृष्ण ने वर दिया कि कलियुग में उनकी भक्ति सबसे प्रिय होगी और वे श्याम नाम से पूजे जाएँगे।",
                en: "Lord Krishna tested Barbarik and asked for the boon of watching the war from the battlefield. The devotee offered his head at Krishna's wish. Krishna blessed that in Kaliyuga his devotion would be dearest, and he would be worshipped as Shyam.",
            },
        },
        {
            title: { hi: "खाटू में विराजमान", en: "Enshrined at Khatu" },
            body: {
                hi: "भगवान की कृपा से उनका शीश राजस्थान के खाटू धाम में विराजमान हुआ। आज करोड़ों भक्त खाटू श्याम बाबा के दर्शन करते हैं, जय श्री श्याम का जयघोष करते हैं, और भक्ति से मनोकामनाएँ पूर्ण होने की आस्था रखते हैं।",
                en: "By divine grace his head was enshrined at Khatu Dham in Rajasthan. Today crores of devotees seek darshan of Khatu Shyam Baba, chant Jai Shree Shyam, and keep faith that devotion fulfills sincere wishes.",
            },
        },
        {
            title: { hi: "आज की भक्ति", en: "Devotion today" },
            body: {
                hi: "एकादशी, अमावस्या और विशेष उत्सवों पर खाटू धाम में भक्तों की भीड़ लगती है। घर बैठे भी श्याम नाम का जाप, आरती, भजन और सेवा — यही सच्ची भक्ति है। जय श्री श्याम।",
                en: "On Ekadashi, Amavasya and festivals, devotees gather at Khatu Dham. Even from home, chanting Shyam's name, aarti, bhajans and seva — this is true devotion. Jai Shree Shyam.",
            },
        },
    ],
};
export function toStoryResponse(doc) {
    const youtubeVideoId = doc.youtubeVideoId && doc.youtubeVideoId.trim()
        ? doc.youtubeVideoId.trim()
        : null;
    return {
        title: doc.title,
        summary: doc.summary,
        youtubeVideoId,
        chapters: doc.chapters,
        access: "free",
        updatedAt: doc.updatedAt ?? null,
    };
}
