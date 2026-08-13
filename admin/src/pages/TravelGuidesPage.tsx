import { FormEvent, useEffect, useRef, useState } from "react";
import { useAuth } from "../auth";
import { fetchTravelGuides, updateTravelGuides } from "../lib/api";
import type { TravelGuideItem } from "../types";

function emptyGuide(index = 0): TravelGuideItem {
  const n = index + 1;
  return {
    id: `guide-${n}`,
    fromCity: { hi: "", en: "" },
    title: { hi: "", en: "" },
    steps: [{ hi: "", en: "" }],
  };
}

export function TravelGuidesPage() {
  const { token } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [guides, setGuides] = useState<TravelGuideItem[]>([emptyGuide()]);
  const lastGuideRef = useRef<HTMLDivElement | null>(null);
  const shouldScrollToNew = useRef(false);

  useEffect(() => {
    if (!token) return;
    let cancelled = false;
    (async () => {
      try {
        setLoading(true);
        setError(null);
        const { travelGuides } = await fetchTravelGuides(token);
        if (cancelled) return;
        setGuides(
          travelGuides.guides.length > 0
            ? travelGuides.guides
            : [emptyGuide()],
        );
      } catch (err) {
        if (!cancelled) {
          setError(
            err instanceof Error
              ? err.message
              : "Failed to load travel guides",
          );
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
    lastGuideRef.current?.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
  }, [guides.length]);

  function updateGuide(
    index: number,
    patch: (guide: TravelGuideItem) => TravelGuideItem,
  ) {
    setGuides((prev) =>
      prev.map((guide, i) => (i === index ? patch(guide) : guide)),
    );
  }

  function addGuide() {
    shouldScrollToNew.current = true;
    setMessage(null);
    setGuides((prev) => [...prev, emptyGuide(prev.length)]);
  }

  function removeGuide(index: number) {
    setGuides((prev) =>
      prev.length <= 1 ? prev : prev.filter((_, i) => i !== index),
    );
  }

  function addStep(guideIndex: number) {
    updateGuide(guideIndex, (g) => ({
      ...g,
      steps: [...g.steps, { hi: "", en: "" }],
    }));
  }

  function removeStep(guideIndex: number, stepIndex: number) {
    updateGuide(guideIndex, (g) => ({
      ...g,
      steps:
        g.steps.length <= 1
          ? g.steps
          : g.steps.filter((_, i) => i !== stepIndex),
    }));
  }

  async function onSave(event: FormEvent) {
    event.preventDefault();
    if (!token) return;
    setSaving(true);
    setError(null);
    setMessage(null);
    try {
      const cleaned = guides.map((g) => ({
        ...g,
        id: g.id.trim().toLowerCase().replace(/[^a-z0-9-]+/g, "-"),
        fromCity: {
          hi: g.fromCity.hi.trim(),
          en: g.fromCity.en.trim() || g.fromCity.hi.trim(),
        },
        title: {
          hi: g.title.hi.trim(),
          en: g.title.en.trim() || g.title.hi.trim(),
        },
        steps: g.steps.map((s) => ({
          hi: s.hi.trim(),
          en: s.en.trim() || s.hi.trim(),
        })),
      }));
      const { travelGuides } = await updateTravelGuides(token, {
        guides: cleaned,
      });
      setGuides(travelGuides.guides);
      setMessage("Travel guides saved. App will show the updated list.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save");
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div className="page">
        <h1>Travel guides</h1>
        <p className="muted">Loading…</p>
      </div>
    );
  }

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h1>Travel guides</h1>
          <p className="muted">
            App Travel Guide screen — Hinglish ok. Edit steps anytime.
          </p>
        </div>
        <button className="btn" type="button" onClick={addGuide}>
          Add guide
        </button>
      </div>

      {error ? (
        <div className="banner danger" style={{ marginBottom: 14 }}>
          {error}
        </div>
      ) : null}
      {message ? (
        <div className="banner success" style={{ marginBottom: 14 }}>
          {message}
        </div>
      ) : null}

      <form className="stack" onSubmit={onSave}>
        {guides.map((guide, index) => (
          <div
            key={`${guide.id}-${index}`}
            className="card stack"
            ref={index === guides.length - 1 ? lastGuideRef : undefined}
          >
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                gap: 12,
              }}
            >
              <strong>
                Guide {index + 1}
                {guide.title.hi ? ` — ${guide.title.hi}` : ""}
              </strong>
              <button
                className="btn ghost"
                type="button"
                onClick={() => removeGuide(index)}
                disabled={guides.length <= 1}
              >
                Remove
              </button>
            </div>

            <label>
              Id (slug)
              <input
                value={guide.id}
                onChange={(e) =>
                  updateGuide(index, (g) => ({ ...g, id: e.target.value }))
                }
                required
                placeholder="how-to-reach-khatu"
              />
            </label>

            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: 12,
              }}
            >
              <label>
                Title (Hinglish / HI)
                <input
                  value={guide.title.hi}
                  onChange={(e) =>
                    updateGuide(index, (g) => ({
                      ...g,
                      title: { ...g.title, hi: e.target.value },
                    }))
                  }
                  required
                />
              </label>
              <label>
                Title (EN)
                <input
                  value={guide.title.en}
                  onChange={(e) =>
                    updateGuide(index, (g) => ({
                      ...g,
                      title: { ...g.title, en: e.target.value },
                    }))
                  }
                />
              </label>
            </div>

            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: 12,
              }}
            >
              <label>
                From city (HI)
                <input
                  value={guide.fromCity.hi}
                  onChange={(e) =>
                    updateGuide(index, (g) => ({
                      ...g,
                      fromCity: { ...g.fromCity, hi: e.target.value },
                    }))
                  }
                  required
                />
              </label>
              <label>
                From city (EN)
                <input
                  value={guide.fromCity.en}
                  onChange={(e) =>
                    updateGuide(index, (g) => ({
                      ...g,
                      fromCity: { ...g.fromCity, en: e.target.value },
                    }))
                  }
                />
              </label>
            </div>

            <div className="stack">
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  gap: 12,
                }}
              >
                <strong>Steps</strong>
                <button
                  className="btn ghost"
                  type="button"
                  onClick={() => addStep(index)}
                >
                  Add step
                </button>
              </div>
              {guide.steps.map((step, stepIndex) => (
                <div key={stepIndex} className="card stack">
                  <div
                    style={{
                      display: "flex",
                      justifyContent: "space-between",
                      alignItems: "center",
                      gap: 12,
                    }}
                  >
                    <span className="muted">Step {stepIndex + 1}</span>
                    <button
                      className="btn ghost"
                      type="button"
                      onClick={() => removeStep(index, stepIndex)}
                      disabled={guide.steps.length <= 1}
                    >
                      Remove step
                    </button>
                  </div>
                  <label>
                    Hinglish / HI
                    <textarea
                      rows={3}
                      value={step.hi}
                      onChange={(e) =>
                        updateGuide(index, (g) => ({
                          ...g,
                          steps: g.steps.map((s, i) =>
                            i === stepIndex ? { ...s, hi: e.target.value } : s,
                          ),
                        }))
                      }
                      required
                    />
                  </label>
                  <label>
                    EN (optional — defaults to HI)
                    <textarea
                      rows={2}
                      value={step.en}
                      onChange={(e) =>
                        updateGuide(index, (g) => ({
                          ...g,
                          steps: g.steps.map((s, i) =>
                            i === stepIndex ? { ...s, en: e.target.value } : s,
                          ),
                        }))
                      }
                    />
                  </label>
                </div>
              ))}
            </div>
          </div>
        ))}

        <button className="btn primary" type="submit" disabled={saving}>
          {saving ? "Saving…" : "Save travel guides"}
        </button>
      </form>
    </div>
  );
}
