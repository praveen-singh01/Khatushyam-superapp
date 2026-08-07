import { Router, type RequestHandler } from "express";
import { z } from "zod";
import { Chamatkar } from "./chamatkar.model.js";

const createSchema = z.object({
  title: z.string().trim().min(3).max(120),
  story: z.string().trim().min(20).max(4000),
  language: z.enum(["hi", "en"]).default("hi"),
});

export function createChamatkarRouter(authenticate: RequestHandler): Router {
  const router = Router();

  router.get("/", async (req, res, next) => {
    try {
      const cursor = req.query.cursor?.toString();
      const query = {
        status: "published",
        ...(cursor ? { _id: { $lt: cursor } } : {}),
      };
      const items = await Chamatkar.find(query)
        .sort({ _id: -1 })
        .limit(20)
        .lean();
      res.json({
        items,
        nextCursor: items.at(-1)?._id.toString() ?? null,
      });
    } catch (error) {
      next(error);
    }
  });

  router.post("/", authenticate, async (req, res, next) => {
    try {
      const input = createSchema.parse(req.body);
      const item = await Chamatkar.create({
        ...input,
        authorId: req.user!.id,
        authorName: req.user!.displayName ?? "Shyam Premi",
      });
      res.status(201).json({ item });
    } catch (error) {
      next(error);
    }
  });

  return router;
}
