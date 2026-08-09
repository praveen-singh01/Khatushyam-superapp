import { Router, type RequestHandler } from "express";
import { z } from "zod";
import {
  AppSetting,
  LEGAL_SETTINGS_KEY,
  defaultLegalPolicies,
} from "./app-setting.model.js";

const policySchema = z.object({
  title: z.string().min(1).max(200),
  body: z.string().min(1).max(50000),
});

const updateSchema = z.object({
  privacyPolicy: policySchema.optional(),
  deleteAccountPolicy: policySchema.optional(),
  cancellationRefundPolicy: policySchema.optional(),
});

async function loadPolicies() {
  let doc = await AppSetting.findOne({ key: LEGAL_SETTINGS_KEY }).lean();
  if (!doc) {
    doc = (
      await AppSetting.create({
        key: LEGAL_SETTINGS_KEY,
        ...defaultLegalPolicies,
      })
    ).toObject();
  }
  return {
    privacyPolicy: doc.privacyPolicy,
    deleteAccountPolicy: doc.deleteAccountPolicy,
    cancellationRefundPolicy: doc.cancellationRefundPolicy,
    updatedAt: doc.updatedAt ?? null,
  };
}

export function createLegalRouter(options: {
  authenticate: RequestHandler;
  requireAdmin: RequestHandler;
}): Router {
  const router = Router();

  router.get("/policies", async (_req, res, next) => {
    try {
      res.json(await loadPolicies());
    } catch (error) {
      next(error);
    }
  });

  router.put(
    "/policies",
    options.authenticate,
    options.requireAdmin,
    async (req, res, next) => {
      try {
        const input = updateSchema.parse(req.body ?? {});
        const current = await loadPolicies();
        const nextDoc = await AppSetting.findOneAndUpdate(
          { key: LEGAL_SETTINGS_KEY },
          {
            $set: {
              privacyPolicy: input.privacyPolicy ?? current.privacyPolicy,
              deleteAccountPolicy:
                input.deleteAccountPolicy ?? current.deleteAccountPolicy,
              cancellationRefundPolicy:
                input.cancellationRefundPolicy ??
                current.cancellationRefundPolicy,
            },
          },
          { upsert: true, new: true },
        ).lean();
        res.json({
          privacyPolicy: nextDoc!.privacyPolicy,
          deleteAccountPolicy: nextDoc!.deleteAccountPolicy,
          cancellationRefundPolicy: nextDoc!.cancellationRefundPolicy,
          updatedAt: nextDoc!.updatedAt ?? null,
        });
      } catch (error) {
        next(error);
      }
    },
  );

  return router;
}
