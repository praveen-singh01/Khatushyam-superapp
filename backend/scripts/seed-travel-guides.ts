import "dotenv/config";
import mongoose from "mongoose";
import {
  DEFAULT_TRAVEL_GUIDES,
  TRAVEL_GUIDES_KEY,
  TravelGuides,
} from "../src/modules/content/travel-guide.model.js";

const mongoUri = process.env.MONGODB_URI;
if (!mongoUri) {
  console.error("MONGODB_URI required");
  process.exit(1);
}

await mongoose.connect(mongoUri);
const doc = await TravelGuides.findOneAndUpdate(
  { key: TRAVEL_GUIDES_KEY },
  {
    $set: {
      key: TRAVEL_GUIDES_KEY,
      guides: DEFAULT_TRAVEL_GUIDES,
    },
  },
  { upsert: true, new: true, setDefaultsOnInsert: true },
);
console.info(
  `Seeded travel guides (${doc.guides.length}):`,
  doc.guides.map((g) => g.id).join(", "),
);
await mongoose.disconnect();
