import { Router, type RequestHandler } from "express";
import { entitlementFromUser } from "../../shared/ports.js";

export function createEntitlementRouter(
  authenticate: RequestHandler,
  planId: string,
  options: { freeMode?: boolean; trialAmountInr?: number } = {},
): Router {
  const router = Router();

  router.get("/", authenticate, (req, res) => {
    res.json(
      entitlementFromUser(req.user!, planId, {
        freeMode: options.freeMode,
        trialAmountInr: options.trialAmountInr,
      }),
    );
  });

  return router;
}
