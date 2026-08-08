import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  type User as FirebaseUser,
} from "firebase/auth";
import { FirebaseError } from "firebase/app";
import { ApiError, fetchMe } from "./lib/api";
import { firebaseAuth } from "./lib/firebase";
import type { AuthUser } from "./types";

function authErrorMessage(err: unknown): string {
  if (err instanceof ApiError) return err.message;
  if (err instanceof FirebaseError) {
    switch (err.code) {
      case "auth/invalid-credential":
      case "auth/wrong-password":
      case "auth/user-not-found":
      case "auth/invalid-email":
        return "Invalid email or password";
      case "auth/too-many-requests":
        return "Too many attempts. Try again later.";
      default:
        return err.message;
    }
  }
  if (err instanceof Error) return err.message;
  return "Unable to sign in";
}

interface AuthContextValue {
  user: AuthUser | null;
  token: string | null;
  loading: boolean;
  error: string | null;
  signInWithEmailPassword: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

async function loadAdminSession(firebaseUser: FirebaseUser) {
  const idToken = await firebaseUser.getIdToken();
  const { user: me } = await fetchMe(idToken);
  if (me.role !== "admin") {
    throw new Error("ADMIN_REQUIRED");
  }
  return { token: idToken, user: me };
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(firebaseAuth, (firebaseUser) => {
      void (async () => {
        if (!firebaseUser) {
          setUser(null);
          setToken(null);
          setLoading(false);
          return;
        }

        setLoading(true);
        setError(null);
        try {
          const session = await loadAdminSession(firebaseUser);
          setToken(session.token);
          setUser(session.user);
        } catch (err) {
          setUser(null);
          setToken(null);
          await firebaseSignOut(firebaseAuth).catch(() => undefined);
          setError(authErrorMessage(err));
        } finally {
          setLoading(false);
        }
      })();
    });

    return unsubscribe;
  }, []);

  const signInWithEmailPassword = useCallback(
    async (email: string, password: string) => {
      setLoading(true);
      setError(null);
      try {
        const credential = await signInWithEmailAndPassword(
          firebaseAuth,
          email.trim(),
          password,
        );
        const session = await loadAdminSession(credential.user);
        setToken(session.token);
        setUser(session.user);
      } catch (err) {
        setUser(null);
        setToken(null);
        setError(authErrorMessage(err));
        throw err;
      } finally {
        setLoading(false);
      }
    },
    [],
  );

  const signOut = useCallback(async () => {
    await firebaseSignOut(firebaseAuth);
    setUser(null);
    setToken(null);
    setError(null);
  }, []);

  const value = useMemo(
    () => ({
      user,
      token,
      loading,
      error,
      signInWithEmailPassword,
      signOut,
    }),
    [user, token, loading, error, signInWithEmailPassword, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("useAuth must be used within AuthProvider");
  }
  return ctx;
}
