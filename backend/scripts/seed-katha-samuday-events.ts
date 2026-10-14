/**
 * Seeds richer Shyam Katha chapters, realistic Samuday (chamatkar) posts,
 * and Events into MongoDB (uses MONGODB_URI from .env — prod when pointed there).
 *
 *   cd backend && npx tsx scripts/seed-katha-samuday-events.ts
 */
import "dotenv/config";
import mongoose from "mongoose";
import { User } from "../src/modules/auth/user.model.js";
import { Chamatkar } from "../src/modules/chamatkars/chamatkar.model.js";
import {
  DEFAULT_STORY,
  STORY_KEY,
  Story,
} from "../src/modules/content/story.model.js";
import {
  DEFAULT_EVENTS,
  Event,
} from "../src/modules/content/event.model.js";

const mongoUri =
  process.env.MONGODB_URI ?? "mongodb://127.0.0.1:27017/khatu_shyam";

const samudayPosts: Array<{
  authorName: string;
  title: string;
  story: string;
  language: "hi" | "en";
  likeCount: number;
}> = [
  {
    authorName: "Ramesh Jangid",
    title: "नौकरी मिलते ही आँसू आ गए",
    story:
      "दो साल से इंटरव्यू दे-देकर थक गया था। घरवाले पूछते तो जवाब नहीं सूझता था। एक शनिवार खाटू जाकर बाबा के सामने सिर्फ इतना कहा — बाबा, रास्ता खोल दो। लौटकर आया तो उसी हफ्ते एक कंपनी से कॉल आया और जॉइनिंग लेटर मिल गया। सच्चाई ये है कि मेहनत भी थी, पर भरोसा बाबा ने दिया। जय श्री श्याम 🙏",
    language: "hi",
    likeCount: 48,
  },
  {
    authorName: "Sunita Devi",
    title: "बेटे की तबियत सुधरी",
    story:
      "बेटा बहुत बीमार था, डॉक्टर भी उलझन में थे। मैंने सातवारा रखा — हर शनिवार बाबा का नाम और आरती। सातवें शनिवार को रिपोर्ट सामान्य आने लगी। आज वो स्कूल जाता है और खुद जय श्री श्याम बोलता है। बाबा, कृपा का कोई हिसाब नहीं।",
    language: "hi",
    likeCount: 72,
  },
  {
    authorName: "Amit Sharma",
    title: "Lost bag found at Ringas",
    story:
      "I left my bag in a shared taxi near Ringas with documents and cash. Panic set in. I just folded my hands and said Jai Shree Shyam. Within an hour the driver called back — another passenger had kept it safe. Everything was intact. Still get goosebumps thinking about it.",
    language: "en",
    likeCount: 35,
  },
  {
    authorName: "Priya Meghwal",
    title: "शादी का रिश्ता अटक गया था",
    story:
      "रिश्ता लगभग तय था फिर अचानक टूटने लगा। घर में तनाव बढ़ गया। मैंने बाबा से कहा — जो अच्छा हो वही हो। फाल्गुन ग्यारस के बाद वही परिवार वापस आया और शादी तय हो गई। आज भी जब मंदिर की घंटी याद आती है तो दिल भर आता है। जय श्री श्याम।",
    language: "hi",
    likeCount: 91,
  },
  {
    authorName: "Vikram Singh",
    title: "कर्ज से राहत मिली",
    story:
      "व्यापार में घाटा हुआ और कर्ज बढ़ गया था। नींद नहीं आती थी। एक भक्त मित्र ने कहा — बाबा के पास झूठ मत बोलना, सिर्फ हिम्मत माँगना। मैंने हिम्मत माँगी। धीरे-धीरे ऑर्डर आने लगे, किस्तें समय पर भर पा रहा हूँ। अभी भी संघर्ष है, पर अकेलापन नहीं रहा। धन्यवाद बाबा।",
    language: "hi",
    likeCount: 56,
  },
  {
    authorName: "Neha Gupta",
    title: "First visit to Khatu changed me",
    story:
      "I went to Khatu with my parents almost casually. Standing in the queue, hearing Jai Shree Shyam all around, something softened inside. Since that trip I do evening aarti at home. Life problems didn't vanish overnight, but the fear did. Sharing so other first-timers don't hesitate.",
    language: "en",
    likeCount: 40,
  },
  {
    authorName: "Manoj Saini",
    title: "बारिश में फँसे थे, रास्ता खुल गया",
    story:
      "सीकर से खाटू जाते समय भारी बारिश हो गई, सड़क जलभराव से बंद लग रही थी। ड्राइवर वापस लौटना चाहता था। हमने बाबा का नाम लिया और थोड़ी देर रुके। एक लोकल व्यक्ति ने छोटा सा कच्चा रास्ता बताया और हम समय पर आरती पहुँच गए। छोटी सी बात लगती है, पर उस दिन बहुत बड़ी कृपा लगी।",
    language: "hi",
    likeCount: 29,
  },
  {
    authorName: "Kavita Rathore",
    title: "परीक्षा का डर गया",
    story:
      "बेटी की बोर्ड परीक्षा पास थी और रात-रात भर रोती थी। मैंने उसके साथ रोज थोड़ी देर श्याम भजन लगाया। परीक्षा के दिन वो शांत रही और अच्छा स्कोर आया। मैं कहती हूँ — नंबर बाबा नहीं लिखते, पर हिम्मत जरूर देते हैं। जय श्री श्याम।",
    language: "hi",
    likeCount: 63,
  },
  {
    authorName: "Suresh Yadav",
    title: "मंदिर में मिला पुराना दोस्त",
    story:
      "पंद्रह साल से कोई खबर नहीं थी एक स्कूल के दोस्त की। खाटू धाम दर्शन के लिए लाइन में खड़ा था तो अचानक वही सामने मिल गया — वो भी परिवार के साथ आया था। दोनों रो पड़े। बाबा मिलाते भी हैं, ये बात उस दिन समझ आई।",
    language: "hi",
    likeCount: 44,
  },
  {
    authorName: "Ananya Jain",
    title: "Quiet blessing during tough pregnancy",
    story:
      "Doctors advised complete rest. I couldn't travel to Khatu, so I just listened to Shyam bhajans every evening. Neighbours brought prasad from the temple once. Delivery went safely. Writing this with my baby sleeping beside me — Jai Shree Shyam.",
    language: "en",
    likeCount: 88,
  },
];

await mongoose.connect(mongoUri);
console.info("Connected:", mongoUri.replace(/\/\/.*@/, "//***@"));

// —— 1) Expand Shyam Katha ——
const storyResult = await Story.findOneAndUpdate(
  { key: STORY_KEY },
  {
    $set: {
      title: DEFAULT_STORY.title,
      summary: {
        hi: "महाभारत के बबरिक से खाटू धाम के श्याम बाबा तक — भक्ति की अमर कथा। फागुन मेला, सातवारा और श्याम नाम की महिमा सहित विस्तारित अध्याय।",
        en: "From Barbarik of the Mahabharata to Shyam Baba of Khatu — with chapters on Phalgun Mela, Saatwara and the glory of Shyam's name.",
      },
      youtubeVideoId: DEFAULT_STORY.youtubeVideoId,
      chapters: DEFAULT_STORY.chapters.map((c) => ({
        title: { ...c.title },
        body: { ...c.body },
      })),
    },
  },
  { upsert: true, new: true },
);
console.info(
  `Story upserted with ${storyResult?.chapters?.length ?? 0} chapters`,
);

// —— 2) Samuday / chamatkar posts ——
let author = await User.findOne({ email: "admin@khatushyam.app" });
if (!author) {
  author = await User.findOne({ email: "seed@khatushyam.app" });
}
if (!author) {
  author = await User.create({
    firebaseUid: "seed-samuday-author",
    email: "seed@khatushyam.app",
    displayName: "Khatu Devotee",
    role: "user",
    subscriptionStatus: "inactive",
  });
}

let added = 0;
let skipped = 0;
for (const post of samudayPosts) {
  const exists = await Chamatkar.findOne({ title: post.title }).lean();
  if (exists) {
    skipped += 1;
    continue;
  }
  await Chamatkar.create({
    authorId: author._id,
    authorName: post.authorName,
    title: post.title,
    story: post.story,
    language: post.language,
    status: "published",
    likeCount: post.likeCount,
    likedBy: [],
  });
  added += 1;
}
console.info(`Samuday posts: added ${added}, skipped existing ${skipped}`);

// —— 3) Events ——
let eventsAdded = 0;
for (const event of DEFAULT_EVENTS) {
  const exists = await Event.findOne({
    title: event.title,
    city: event.city,
  }).lean();
  if (exists) continue;
  await Event.create({
    ...event,
    status: "published",
  });
  eventsAdded += 1;
}
console.info(`Events: added ${eventsAdded}`);

const counts = {
  stories: await Story.countDocuments(),
  storyChapters: storyResult?.chapters?.length ?? 0,
  chamatkars: await Chamatkar.countDocuments({ status: "published" }),
  events: await Event.countDocuments({ status: "published" }),
};
console.info("DB counts", counts);

await mongoose.disconnect();
