import { Router, type RequestHandler } from "express";
import { entitlementFromUser } from "../../shared/ports.js";

export function createEntitlementRouter(
  authenticate: RequestHandler,
  planId: string,
): Router {
  const router = Router();

  router.get("/", authenticate, (req, res) => {
    res.json(entitlementFromUser(req.user!, planId));
  });

  return router;
}
