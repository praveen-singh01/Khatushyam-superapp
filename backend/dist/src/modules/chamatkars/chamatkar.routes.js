import { Router } from "express";
import mongoose from "mongoose";
import { z } from "zod";
import { Chamatkar } from "./chamatkar.model.js";
const createSchema = z.object({
    title: z.string().trim().min(3).max(120),
    story: z.string().trim().min(20).max(4000),
    language: z.enum(["hi", "en"]).default("hi"),
});
function serialize(item, viewerId) {
    const likedBy = item.likedBy ?? [];
    const likeCount = item.likeCount ?? likedBy.length;
    return {
        id: item._id.toString(),
        authorId: item.authorId.toString(),
        authorName: item.authorName,
        title: item.title,
        story: item.story,
        language: item.language,
        likeCount,
        likedByMe: viewerId
            ? likedBy.some((id) => id.toString() === viewerId)
            : false,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
    };
}
export function createChamatkarRouter(authenticate, optionalAuthenticate) {
    const router = Router();
    router.get("/", optionalAuthenticate, async (req, res, next) => {
        try {
            const cursor = req.query.cursor?.toString();
            if (cursor && !mongoose.isValidObjectId(cursor)) {
                res.status(400).json({ error: "INVALID_CURSOR" });
                return;
            }
            const query = {
                status: "published",
                ...(cursor ? { _id: { $lt: cursor } } : {}),
            };
            const items = await Chamatkar.find(query)
                .sort({ _id: -1 })
                .limit(20)
                .lean();
            const viewerId = req.user?.id;
            res.json({
                items: items.map((item) => serialize(item, viewerId)),
                nextCursor: items.at(-1)?._id.toString() ?? null,
            });
        }
        catch (error) {
            next(error);
        }
    });
    router.post("/", authenticate, async (req, res, next) => {
        try {
            const input = createSchema.parse(req.body);
            const item = await Chamatkar.create({
                ...input,
                authorId: req.user.id,
                authorName: req.user.displayName ?? "Shyam Premi",
            });
            res.status(201).json({
                item: serialize(item.toObject(), req.user.id),
            });
        }
        catch (error) {
            next(error);
        }
    });
    router.post("/:id/like", authenticate, async (req, res, next) => {
        try {
            const { id } = req.params;
            if (!mongoose.isValidObjectId(id)) {
                res.status(400).json({ error: "INVALID_ID" });
                return;
            }
            const userId = new mongoose.Types.ObjectId(req.user.id);
            const existing = await Chamatkar.findOne({
                _id: id,
                status: "published",
            }).lean();
            if (!existing) {
                res.status(404).json({ error: "NOT_FOUND" });
                return;
            }
            const alreadyLiked = (existing.likedBy ?? []).some((likedId) => likedId.toString() === req.user.id);
            const updated = alreadyLiked
                ? await Chamatkar.findByIdAndUpdate(id, {
                    $pull: { likedBy: userId },
                    $inc: { likeCount: -1 },
                }, { new: true }).lean()
                : await Chamatkar.findByIdAndUpdate(id, {
                    $addToSet: { likedBy: userId },
                    $inc: { likeCount: 1 },
                }, { new: true }).lean();
            if (!updated) {
                res.status(404).json({ error: "NOT_FOUND" });
                return;
            }
            // Guard against negative counts from legacy docs.
            if ((updated.likeCount ?? 0) < 0) {
                await Chamatkar.updateOne({ _id: id }, { $set: { likeCount: 0 } });
                updated.likeCount = 0;
            }
            res.json({ item: serialize(updated, req.user.id) });
        }
        catch (error) {
            next(error);
        }
    });
    return router;
}
