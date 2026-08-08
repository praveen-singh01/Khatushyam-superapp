import { FormEvent, useEffect, useRef, useState } from "react";
import { useAuth } from "../auth";
import { fetchStory, updateStory } from "../lib/api";
import type { StoryChapter } from "../types";

function emptyChapter(index = 0): StoryChapter {
  const n = index + 1;
  return {
    title: { hi: `अध्याय ${n}`, en: `Chapter ${n}` },
    body: { hi: "", en: "" },
  };
}

export function StoryPage() {
  const { token } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [titleHi, setTitleHi] = useState("");
  const [titleEn, setTitleEn] = useState("");
  const [summaryHi, setSummaryHi] = useState("");
  const [summaryEn, setSummaryEn] = useState("");
  const [youtubeUrl, setYoutubeUrl] = useState("");
  const [chapters, setChapters] = useState<StoryChapter[]>([emptyChapter()]);
  const lastChapterRef = useRef<HTMLDivElement | null>(null);
  const shouldScrollToNew = useRef(false);

  useEffect(() => {
    if (!token) return;
    let cancelled = false;
    (async () => {
      try {
        setLoading(true);
        setError(null);
        const { story } = await fetchStory(token);
        if (cancelled) return;
        setTitleHi(story.title.hi);
        setTitleEn(story.title.en);
        setSummaryHi(story.summary.hi);
        setSummaryEn(story.summary.en);
        setYoutubeUrl(
          story.youtubeVideoId
            ? `https://www.youtube.com/watch?v=${story.youtubeVideoId}`
            : "",
        );
        setChapters(
          story.chapters.length > 0 ? story.chapters : [emptyChapter()],
        );
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load story");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [token]);

  useEffect(() => {
    if (!shouldScrollToNew.current) return;
    shouldScrollToNew.current = false;
    lastChapterRef.current?.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
  }, [chapters.length]);

  function updateChapter(
    index: number,
    patch: (chapter: StoryChapter) => StoryChapter,
  ) {
    setChapters((prev) =>
      prev.map((chapter, i) => (i === index ? patch(chapter) : chapter)),
    );
  }

  function moveChapter(index: number, direction: -1 | 1) {
    setChapters((prev) => {
      const next = [...prev];
      const target = index + direction;
      if (target < 0 || target >= next.length) return prev;
      const tmp = next[index]!;
      next[index] = next[target]!;
      next[target] = tmp;
      return next;
    });
  }

  function addChapter() {
    shouldScrollToNew.current = true;
    setMessage(null);
    setChapters((prev) => [...prev, emptyChapter(prev.length)]);
  }

  function duplicateChapter(index: number) {
    shouldScrollToNew.current = true;
    setChapters((prev) => {
      const source = prev[index]!;
      const copy: StoryChapter = {
        title: {
          hi: `${source.title.hi} (प्रतिलिपि)`,
          en: `${source.title.en} (copy)`,
        },
        body: { ...source.body },
      };
      const next = [...prev];
      next.splice(index + 1, 0, copy);
      return next;
    });
  }

  async function onSave(event: FormEvent) {
    event.preventDefault();
    if (!token) return;
    setSaving(true);
    setError(null);
    setMessage(null);
    try {
      const { story } = await updateStory(token, {
        title: { hi: titleHi.trim(), en: titleEn.trim() },
        summary: { hi: summaryHi.trim(), en: summaryEn.trim() },
        youtubeVideoId: youtubeUrl.trim() ? youtubeUrl.trim() : null,
        chapters: chapters.map((chapter) => ({
          title: {
            hi: chapter.title.hi.trim(),
            en: chapter.title.en.trim(),
          },
          body: {
            hi: chapter.body.hi.trim(),
            en: chapter.body.en.trim(),
          },
        })),
      });
      setTitleHi(story.title.hi);
      setTitleEn(story.title.en);
      setSummaryHi(story.summary.hi);
      setSummaryEn(story.summary.en);
      setYoutubeUrl(
        story.youtubeVideoId
          ? `https://www.youtube.com/watch?v=${story.youtubeVideoId}`
          : "",
      );
      setChapters(story.chapters);
      setMessage(
        `Saved ${story.chapters.length} chapter(s). Pull to refresh खोजें in the app.`,
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save story");
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <section className="panel">
        <p className="muted">Loading story…</p>
      </section>
    );
  }

  return (
    <section>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          gap: 12,
          alignItems: "flex-start",
          flexWrap: "wrap",
          marginBottom: 18,
        }}
      >
        <div>
          <h1 style={{ margin: 0, fontFamily: "var(--font-display)" }}>
            Story
          </h1>
          <p className="muted" style={{ margin: "6px 0 0" }}>
            Edit title, summary, and chapters for the app&apos;s खोजें tab. You
            can add as many chapters as you need.
          </p>
        </div>
        <button className="btn" type="button" onClick={addChapter}>
          + Add chapter
        </button>
      </div>

      {error && (
        <div className="banner danger" style={{ marginBottom: 14 }}>
          {error}
        </div>
      )}
      {message && (
        <div className="banner success" style={{ marginBottom: 14 }}>
          {message}
        </div>
      )}

      <form className="panel" onSubmit={onSave}>
        <h2 style={{ marginTop: 0, fontFamily: "var(--font-display)" }}>
          Story details
        </h2>

        <div className="field">
          <label htmlFor="story-title-hi">Title (Hindi)</label>
          <input
            id="story-title-hi"
            value={titleHi}
            onChange={(e) => setTitleHi(e.target.value)}
            required
          />
        </div>
        <div className="field">
          <label htmlFor="story-title-en">Title (English)</label>
          <input
            id="story-title-en"
            value={titleEn}
            onChange={(e) => setTitleEn(e.target.value)}
            required
          />
        </div>
        <div className="field">
          <label htmlFor="story-summary-hi">Summary (Hindi)</label>
          <textarea
            id="story-summary-hi"
            rows={3}
            value={summaryHi}
            onChange={(e) => setSummaryHi(e.target.value)}
            required
          />
        </div>
        <div className="field">
          <label htmlFor="story-summary-en">Summary (English)</label>
          <textarea
            id="story-summary-en"
            rows={3}
            value={summaryEn}
            onChange={(e) => setSummaryEn(e.target.value)}
            required
          />
        </div>
        <div className="field">
          <label htmlFor="story-youtube">
            Optional YouTube video (URL or ID)
          </label>
          <input
            id="story-youtube"
            value={youtubeUrl}
            onChange={(e) => setYoutubeUrl(e.target.value)}
            placeholder="Leave empty for logo hero"
          />
        </div>

        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            gap: 12,
            marginTop: 24,
            marginBottom: 8,
          }}
        >
          <h2 style={{ margin: 0, fontFamily: "var(--font-display)" }}>
            Chapters ({chapters.length})
          </h2>
          <button className="btn secondary" type="button" onClick={addChapter}>
            + Add chapter
          </button>
        </div>

        {chapters.map((chapter, index) => (
          <div
            key={index}
            ref={index === chapters.length - 1 ? lastChapterRef : undefined}
            className="panel"
            style={{
              marginBottom: 14,
              boxShadow: "none",
              border: "1px solid var(--line)",
            }}
          >
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                gap: 10,
                alignItems: "center",
                marginBottom: 12,
                flexWrap: "wrap",
              }}
            >
              <strong>Chapter {index + 1}</strong>
              <div className="row-actions">
                <button
                  className="btn secondary"
                  type="button"
                  disabled={index === 0}
                  onClick={() => moveChapter(index, -1)}
                >
                  Up
                </button>
                <button
                  className="btn secondary"
                  type="button"
                  disabled={index === chapters.length - 1}
                  onClick={() => moveChapter(index, 1)}
                >
                  Down
                </button>
                <button
                  className="btn secondary"
                  type="button"
                  onClick={() => duplicateChapter(index)}
                >
                  Duplicate
                </button>
                <button
                  className="btn danger"
                  type="button"
                  disabled={chapters.length <= 1}
                  onClick={() =>
                    setChapters((prev) => prev.filter((_, i) => i !== index))
                  }
                >
                  Remove
                </button>
              </div>
            </div>

            <div className="field">
              <label>Chapter title (Hindi)</label>
              <input
                value={chapter.title.hi}
                onChange={(e) =>
                  updateChapter(index, (c) => ({
                    ...c,
                    title: { ...c.title, hi: e.target.value },
                  }))
                }
                required
              />
            </div>
            <div className="field">
              <label>Chapter title (English)</label>
              <input
                value={chapter.title.en}
                onChange={(e) =>
                  updateChapter(index, (c) => ({
                    ...c,
                    title: { ...c.title, en: e.target.value },
                  }))
                }
                required
              />
            </div>
            <div className="field">
              <label>Chapter body (Hindi)</label>
              <textarea
                rows={5}
                value={chapter.body.hi}
                onChange={(e) =>
                  updateChapter(index, (c) => ({
                    ...c,
                    body: { ...c.body, hi: e.target.value },
                  }))
                }
                required
                placeholder="Write the Hindi chapter text…"
              />
            </div>
            <div className="field">
              <label>Chapter body (English)</label>
              <textarea
                rows={5}
                value={chapter.body.en}
                onChange={(e) =>
                  updateChapter(index, (c) => ({
                    ...c,
                    body: { ...c.body, en: e.target.value },
                  }))
                }
                required
                placeholder="Write the English chapter text…"
              />
            </div>
          </div>
        ))}

        <div className="row-actions" style={{ marginTop: 8 }}>
          <button className="btn secondary" type="button" onClick={addChapter}>
            + Add another chapter
          </button>
          <button className="btn" type="submit" disabled={saving}>
            {saving ? "Saving…" : "Save story"}
          </button>
        </div>
      </form>
    </section>
  );
}
