import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(4000),
  MONGODB_URI: z.string().min(1),
  APP_ORIGIN: z.string().default("*"),
  FIREBASE_PROJECT_ID: z.string().min(1),
  RAZORPAY_KEY_ID: z.string().min(1),
  RAZORPAY_KEY_SECRET: z.string().min(1),
  RAZORPAY_PLAN_ID: z.string().min(1),
  RAZORPAY_WEBHOOK_SECRET: z.string().min(1),
  AWS_REGION: z.string().default("ap-south-1"),
  S3_MEDIA_BUCKET: z.string().min(1),
  CLOUDFRONT_BASE_URL: z.string().url(),
});

export type AppEnv = z.infer<typeof envSchema>;

export function readEnv(source: NodeJS.ProcessEnv = process.env): AppEnv {
  return envSchema.parse(source);
}
