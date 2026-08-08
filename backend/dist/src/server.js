import "dotenv/config";
import mongoose from "mongoose";
import { createApp } from "./app.js";
import { readEnv } from "./config/env.js";
import { createFirebaseIdentityVerifier } from "./modules/auth/firebase.js";
import { createRazorpayGateway } from "./modules/subscriptions/razorpay.gateway.js";
import { createS3UploadPresigner } from "./modules/uploads/s3.presigner.js";
const env = readEnv();
await mongoose.connect(env.MONGODB_URI);
const app = createApp({
    env,
    identityVerifier: createFirebaseIdentityVerifier(env.FIREBASE_PROJECT_ID),
    subscriptionGateway: createRazorpayGateway({
        keyId: env.RAZORPAY_KEY_ID,
        keySecret: env.RAZORPAY_KEY_SECRET,
    }),
    uploadPresigner: createS3UploadPresigner(env.AWS_REGION),
});
const server = app.listen(env.PORT, () => {
    console.info(`API listening on port ${env.PORT}`);
});
async function shutdown(signal) {
    console.info(`${signal} received; shutting down`);
    server.close(async () => {
        await mongoose.disconnect();
        process.exit(0);
    });
}
process.on("SIGTERM", () => void shutdown("SIGTERM"));
process.on("SIGINT", () => void shutdown("SIGINT"));
