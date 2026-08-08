import { useState, type FormEvent } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../auth";
import { getApiBase } from "../lib/api";

export function LoginPage() {
  const { user, loading, error, signInWithToken } = useAuth();
  const [token, setToken] = useState("admin");
  const [submitting, setSubmitting] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  if (!loading && user) {
    return <Navigate to="/" replace />;
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setLocalError(null);
    try {
      await signInWithToken(token);
    } catch (err) {
      setLocalError(
        err instanceof Error ? err.message : "Unable to sign in as admin",
      );
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="login-page">
      <form className="login-card" onSubmit={onSubmit}>
        <div>
          <h1>Khatu Shyam Admin</h1>
          <p>
            Manage wallpapers, ringtones, and devotee accounts for the super app.
          </p>
        </div>

        <div className="field">
          <label htmlFor="token">API bearer token</label>
          <input
            id="token"
            value={token}
            onChange={(event) => setToken(event.target.value)}
            placeholder="admin"
            autoComplete="off"
            required
          />
        </div>

        <p className="muted">
          Local API: use <code>admin</code> with <code>npm run local</code>.
          Production: paste a Firebase ID token for an email listed in{" "}
          <code>ADMIN_EMAILS</code>.
        </p>
        <p className="muted">API: {getApiBase()}</p>

        {(localError || error) && (
          <div className="error">{localError || error}</div>
        )}

        <button className="btn" type="submit" disabled={submitting || loading}>
          {submitting || loading ? "Signing in…" : "Enter dashboard"}
        </button>
      </form>
    </div>
  );
}
