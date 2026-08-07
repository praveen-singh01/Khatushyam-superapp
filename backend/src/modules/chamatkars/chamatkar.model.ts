import { Schema, model } from "mongoose";

export interface ChamatkarDocument {
  authorId: Schema.Types.ObjectId;
  authorName: string;
  title: string;
  story: string;
  language: "hi" | "en";
  status: "published" | "hidden";
}

const chamatkarSchema = new Schema<ChamatkarDocument>(
  {
    authorId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    authorName: { type: String, required: true, trim: true },
    title: { type: String, required: true, trim: true, maxlength: 120 },
    story: { type: String, required: true, trim: true, maxlength: 4000 },
    language: { type: String, enum: ["hi", "en"], default: "hi" },
    status: {
      type: String,
      enum: ["published", "hidden"],
      default: "published",
      index: true,
    },
  },
  { timestamps: true },
);

chamatkarSchema.index({ status: 1, createdAt: -1 });

export const Chamatkar = model<ChamatkarDocument>(
  "Chamatkar",
  chamatkarSchema,
);
