import "dotenv/config";
import {
  DeleteObjectCommand,
  GetObjectCommand,
  HeadBucketCommand,
  ListBucketsCommand,
  ListObjectsV2Command,
  PutObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";

function mask(value: string) {
  if (!value) return "(missing)";
  return `${value.slice(0, 4)}…${value.slice(-4)} (len=${value.length})`;
}

const region = (process.env.AWS_REGION || "ap-south-1").trim();
const accessKeyId = (
  process.env.AWS_ACCESS_KEY_ID ||
  process.env.AWS_ACCESS_KEY ||
  ""
).trim();
const secretAccessKey = (
  process.env.AWS_SECRET_ACCESS_KEY ||
  process.env.AWS_SECRET_KEY ||
  ""
).trim();
const configuredBucket = (
  process.env.S3_MEDIA_BUCKET ||
  process.env.AWS_S3_BUCKET ||
  ""
).trim();

console.log("=== Config check (no secrets) ===");
console.log({
  region,
  accessKeyId: mask(accessKeyId),
  secretAccessKey: secretAccessKey
    ? `set (len=${secretAccessKey.length})`
    : "(missing)",
  S3_MEDIA_BUCKET: configuredBucket || "(missing)",
  AWS_S3_BUCKET: (process.env.AWS_S3_BUCKET || "").trim() || "(missing/commented)",
  CLOUDFRONT_BASE_URL: process.env.CLOUDFRONT_BASE_URL || "(missing)",
  CLOUDFRONT_DOMAIN: process.env.CLOUDFRONT_DOMAIN || "(missing)",
  looksLikeCloudFrontInBucketField: configuredBucket.includes("cloudfront.net"),
  sdkExpectedVars: {
    AWS_ACCESS_KEY_ID: Boolean(process.env.AWS_ACCESS_KEY_ID),
    AWS_SECRET_ACCESS_KEY: Boolean(process.env.AWS_SECRET_ACCESS_KEY),
    customAWS_ACCESS_KEY: Boolean(process.env.AWS_ACCESS_KEY),
    customAWS_SECRET_KEY: Boolean(process.env.AWS_SECRET_KEY),
  },
});

if (!accessKeyId || !secretAccessKey) {
  console.error("FAIL: missing credentials");
  process.exit(1);
}

const s3 = new S3Client({
  region,
  credentials: { accessKeyId, secretAccessKey },
});

async function tryHead(bucket: string) {
  try {
    await s3.send(new HeadBucketCommand({ Bucket: bucket }));
    return { bucket, ok: true as const };
  } catch (error) {
    const err = error as Error & { name?: string; Code?: string; $metadata?: { httpStatusCode?: number } };
    return {
      bucket,
      ok: false as const,
      code: err.name || err.Code || err.$metadata?.httpStatusCode,
      message: err.message,
    };
  }
}

console.log("\n=== ListBuckets ===");
try {
  const listed = await s3.send(new ListBucketsCommand({}));
  console.log(
    "OK buckets:",
    (listed.Buckets || []).map((bucket) => bucket.Name),
  );
} catch (error) {
  const err = error as Error;
  console.log("ListBuckets FAILED:", err.name, err.message);
}

const candidates = [
  configuredBucket,
  "mitro-app-assets",
  "khatu-shyam-media-dev",
  "khatu-shyam",
].filter(Boolean);
const uniq = [...new Set(candidates)];

console.log("\n=== HeadBucket candidates ===");
const headResults = [];
for (const bucket of uniq) {
  const result = await tryHead(bucket);
  headResults.push(result);
  console.log(result);
}

const writable = headResults.find((result) => result.ok)?.bucket;
if (!writable) {
  console.log("\nRESULT: No accessible bucket found with these credentials.");
  process.exit(2);
}

const key = `khatu-shyam/_connectivity-test/${Date.now()}.txt`;
const body = `khatu-shyam s3 connectivity test ${new Date().toISOString()}`;

console.log(
  `\n=== Put/Get/Delete under prefix khatu-shyam/ in bucket ${writable} ===`,
);
try {
  await s3.send(
    new PutObjectCommand({
      Bucket: writable,
      Key: key,
      Body: body,
      ContentType: "text/plain",
    }),
  );
  console.log("PutObject OK:", key);

  const got = await s3.send(new GetObjectCommand({ Bucket: writable, Key: key }));
  const text = await got.Body!.transformToString();
  console.log(
    "GetObject OK:",
    text === body ? "content matches" : "CONTENT MISMATCH",
  );

  const listed = await s3.send(
    new ListObjectsV2Command({
      Bucket: writable,
      Prefix: "khatu-shyam/",
      MaxKeys: 5,
    }),
  );
  console.log(
    "ListObjectsV2 khatu-shyam/ OK, count=",
    (listed.Contents || []).length,
  );

  await s3.send(new DeleteObjectCommand({ Bucket: writable, Key: key }));
  console.log("DeleteObject OK (test file removed)");

  console.log("\n=== SUMMARY ===");
  console.log(
    JSON.stringify(
      {
        credentialsWork: true,
        workingBucket: writable,
        prefix: "khatu-shyam/",
        putGetDelete: true,
        configIssues: [
          configuredBucket.includes("cloudfront.net")
            ? "S3_MEDIA_BUCKET is set to a CloudFront domain; it must be the S3 bucket name"
            : null,
          !process.env.AWS_ACCESS_KEY_ID
            ? "Use AWS_ACCESS_KEY_ID (SDK standard); AWS_ACCESS_KEY alone is ignored by default SDK chain"
            : null,
          !process.env.AWS_SECRET_ACCESS_KEY
            ? "Use AWS_SECRET_ACCESS_KEY (SDK standard); AWS_SECRET_KEY alone is ignored by default SDK chain"
            : null,
          !process.env.CLOUDFRONT_BASE_URL
            ? "CLOUDFRONT_BASE_URL missing (app env schema requires a full https URL)"
            : null,
          configuredBucket !== writable
            ? `App would use S3_MEDIA_BUCKET="${configuredBucket}" but working bucket is "${writable}"`
            : null,
        ].filter(Boolean),
      },
      null,
      2,
    ),
  );
} catch (error) {
  const err = error as Error;
  console.log("Write test FAILED:", err.name, err.message);
  process.exit(3);
}
