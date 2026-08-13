import type { AuthenticatedUser, SubscriptionStatus } from "../../shared/types.js";

/**
 * Mitro-aligned premium gate:
 * - freeMode → always premium
 * - halted → never premium (payment failed / mandate broken)
 * - inactive / pending (unpaid) → not premium
 * - active → premium while expiresAt is null or in the future
 * - cancelled → keep premium until expiresAt (cancel_at_cycle_end)
 * - authenticated → premium during trial window (post-verify, pre-cycle)
 */
export function computeIsPremium(input: {
  subscriptionStatus: SubscriptionStatus;
  subscriptionExpiresAt?: Date | string | null;
  freeMode?: boolean;
  now?: Date;
}): boolean {
  if (input.freeMode) return true;

  const status = input.subscriptionStatus;
  if (status === "halted" || status === "inactive" || status === "pending") {
    return false;
  }

  const expiresAt = input.subscriptionExpiresAt
    ? new Date(input.subscriptionExpiresAt)
    : null;
  const now = input.now ?? new Date();

  if (status === "cancelled") {
    return Boolean(expiresAt && expiresAt.getTime() > now.getTime());
  }

  // active | authenticated
  if (!expiresAt) return status === "active" || status === "authenticated";
  return expiresAt.getTime() > now.getTime();
}

export function userIsPremium(
  user: Pick<
    AuthenticatedUser,
    "subscriptionStatus" | "subscriptionExpiresAt"
  >,
  freeMode = false,
): boolean {
  return computeIsPremium({
    subscriptionStatus: user.subscriptionStatus,
    subscriptionExpiresAt: user.subscriptionExpiresAt,
    freeMode,
  });
}

export function periodDaysForPlan(plan?: string | null): number {
  return plan === "weekly" ? 7 : 30;
}

export function unixToDate(unix?: number | null): Date | null {
  if (unix == null || !Number.isFinite(unix) || unix <= 0) return null;
  return new Date(unix * 1000);
}
