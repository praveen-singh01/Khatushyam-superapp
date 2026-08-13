import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "../auth";

export function AppLayout() {
  const { user, signOut } = useAuth();

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <strong>Khatu Shyam</strong>
          <span>Admin console</span>
        </div>
        <nav className="nav">
          <NavLink to="/" end>
            Dashboard
          </NavLink>
          <NavLink to="/story">Story</NavLink>
          <NavLink to="/travel-guides">Travel</NavLink>
          <NavLink to="/content">Content</NavLink>
          <NavLink to="/users">Users</NavLink>
        </nav>
        <div className="sidebar-footer">
          <div>
            <strong>{user?.displayName || "Admin"}</strong>
            <div className="muted" style={{ color: "rgba(248,235,226,0.68)" }}>
              {user?.email}
            </div>
          </div>
          <button
            className="btn ghost"
            type="button"
            onClick={() => {
              void signOut();
            }}
          >
            Sign out
          </button>
        </div>
      </aside>
      <main className="main">
        <Outlet />
      </main>
    </div>
  );
}
