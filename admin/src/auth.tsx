import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { ApiError, fetchMe } from "./lib/api";
import type { AuthUser } from "./types";

const TOKEN_KEY = "khatu_admin_token";

interface AuthContextValue {
  user: AuthUser | null;
  token: string | null;
  loading: boolean;
  error: string | null;
  signInWithToken: (token: string) => Promise<void>;
  signOut: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [token, setToken] = useState<string | null>(
    () => localStorage.getItem(TOKEN_KEY),
  );
  const [loading, setLoading] = useState(Boolean(localStorage.getItem(TOKEN_KEY)));
  const [error, setError] = useState<string | null>(null);

  const hydrate = useCallback(async (nextToken: string) => {
    setLoading(true);
    setError(null);
    try {
      const { user: me } = await fetchMe(nextToken);
      if (me.role !== "admin") {
        throw new Error("ADMIN_REQUIRED");
      }
      localStorage.setItem(TOKEN_KEY, nextToken);
      setToken(nextToken);
      setUser(me);
    } catch (err) {
      localStorage.removeItem(TOKEN_KEY);
      setToken(null);
      setUser(null);
      if (err instanceof ApiError) {
        setError(err.message);
      } else if (err instanceof Error) {
        setError(err.message);
      } else {
        setError("Unable to sign in");
      }
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const saved = localStorage.getItem(TOKEN_KEY);
    if (!saved) {
      setLoading(false);
      return;
    }
    void hydrate(saved).catch(() => undefined);
    // Intentionally run once on mount to restore session.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const signInWithToken = useCallback(
    async (nextToken: string) => {
      await hydrate(nextToken.trim());
    },
    [hydrate],
  );

  const signOut = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY);
    setToken(null);
    setUser(null);
    setError(null);
  }, []);

  const value = useMemo(
    () => ({
      user,
      token,
      loading,
      error,
      signInWithToken,
      signOut,
    }),
    [user, token, loading, error, signInWithToken, signOut],
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
