import { createHmac } from "node:crypto";
import mongoose from "mongoose";

const base = process.env.BASE_URL ?? "http://127.0.0.1:4000";

async function main() {
  await mongoose.connect("mongodb://127.0.0.1:27017/khatu_shyam_local");
  const users = mongoose.connection.collection("users");
  await users.updateOne(
    { firebaseUid: "local-premium" },
    {
      $set: {
        email: "premium@local.test",
        displayName: "Local Premium",
        subscriptionStatus: "active",
        razorpaySubscriptionId: "sub_live_premium",
        fcmTokens: [],
      },
    },
    { upsert: true },
  );
  const free = await users.findOne({ firebaseUid: "local-free" });
  const subId = String(free?.razorpaySubscriptionId ?? "sub_local_missing");
  await mongoose.disconnect();

  const headers = (token: string) => ({
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  });

  const entitlement = await fetch(`${base}/v1/entitlement`, {
    headers: headers("premium"),
  });
  console.log("premium entitlement", entitlement.status, await entitlement.json());

  const manifest = await fetch(`${base}/v1/content/premium-manifest`, {
    headers: headers("premium"),
  });
  console.log("premium manifest", manifest.status, await manifest.json());

  const upload = await fetch(`${base}/v1/uploads/presign`, {
    method: "POST",
    headers: headers("premium"),
    body: JSON.stringify({
      contentType: "image/jpeg",
      purpose: "poster_photo",
    }),
  });
  console.log("upload presign", upload.status, await upload.json());

  const body = JSON.stringify({
    event: "subscription.activated",
    payload: { subscription: { entity: { id: subId, status: "active" } } },
  });
  const signature = createHmac("sha256", "local_webhook_secret")
    .update(body)
    .digest("hex");
  const webhook = await fetch(`${base}/v1/subscriptions/webhook`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-razorpay-signature": signature,
      "x-razorpay-event-id": `evt_live_${Date.now()}`,
    },
    body,
  });
  console.log("webhook", webhook.status, await webhook.json());

  const freeAfter = await fetch(`${base}/v1/entitlement`, {
    headers: headers("free"),
  });
  console.log("free after webhook", freeAfter.status, await freeAfter.json());
}

await main();
