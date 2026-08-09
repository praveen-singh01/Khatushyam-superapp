import { useCallback, useEffect, useMemo, useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../auth";
import {
  archiveContent,
  createContent,
  fetchCategories,
  fetchContent,
  updateContent,
  uploadLibraryFile,
} from "../lib/api";
import type { ContentItem, ContentStatus, ContentType } from "../types";

function slugify(value: string) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80);
}

export function ContentPage() {
  const { token } = useAuth();
  const [items, setItems] = useState<ContentItem[]>([]);
  const [categoryOptions, setCategoryOptions] = useState<{
    wallpaper: string[];
    ringtone: string[];
    poster: string[];
  }>({ wallpaper: [], ringtone: [], poster: [] });
  const [q, setQ] = useState("");
  const [typeFilter, setTypeFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState("published");
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);

  const [type, setType] = useState<ContentType>("wallpaper");
  const [category, setCategory] = useState<string>("");
  const [titleEn, setTitleEn] = useState("");
  const [titleHi, setTitleHi] = useState("");
  const [slug, setSlug] = useState("");
  const [status, setStatus] = useState<ContentStatus>("published");
  const [premium, setPremium] = useState(true);
  const [file, setFile] = useState<File | null>(null);

  useEffect(() => {
    // Daily posters are free in the app; keep admin default aligned.
    if (type === "poster") setPremium(false);
  }, [type]);

  const categories = useMemo(() => {
    if (type === "wallpaper") return categoryOptions.wallpaper;
    if (type === "ringtone") return categoryOptions.ringtone;
    return categoryOptions.poster;
  }, [type, categoryOptions]);

  useEffect(() => {
    if (!categories.includes(category)) {
      setCategory(categories[0] ?? "");
    }
  }, [categories, category]);

  const load = useCallback(async () => {
    if (!token) return;
    setError(null);
    try {
      const [result, cats] = await Promise.all([
        fetchContent(token, {
          q: q || undefined,
          type: typeFilter || undefined,
          status: statusFilter || undefined,
        }),
        fetchCategories(token),
      ]);
      setItems(result.items);
      setCategoryOptions(cats.byType);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load content");
    }
  }, [token, q, typeFilter, statusFilter]);

  useEffect(() => {
    void load();
  }, [load]);

  async function onFilter(event: FormEvent) {
    event.preventDefault();
    await load();
  }

  async function onUpload(event: FormEvent) {
    event.preventDefault();
    if (!token || !file) {
      setError("Choose a file to upload");
      return;
    }

    setUploading(true);
    setError(null);
    setMessage(null);

    try {
      const finalSlug = slug || slugify(titleEn) || `asset-${Date.now()}`;
      const uploaded = await uploadLibraryFile(token, file, type, category);
      await createContent(token, {
        slug: finalSlug,
        type,
        category,
        title: { en: titleEn, hi: titleHi || titleEn },
        fileKey: uploaded.key,
        format: uploaded.format,
        premium,
        status,
        source: "admin-upload",
      });
      setMessage(`Uploaded ${finalSlug}`);
      setTitleEn("");
      setTitleHi("");
      setSlug("");
      setFile(null);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Upload failed");
    } finally {
      setUploading(false);
    }
  }

  async function setItemStatus(item: ContentItem, next: ContentStatus) {
    if (!token) return;
    try {
      if (next === "archived") {
        const { item: updated } = await archiveContent(token, item.id);
        setItems((current) =>
          current.map((row) => (row.id === item.id ? updated : row)),
        );
      } else {
        const { item: updated } = await updateContent(token, item.id, {
          status: next,
        });
        setItems((current) =>
          current.map((row) => (row.id === item.id ? updated : row)),
        );
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Status update failed");
    }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Content library</h1>
          <p>
            Upload wallpapers, ringtones, and daily posters to S3 (
            <code>khatu-shyam/</code>) and publish them in Mongo.
          </p>
        </div>
        <Link className="btn secondary" to="/">
          Manage categories
        </Link>
      </div>

      <div className="content-library">
        <form className="panel stack upload-panel" onSubmit={onUpload}>
          <div className="section-heading">
            <h2 style={{ margin: 0, fontFamily: "var(--font-display)" }}>
              Upload asset
            </h2>
            <p className="muted" style={{ margin: 0 }}>
              Choose Poster for daily share images. Wallpaper / ringtone stay
              the same.
            </p>
          </div>

          <div className="form-grid">
            <div className="field">
              <label>Type</label>
              <select
                value={type}
                onChange={(event) => setType(event.target.value as ContentType)}
              >
                <option value="wallpaper">Wallpaper</option>
                <option value="ringtone">Ringtone</option>
                <option value="poster">Poster</option>
              </select>
            </div>

            <div className="field">
              <label>Category</label>
              <select
                value={category}
                onChange={(event) => setCategory(event.target.value)}
                required
                disabled={categories.length === 0}
              >
                {categories.length === 0 ? (
                  <option value="">Add a category on Dashboard first</option>
                ) : (
                  categories.map((value) => (
                    <option key={value} value={value}>
                      {value}
                    </option>
                  ))
                )}
              </select>
            </div>

            <div className="field">
              <label>Title (English)</label>
              <input
                value={titleEn}
                onChange={(event) => {
                  setTitleEn(event.target.value);
                  if (!slug) setSlug(slugify(event.target.value));
                }}
                required
              />
            </div>

            <div className="field">
              <label>Title (Hindi)</label>
              <input
                value={titleHi}
                onChange={(event) => setTitleHi(event.target.value)}
                placeholder="Optional"
              />
            </div>

            <div className="field">
              <label>Slug</label>
              <input
                value={slug}
                onChange={(event) => setSlug(slugify(event.target.value))}
                placeholder="auto-from-title"
                required
              />
            </div>

            <div className="field">
              <label>Status</label>
              <select
                value={status}
                onChange={(event) =>
                  setStatus(event.target.value as ContentStatus)
                }
              >
                <option value="published">Published</option>
                <option value="draft">Draft</option>
                <option value="archived">Archived</option>
              </select>
            </div>

            <div className="field form-grid-span">
              <label>File</label>
              <input
                type="file"
                accept={
                  type === "ringtone"
                    ? "audio/mpeg,audio/mp4,audio/x-m4a,.mp3,.m4a"
                    : "image/jpeg,image/png,image/webp"
                }
                onChange={(event) => setFile(event.target.files?.[0] ?? null)}
                required
              />
              {file && (
                <span className="muted" style={{ fontSize: "0.92rem" }}>
                  Selected: {file.name}
                </span>
              )}
            </div>
          </div>

          <label className="checkbox-row">
            <input
              type="checkbox"
              checked={premium}
              onChange={(event) => setPremium(event.target.checked)}
            />
            <span>Premium content</span>
          </label>

          {error && <div className="error">{error}</div>}
          {message && <div className="badge success">{message}</div>}

          <div className="form-actions">
            <button className="btn" type="submit" disabled={uploading}>
              {uploading ? "Uploading…" : "Upload & publish"}
            </button>
          </div>
        </form>

        <div className="panel stack">
          <div className="section-heading">
            <h2 style={{ margin: 0, fontFamily: "var(--font-display)" }}>
              Library
            </h2>
          </div>

          <form className="toolbar" onSubmit={onFilter}>
            <input
              value={q}
              onChange={(event) => setQ(event.target.value)}
              placeholder="Search title or slug"
            />
            <select
              value={typeFilter}
              onChange={(event) => setTypeFilter(event.target.value)}
            >
              <option value="">All types</option>
              <option value="wallpaper">Wallpaper</option>
              <option value="ringtone">Ringtone</option>
              <option value="poster">Poster</option>
            </select>
            <select
              value={statusFilter}
              onChange={(event) => setStatusFilter(event.target.value)}
            >
              <option value="">All statuses</option>
              <option value="published">Published</option>
              <option value="draft">Draft</option>
              <option value="archived">Archived</option>
            </select>
            <button className="btn secondary" type="submit">
              Filter
            </button>
          </form>

          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Asset</th>
                  <th>Type</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item) => (
                  <tr key={item.id}>
                    <td>
                      <strong>{item.title.en}</strong>
                      <div className="muted">
                        {item.slug} · {item.category}
                      </div>
                    </td>
                    <td>
                      <span className="badge">{item.type}</span>
                    </td>
                    <td>
                      <span
                        className={`badge ${
                          item.status === "published"
                            ? "success"
                            : item.status === "draft"
                              ? "warning"
                              : "danger"
                        }`}
                      >
                        {item.status}
                      </span>
                    </td>
                    <td>
                      <div className="row-actions">
                        {item.status !== "published" && (
                          <button
                            className="btn secondary"
                            onClick={() =>
                              void setItemStatus(item, "published")
                            }
                          >
                            Publish
                          </button>
                        )}
                        {item.status !== "archived" && (
                          <button
                            className="btn danger"
                            onClick={() =>
                              void setItemStatus(item, "archived")
                            }
                          >
                            Archive
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
                {items.length === 0 && (
                  <tr>
                    <td colSpan={4}>
                      <div className="empty">
                        No content yet. Upload your first asset or run{" "}
                        <code>npm run seed:content</code> in backend.
                      </div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
