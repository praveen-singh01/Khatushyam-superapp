import "dotenv/config";
import mongoose from "mongoose";
import { ContentCategory } from "../src/modules/content/content-category.model.js";
import {
  DEFAULT_STORY,
  STORY_KEY,
  Story,
} from "../src/modules/content/story.model.js";

const mongoUri =
  process.env.MONGODB_URI ?? "mongodb://127.0.0.1:27017/khatu_shyam";

await mongoose.connect(mongoUri);

await Story.findOneAndUpdate(
  { key: STORY_KEY },
  {
    $set: {
      key: STORY_KEY,
      title: { ...DEFAULT_STORY.title },
      summary: { ...DEFAULT_STORY.summary },
      youtubeVideoId: DEFAULT_STORY.youtubeVideoId,
      chapters: DEFAULT_STORY.chapters.map((chapter) => ({
        title: { ...chapter.title },
        body: { ...chapter.body },
      })),
    },
  },
  { upsert: true, new: true },
);

const categories = [
  {
    type: "wallpaper" as const,
    slug: "baba-darshan",
    label: { hi: "बाबा दर्शन", en: "Baba Darshan" },
  },
  {
    type: "wallpaper" as const,
    slug: "khatu-temple",
    label: { hi: "खाटू मंदिर", en: "Khatu Temple" },
  },
  {
    type: "wallpaper" as const,
    slug: "festival",
    label: { hi: "त्योहार", en: "Festival" },
  },
  {
    type: "wallpaper" as const,
    slug: "ekadashi",
    label: { hi: "एकादशी", en: "Ekadashi" },
  },
  {
    type: "wallpaper" as const,
    slug: "quotes",
    label: { hi: "कोट्स", en: "Quotes" },
  },
  {
    type: "ringtone" as const,
    slug: "jai-shree-shyam",
    label: { hi: "जय श्री श्याम", en: "Jai Shree Shyam" },
  },
];

for (const category of categories) {
  await ContentCategory.findOneAndUpdate(
    { type: category.type, slug: category.slug },
    { $set: category },
    { upsert: true, new: true },
  );
}

const db = mongoose.connection.db!;
const assetCount = await db.collection("contentassets").countDocuments();
const storyCount = await db.collection("stories").countDocuments();
const categoryCount = await db.collection("contentcategories").countDocuments();

console.info("Seed complete", {
  mongoUri: mongoUri.replace(/\/\/([^:]+):([^@]+)@/, "//$1:***@"),
  assetCount,
  storyCount,
  categoryCount,
});

await mongoose.disconnect();
