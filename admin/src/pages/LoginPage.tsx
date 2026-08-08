import { useState, type FormEvent } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../auth";
import { getApiBase } from "../lib/api";

export function LoginPage() {
  const { user, loading, error, signInWithEmailPassword } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
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
      await signInWithEmailPassword(email, password);
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
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder="you@example.com"
            autoComplete="username"
            required
          />
        </div>

        <div className="field">
          <label htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            placeholder="••••••••"
            autoComplete="current-password"
            required
          />
        </div>

        <p className="muted">
          Sign in with a Firebase email/password account listed in backend{" "}
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
