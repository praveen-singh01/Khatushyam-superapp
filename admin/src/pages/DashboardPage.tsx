import { useCallback, useEffect, useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../auth";
import {
  createCategory,
  deleteCategory,
  fetchCategories,
  fetchLive,
  fetchStats,
  updateLive,
} from "../lib/api";
import type { AdminStats, ContentCategory, ContentType } from "../types";

function slugify(value: string) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 64);
}

export function DashboardPage() {
  const { token } = useAuth();
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [categories, setCategories] = useState<ContentCategory[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [savingLive, setSavingLive] = useState(false);

  const [type, setType] = useState<ContentType>("wallpaper");
  const [labelEn, setLabelEn] = useState("");
  const [labelHi, setLabelHi] = useState("");
  const [slug, setSlug] = useState("");

  const [isLive, setIsLive] = useState(false);
  const [youtubeUrl, setYoutubeUrl] = useState("");
  const [liveTitleEn, setLiveTitleEn] = useState("Khatu Shyam Live Darshan");
  const [liveTitleHi, setLiveTitleHi] = useState("खाटू श्याम लाइव दर्शन");
  const [liveEmbedUrl, setLiveEmbedUrl] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!token) return;
    setError(null);
    try {
      const [nextStats, nextCategories, live] = await Promise.all([
        fetchStats(token),
        fetchCategories(token),
        fetchLive(token),
      ]);
      setStats(nextStats);
      setCategories(nextCategories.items);
      setIsLive(live.live.isLive);
      setYoutubeUrl(
        live.live.youtubeVideoId
          ? `https://www.youtube.com/watch?v=${live.live.youtubeVideoId}`
          : "",
      );
      setLiveTitleEn(live.live.title.en);
      setLiveTitleHi(live.live.title.hi);
      setLiveEmbedUrl(live.live.embedUrl);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load dashboard");
    }
  }, [token]);

  useEffect(() => {
    void load();
  }, [load]);

  async function onSaveLive(event: FormEvent) {
    event.preventDefault();
    if (!token) return;

    if (isLive && !youtubeUrl.trim()) {
      setError("Add a YouTube URL before going live");
      return;
    }

    setSavingLive(true);
    setError(null);
    setMessage(null);
    try {
      const { live } = await updateLive(token, {
        isLive,
        youtubeVideoId: youtubeUrl.trim() || null,
        title: { en: liveTitleEn, hi: liveTitleHi },
      });
      setIsLive(live.isLive);
      setYoutubeUrl(
        live.youtubeVideoId
          ? `https://www.youtube.com/watch?v=${live.youtubeVideoId}`
          : "",
      );
      setLiveEmbedUrl(live.embedUrl);
      setMessage(
        live.isLive
          ? "Live Darshan is ON for the app"
          : "Live Darshan is OFF",
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update live");
    } finally {
      setSavingLive(false);
    }
  }

  async function onAddCategory(event: FormEvent) {
    event.preventDefault();
    if (!token) return;

    const finalSlug = slug || slugify(labelEn);
    if (!finalSlug) {
      setError("Enter a category name or slug");
      return;
    }

    setSaving(true);
    setError(null);
    setMessage(null);
    try {
      await createCategory(token, {
        type,
        slug: finalSlug,
        label: {
          en: labelEn || finalSlug,
          hi: labelHi || labelEn || finalSlug,
        },
      });
      setLabelEn("");
      setLabelHi("");
      setSlug("");
      setMessage(`Added ${type} category “${finalSlug}”`);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to add category");
    } finally {
      setSaving(false);
    }
  }

  async function onDeleteCategory(category: ContentCategory) {
    if (!token) return;
    setError(null);
    setMessage(null);
    try {
      await deleteCategory(token, category.id);
      setMessage(`Removed category “${category.slug}”`);
      await load();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to remove category",
      );
    }
  }

  const wallpaperCategories = categories.filter(
    (item) => item.type === "wallpaper",
  );
  const ringtoneCategories = categories.filter(
    (item) => item.type === "ringtone",
  );

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Dashboard</h1>
          <p>Upload library content and manage devotee accounts.</p>
        </div>
        <div className="row-actions">
          <Link className="btn secondary" to="/content">
            Upload content
          </Link>
          <Link className="btn" to="/users">
            Manage users
          </Link>
        </div>
      </div>

      <div className="panel stack" style={{ marginBottom: 18 }}>
        {error && <div className="error">{error}</div>}
        {message && <div className="badge success">{message}</div>}
        {!stats && !error && <div className="muted">Loading stats…</div>}
        {stats && (
          <div className="stats-grid">
            <div className="stat">
              <label>Total users</label>
              <strong>{stats.users.total}</strong>
            </div>
            <div className="stat">
              <label>Premium users</label>
              <strong>{stats.users.premium}</strong>
            </div>
            <div className="stat">
              <label>Wallpapers</label>
              <strong>{stats.content.wallpapers}</strong>
            </div>
            <div className="stat">
              <label>Ringtones</label>
              <strong>{stats.content.ringtones}</strong>
            </div>
          </div>
        )}
      </div>

      <form
        className="panel stack"
        style={{ marginBottom: 18 }}
        onSubmit={onSaveLive}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            gap: 12,
            alignItems: "center",
            flexWrap: "wrap",
          }}
        >
          <div>
            <h2 style={{ margin: 0, fontFamily: "var(--font-display)" }}>
              Live Darshan
            </h2>
            <p className="muted" style={{ margin: "6px 0 0" }}>
              Paste a YouTube URL and turn live on so the app shows the stream.
            </p>
          </div>
          <span className={`badge ${isLive ? "success" : "warning"}`}>
            {isLive ? "LIVE" : "OFFLINE"}
          </span>
        </div>

        <div className="field">
          <label htmlFor="youtube-url">YouTube URL or video ID</label>
          <input
            id="youtube-url"
            value={youtubeUrl}
            onChange={(event) => setYoutubeUrl(event.target.value)}
            placeholder="https://www.youtube.com/watch?v=…"
          />
        </div>

        <div className="field">
          <label htmlFor="live-title-en">Title (English)</label>
          <input
            id="live-title-en"
            value={liveTitleEn}
            onChange={(event) => setLiveTitleEn(event.target.value)}
            required
          />
        </div>

        <div className="field">
          <label htmlFor="live-title-hi">Title (Hindi)</label>
          <input
            id="live-title-hi"
            value={liveTitleHi}
            onChange={(event) => setLiveTitleHi(event.target.value)}
            required
          />
        </div>

        <label
          className="field"
          style={{
            gridTemplateColumns: "auto 1fr",
            alignItems: "center",
            cursor: "pointer",
          }}
        >
          <input
            type="checkbox"
            checked={isLive}
            onChange={(event) => setIsLive(event.target.checked)}
          />
          <span>
            <strong>Go live</strong>
            <div className="muted">
              When checked, the app shows this YouTube stream as Live Darshan.
            </div>
          </span>
        </label>

        {liveEmbedUrl && (
          <p className="muted" style={{ margin: 0 }}>
            Embed: {liveEmbedUrl}
          </p>
        )}

        <div className="row-actions">
          <button className="btn" type="submit" disabled={savingLive}>
            {savingLive ? "Saving…" : "Save live settings"}
          </button>
          {isLive && (
            <button
              className="btn danger"
              type="button"
              disabled={savingLive}
              onClick={() => {
                setIsLive(false);
              }}
            >
              Mark offline
            </button>
          )}
        </div>
      </form>

      <div className="upload-grid">
        <form className="panel stack" onSubmit={onAddCategory}>
          <h2 style={{ margin: 0, fontFamily: "var(--font-display)" }}>
            Add category
          </h2>
          <p className="muted" style={{ margin: 0 }}>
            Create more wallpaper or ringtone folders for the content library.
          </p>

          <div className="field">
            <label>Type</label>
            <select
              value={type}
              onChange={(event) => setType(event.target.value as ContentType)}
            >
              <option value="wallpaper">Wallpaper</option>
              <option value="ringtone">Ringtone</option>
            </select>
          </div>

          <div className="field">
            <label>Name (English)</label>
            <input
              value={labelEn}
              onChange={(event) => {
                setLabelEn(event.target.value);
                if (!slug) setSlug(slugify(event.target.value));
              }}
              placeholder="Temple night"
              required
            />
          </div>

          <div className="field">
            <label>Name (Hindi)</label>
            <input
              value={labelHi}
              onChange={(event) => setLabelHi(event.target.value)}
              placeholder="Optional"
            />
          </div>

          <div className="field">
            <label>Slug</label>
            <input
              value={slug}
              onChange={(event) => setSlug(slugify(event.target.value))}
              placeholder="temple-night"
              required
            />
          </div>

          <button className="btn" type="submit" disabled={saving}>
            {saving ? "Saving…" : "Add category"}
          </button>
        </form>

        <div className="panel stack">
          <h2 style={{ margin: 0, fontFamily: "var(--font-display)" }}>
            Categories
          </h2>

          <div>
            <strong>Wallpapers</strong>
            <div className="table-wrap" style={{ marginTop: 10 }}>
              <table>
                <thead>
                  <tr>
                    <th>Category</th>
                    <th>Slug</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {wallpaperCategories.map((category) => (
                    <tr key={category.id}>
                      <td>
                        <strong>{category.label.en}</strong>
                        <div className="muted">{category.label.hi}</div>
                      </td>
                      <td>
                        <span className="badge">{category.slug}</span>
                      </td>
                      <td>
                        <button
                          className="btn danger"
                          type="button"
                          onClick={() => void onDeleteCategory(category)}
                        >
                          Remove
                        </button>
                      </td>
                    </tr>
                  ))}
                  {wallpaperCategories.length === 0 && (
                    <tr>
                      <td colSpan={3}>
                        <div className="empty">No wallpaper categories yet.</div>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>

          <div>
            <strong>Ringtones</strong>
            <div className="table-wrap" style={{ marginTop: 10 }}>
              <table>
                <thead>
                  <tr>
                    <th>Category</th>
                    <th>Slug</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {ringtoneCategories.map((category) => (
                    <tr key={category.id}>
                      <td>
                        <strong>{category.label.en}</strong>
                        <div className="muted">{category.label.hi}</div>
                      </td>
                      <td>
                        <span className="badge">{category.slug}</span>
                      </td>
                      <td>
                        <button
                          className="btn danger"
                          type="button"
                          onClick={() => void onDeleteCategory(category)}
                        >
                          Remove
                        </button>
                      </td>
                    </tr>
                  ))}
                  {ringtoneCategories.length === 0 && (
                    <tr>
                      <td colSpan={3}>
                        <div className="empty">No ringtone categories yet.</div>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
