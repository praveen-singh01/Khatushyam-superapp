import "dotenv/config";
import mongoose from "mongoose";
import { User } from "../src/modules/auth/user.model.js";
import { Chamatkar } from "../src/modules/chamatkars/chamatkar.model.js";

const mongoUri =
  process.env.MONGODB_URI ?? "mongodb://127.0.0.1:27017/khatu_shyam";

const samples = [
  {
    title: "बाबा की कृपा से काम बन गया",
    story:
      "मैं नौकरी के लिए बहुत परेशान था। खाटू धाम की यात्रा के बाद ही इंटरव्यू कॉल आया और चयन हो गया। जय श्री श्याम!",
    language: "hi" as const,
  },
  {
    title: "बीमार माँ स्वस्थ हुईं",
    story:
      "माँ लंबे समय से बीमार थीं। रोज श्याम बाबा का नाम जपने और सातवारे के बाद उनकी तबीयत में सुधार आने लगा।",
    language: "hi" as const,
  },
  {
    title: "Lost wallet returned",
    story:
      "I lost my wallet at the temple complex. After praying at Baba's darshan, a devotee returned it with everything intact. Jai Shree Shyam.",
    language: "en" as const,
  },
];

await mongoose.connect(mongoUri);

let author = await User.findOne({ email: "admin@khatushyam.app" });
if (!author) {
  author = await User.create({
    firebaseUid: "seed-chamatkar-author",
    email: "seed@khatushyam.app",
    displayName: "Khatu Devotee",
    role: "user",
    subscriptionStatus: "inactive",
  });
}

const existing = await Chamatkar.countDocuments({ status: "published" });
if (existing > 0) {
  console.info(`Chamatkars already present (${existing}); skipping seed.`);
} else {
  for (const sample of samples) {
    await Chamatkar.create({
      authorId: author._id,
      authorName: author.displayName || "Khatu Devotee",
      title: sample.title,
      story: sample.story,
      language: sample.language,
      status: "published",
      likeCount: 0,
      likedBy: [],
    });
  }
  console.info(`Seeded ${samples.length} chamatkars`);
}

const counts = {
  chamatkars: await Chamatkar.countDocuments(),
  contentassets: await mongoose.connection.db!.collection("contentassets").countDocuments(),
  stories: await mongoose.connection.db!.collection("stories").countDocuments(),
};
console.info("DB counts", counts);

await mongoose.disconnect();
