import { Router } from "express";
import { entitlementFromUser } from "../../shared/ports.js";
export function createEntitlementRouter(authenticate, planId) {
    const router = Router();
    router.get("/", authenticate, (req, res) => {
        res.json(entitlementFromUser(req.user, planId));
    });
    return router;
}
