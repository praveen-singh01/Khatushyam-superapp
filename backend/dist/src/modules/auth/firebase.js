import { applicationDefault, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
export function createFirebaseIdentityVerifier(projectId) {
    const app = getApps()[0] ??
        initializeApp({
            credential: applicationDefault(),
            projectId,
        });
    return {
        async verify(token) {
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
