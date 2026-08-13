/**
 * Replace all ringtone ContentAssets with audio from a local folder:
 * 1) delete previous ringtone docs in Mongo
 * 2) upload each file to S3 under khatu-shyam/ringtones/<category>/
 * 3) insert published ContentAsset rows
 *
 * Usage:
 *   npx tsx scripts/replace-ringtones-from-folder.ts /tmp/khatu-ringtones-drive
 *   npx tsx scripts/replace-ringtones-from-folder.ts /tmp/khatu-ringtones-drive --keep-s3
 */
import "dotenv/config";
import { createHash } from "node:crypto";
import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";
import {
  DeleteObjectsCommand,
  ListObjectsV2Command,
  PutObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";
import mongoose from "mongoose";
import { ContentAsset } from "../src/modules/content/content-asset.model.js";
import { S3_MEDIA_PREFIX } from "../src/shared/media-paths.js";

const folderArg = process.argv[2];
const keepOldS3 = process.argv.includes("--keep-s3");
const category = "jai-shree-shyam";

if (!folderArg) {
  console.error(
    "Usage: npx tsx scripts/replace-ringtones-from-folder.ts <local-folder>",
  );
  process.exit(1);
}

const folder = path.resolve(folderArg);
const bucket = process.env.S3_MEDIA_BUCKET;
const region = process.env.AWS_REGION ?? "ap-south-1";
const mongoUri = process.env.MONGODB_URI;

if (!bucket || !mongoUri) {
  console.error("S3_MEDIA_BUCKET and MONGODB_URI are required in .env");
  process.exit(1);
}

const s3 = new S3Client({
  region,
  credentials:
    process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY
      ? {
          accessKeyId: process.env.AWS_ACCESS_KEY_ID,
          secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        }
      : undefined,
});

const AUDIO_EXT = new Set([".mp3", ".m4a", ".aac", ".wav", ".ogg"]);

function slugify(name: string, index: number): string {
  const base = name
    .replace(/\.[^.]+$/, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 48);
  const safe = base || `ringtone-${index + 1}`;
  return `rt-${String(index + 1).padStart(2, "0")}-${safe}`;
}

function titleFromFilename(name: string): { hi: string; en: string } {
  const raw = name
    .replace(/\.[^.]+$/, "")
    .replace(/\(\d+\)/g, "")
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  const en = raw || "Khatu Shyam Ringtone";
  return { hi: en, en };
}

function contentTypeFor(ext: string): string {
  switch (ext) {
    case ".m4a":
      return "audio/mp4";
    case ".aac":
      return "audio/aac";
    case ".wav":
      return "audio/wav";
    case ".ogg":
      return "audio/ogg";
    default:
      return "audio/mpeg";
  }
}

async function listRingtoneKeys(): Promise<string[]> {
  const keys: string[] = [];
  let token: string | undefined;
  const prefix = `${S3_MEDIA_PREFIX}/ringtones/`;
  do {
    const page = await s3.send(
      new ListObjectsV2Command({
        Bucket: bucket,
        Prefix: prefix,
        ContinuationToken: token,
      }),
    );
    for (const obj of page.Contents ?? []) {
      if (obj.Key) keys.push(obj.Key);
    }
    token = page.IsTruncated ? page.NextContinuationToken : undefined;
  } while (token);
  return keys;
}

async function deleteS3Keys(keys: string[]) {
  for (let i = 0; i < keys.length; i += 1000) {
    const chunk = keys.slice(i, i + 1000);
    if (chunk.length === 0) continue;
    await s3.send(
      new DeleteObjectsCommand({
        Bucket: bucket,
        Delete: {
          Objects: chunk.map((Key) => ({ Key })),
          Quiet: true,
        },
      }),
    );
  }
}

const entries = (await readdir(folder))
  .filter((name) => AUDIO_EXT.has(path.extname(name).toLowerCase()))
  .sort((a, b) => a.localeCompare(b));

if (entries.length === 0) {
  console.error(`No audio files found in ${folder}`);
  process.exit(1);
}

console.info(`Found ${entries.length} audio files in ${folder}`);
await mongoose.connect(mongoUri);

const deleted = await ContentAsset.deleteMany({ type: "ringtone" });
console.info(`Deleted ${deleted.deletedCount ?? 0} ringtone docs from Mongo`);

if (!keepOldS3) {
  const oldKeys = await listRingtoneKeys();
  console.info(`Found ${oldKeys.length} S3 ringtone objects under prefix`);
  if (oldKeys.length) {
    await deleteS3Keys(oldKeys);
    console.info(`Deleted ${oldKeys.length} old ringtone objects from S3`);
  }
}

let uploaded = 0;
for (const [index, name] of entries.entries()) {
  const abs = path.join(folder, name);
  const st = await stat(abs);
  if (!st.isFile()) continue;

  const ext = path.extname(name).toLowerCase();
  const slug = slugify(name, index);
  const safeFile = `${slug}${ext}`;
  const fileKey = `${S3_MEDIA_PREFIX}/ringtones/${category}/${safeFile}`;
  const body = await readFile(abs);
  const etag = createHash("md5").update(body).digest("hex");

  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: fileKey,
      Body: body,
      ContentType: contentTypeFor(ext),
      CacheControl: "public, max-age=31536000, immutable",
      Metadata: {
        source: "google-drive-ringtones",
        md5: etag,
      },
    }),
  );

  const title = titleFromFilename(name);
  await ContentAsset.create({
    slug,
    type: "ringtone",
    category,
    title,
    fileKey,
    format: ext.replace(".", ""),
    premium: true,
    source: "google-drive-ringtones",
    status: "published",
  });

  uploaded += 1;
  console.info(`✓ ${uploaded}/${entries.length} ${safeFile}`);
}

const count = await ContentAsset.countDocuments({ type: "ringtone" });
console.info(
  `Done. Uploaded ${uploaded} ringtones. Mongo ringtone count=${count}`,
);
await mongoose.disconnect();
