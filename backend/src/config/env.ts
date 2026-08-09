import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(4000),
  MONGODB_URI: z.string().min(1),
  APP_ORIGIN: z.string().default("*"),
  FIREBASE_PROJECT_ID: z.string().min(1),
  RAZORPAY_KEY_ID: z.string().min(1),
  RAZORPAY_KEY_SECRET: z.string().min(1),
  /** Monthly plan (₹199) — also used after ₹3 intro trial. */
  RAZORPAY_PLAN_ID: z.string().min(1),
  /** Weekly plan (₹49) for returning users. */
  RAZORPAY_PLAN_ID_WEEKLY: z.string().min(1).optional(),
  RAZORPAY_WEBHOOK_SECRET: z.string().min(1),
  AWS_REGION: z.string().default("ap-south-1"),
  S3_MEDIA_BUCKET: z.string().min(1),
  CLOUDFRONT_BASE_URL: z.string().url(),
  /**
   * Absolute path to `khatu-shyam-content` for local static serving.
   * When set, media URLs are built from the request Host (phone-friendly).
   */
  MEDIA_LOCAL_ROOT: z.string().optional(),
  /** Comma-separated emails granted admin on first authenticated request. */
  ADMIN_EMAILS: z.string().default(""),
  /**
   * When true, all signed-in users get premium access (no paywall).
   * Flip to false before enabling Razorpay billing.
   */
  APP_FREE_MODE: z
    .enum(["true", "false"])
    .default("true")
    .transform((value) => value === "true"),
});

export type AppEnv = z.infer<typeof envSchema>;

export function readEnv(source: NodeJS.ProcessEnv = process.env): AppEnv {
  return envSchema.parse(source);
}
