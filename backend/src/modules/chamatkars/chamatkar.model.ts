import { Schema, model, type Types } from "mongoose";

export interface ChamatkarDocument {
  authorId: Types.ObjectId;
  authorName: string;
  title: string;
  story: string;
  language: "hi" | "en";
  status: "published" | "hidden";
  likeCount: number;
  likedBy: Types.ObjectId[];
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
    likeCount: { type: Number, default: 0, min: 0 },
    likedBy: {
      type: [{ type: Schema.Types.ObjectId, ref: "User" }],
      default: [],
    },
  },
  { timestamps: true },
);

chamatkarSchema.index({ status: 1, createdAt: -1 });

export const Chamatkar = model<ChamatkarDocument>(
  "Chamatkar",
  chamatkarSchema,
);
