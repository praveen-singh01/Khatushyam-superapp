import { Schema, model } from "mongoose";
const policySchema = new Schema({
    title: { type: String, required: true },
    body: { type: String, required: true },
    updatedAt: { type: Date, default: Date.now },
}, { _id: false });
const appSettingSchema = new Schema({
    key: { type: String, required: true, unique: true, index: true },
    privacyPolicy: { type: policySchema, required: true },
    deleteAccountPolicy: { type: policySchema, required: true },
    cancellationRefundPolicy: { type: policySchema, required: true },
}, { timestamps: true });
export const AppSetting = model("AppSetting", appSettingSchema);
export const LEGAL_SETTINGS_KEY = "legal_policies";
export const defaultLegalPolicies = {
    privacyPolicy: {
        title: "Privacy Policy",
        body: `We collect your name, email, and profile photo to provide sign-in and personalization.

Subscription and payment details are processed by Razorpay. We do not store your full card or UPI secrets.

You can request account deletion from the Profile screen. Contact support for data questions.`,
    },
    deleteAccountPolicy: {
        title: "Delete Account Policy",
        body: `You may request deletion of your account at any time from Profile → Delete account.

After confirmation, your profile data and community posts tied to your account will be removed or anonymized within 30 days, except records we must keep for legal or payment compliance.

Active subscriptions should be cancelled before deletion to avoid further charges.`,
    },
    cancellationRefundPolicy: {
        title: "Cancellation & Refund Policy",
        body: `You can cancel auto-renewal anytime. Access continues until the end of the paid period.

The ₹3 mandate setup fee is non-refundable once the payment mandate is created.

Plan charges (₹49 weekly / ₹199 monthly) follow Razorpay settlement rules. Refund requests for unused paid periods can be reviewed within 7 days of charge by contacting support.`,
    },
};
