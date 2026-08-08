import "dotenv/config";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import mongoose from "mongoose";
import { ContentAsset } from "../src/modules/content/content-asset.model.js";

interface MetadataAsset {
  id: string;
  type: "wallpaper" | "ringtone";
  category: string;
  title: { hi: string; en: string };
  file: string;
  format: string;
  width?: number;
  height?: number;
  durationSeconds?: number;
  license?: string;
  attribution?: string;
  premium?: boolean;
  source?: string;
}

interface MetadataFile {
  assets: MetadataAsset[];
}

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const defaultMetadataPath = path.resolve(
  __dirname,
  "../../khatu-shyam-content/metadata.json",
);

const metadataPath = process.argv[2] ?? defaultMetadataPath;
const mongoUri =
  process.env.MONGODB_URI ?? "mongodb://127.0.0.1:27017/khatu_shyam_local";

const raw = await readFile(metadataPath, "utf8");
const metadata = JSON.parse(raw) as MetadataFile;

await mongoose.connect(mongoUri);

let upserted = 0;
for (const asset of metadata.assets ?? []) {
  await ContentAsset.findOneAndUpdate(
    { slug: asset.id },
    {
      $set: {
        slug: asset.id,
        type: asset.type,
        category: asset.category,
        title: asset.title,
        fileKey: `khatu-shyam-content/${asset.file}`,
        format: asset.format,
        width: asset.width,
        height: asset.height,
        durationSeconds: asset.durationSeconds,
        license: asset.license,
        attribution: asset.attribution,
        premium: asset.premium ?? true,
        source: asset.source,
        status: "published",
      },
    },
    { upsert: true, new: true },
  );
  upserted += 1;
}

console.info(
  `Seeded ${upserted} content assets from ${metadataPath} into ${mongoUri}`,
);
await mongoose.disconnect();
