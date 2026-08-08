import { useCallback, useEffect, useState, type FormEvent } from "react";
import { useAuth } from "../auth";
import { fetchUsers, updateUser } from "../lib/api";
import type { ManagedUser, SubscriptionStatus, UserRole } from "../types";

export function UsersPage() {
  const { token, user: me } = useAuth();
  const [items, setItems] = useState<ManagedUser[]>([]);
  const [q, setQ] = useState("");
  const [role, setRole] = useState("");
  const [subscriptionStatus, setSubscriptionStatus] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!token) return;
    setError(null);
    try {
      const result = await fetchUsers(token, {
        q: q || undefined,
        role: role || undefined,
        subscriptionStatus: subscriptionStatus || undefined,
      });
      setItems(result.items);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load users");
    }
  }, [token, q, role, subscriptionStatus]);

  useEffect(() => {
    void load();
  }, [load]);

  async function onSearch(event: FormEvent) {
    event.preventDefault();
    await load();
  }

  async function patchUser(
    id: string,
    patch: { role?: UserRole; subscriptionStatus?: SubscriptionStatus },
  ) {
    if (!token) return;
    setBusyId(id);
    setError(null);
    try {
      const { user } = await updateUser(token, id, patch);
      setItems((current) =>
        current.map((item) => (item.id === id ? { ...item, ...user } : item)),
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "Update failed");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Users</h1>
          <p>Search devotees, grant admin access, and adjust subscriptions.</p>
        </div>
      </div>

      <div className="panel">
        <form className="toolbar" onSubmit={onSearch}>
          <input
            value={q}
            onChange={(event) => setQ(event.target.value)}
            placeholder="Search email or name"
          />
          <select value={role} onChange={(event) => setRole(event.target.value)}>
            <option value="">All roles</option>
            <option value="user">User</option>
            <option value="admin">Admin</option>
          </select>
          <select
            value={subscriptionStatus}
            onChange={(event) => setSubscriptionStatus(event.target.value)}
          >
            <option value="">All subscriptions</option>
            <option value="inactive">Inactive</option>
            <option value="pending">Pending</option>
            <option value="active">Active</option>
            <option value="halted">Halted</option>
            <option value="cancelled">Cancelled</option>
          </select>
          <button className="btn" type="submit">
            Search
          </button>
        </form>

        {error && <div className="error">{error}</div>}

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>User</th>
                <th>Role</th>
                <th>Subscription</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {items.map((user) => (
                <tr key={user.id}>
                  <td>
                    <strong>{user.displayName || "Unnamed"}</strong>
                    <div className="muted">{user.email}</div>
                  </td>
                  <td>
                    <span className="badge">{user.role}</span>
                  </td>
                  <td>
                    <span
                      className={`badge ${
                        user.subscriptionStatus === "active"
                          ? "success"
                          : user.subscriptionStatus === "pending"
                            ? "warning"
                            : ""
                      }`}
                    >
                      {user.subscriptionStatus}
                    </span>
                  </td>
                  <td>
                    <div className="row-actions">
                      {user.subscriptionStatus !== "active" ? (
                        <button
                          className="btn secondary"
                          disabled={busyId === user.id}
                          onClick={() =>
                            void patchUser(user.id, {
                              subscriptionStatus: "active",
                            })
                          }
                        >
                          Grant premium
                        </button>
                      ) : (
                        <button
                          className="btn secondary"
                          disabled={busyId === user.id}
                          onClick={() =>
                            void patchUser(user.id, {
                              subscriptionStatus: "cancelled",
                            })
                          }
                        >
                          Revoke premium
                        </button>
                      )}
                      {user.role !== "admin" ? (
                        <button
                          className="btn"
                          disabled={busyId === user.id}
                          onClick={() =>
                            void patchUser(user.id, { role: "admin" })
                          }
                        >
                          Make admin
                        </button>
                      ) : (
                        <button
                          className="btn danger"
                          disabled={
                            busyId === user.id || user.id === me?.id
                          }
                          onClick={() =>
                            void patchUser(user.id, { role: "user" })
                          }
                        >
                          Remove admin
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
              {items.length === 0 && (
                <tr>
                  <td colSpan={4}>
                    <div className="empty">No users match these filters.</div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
