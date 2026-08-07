import { applicationDefault, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import type {
  IdentityVerifier,
  VerifiedIdentity,
} from "../../shared/types.js";

export function createFirebaseIdentityVerifier(
  projectId: string,
): IdentityVerifier {
  const app =
    getApps()[0] ??
    initializeApp({
      credential: applicationDefault(),
      projectId,
    });

  return {
    async verify(token: string): Promise<VerifiedIdentity> {
      const decoded = await getAuth(app).verifyIdToken(token);
      return {
        uid: decoded.uid,
        email: decoded.email,
        name: decoded.name,
        picture: decoded.picture,
        signInProvider: decoded.firebase.sign_in_provider,
      };
    },
  };
}
