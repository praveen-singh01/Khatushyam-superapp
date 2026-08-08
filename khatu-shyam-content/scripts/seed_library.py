#!/usr/bin/env python3
"""Seed an S3-ready Khatu Shyam content library.

Wallpapers:
  - Wikimedia Commons CC images where available (with attribution)
  - Original generated phone wallpapers to reach 10 per category

Ringtones:
  - Original short tones generated with ffmpeg (app-owned, replace later
    with licensed bhajans / studio recordings)

Does NOT scrape copyrighted Google/YouTube media.
"""

from __future__ import annotations

import json
import math
import random
import struct
import subprocess
import urllib.request
import wave
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
UA = "KhatuShyamContentBot/1.0 (dev content seed; contact: local)"

WALLPAPER_W, WALLPAPER_H = 1080, 1920

# Wikimedia Commons — only reuse with attribution (CC BY / BY-SA / CC0).
WIKI = [
    {
        "id": "wiki-khatu-temple-01",
        "category": "khatu-temple",
        "title": {"hi": "खाटू श्याम मंदिर", "en": "Khatu Shyam Temple"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/9/91/Khatu_Shyam_Temple.jpg",
        "license": "CC BY-SA 4.0",
        "attribution": "Abhaybeniwalreengus / Wikimedia Commons",
        "source_page": "https://commons.wikimedia.org/wiki/File:Khatu_Shyam_Temple.jpg",
    },
    {
        "id": "wiki-khatu-temple-02",
        "category": "khatu-temple",
        "title": {"hi": "खाटू दरबार", "en": "Khatu Darbar"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/7/77/Khatu_darbar.jpg",
        "license": "CC BY-SA 4.0",
        "attribution": "Shubhamvs22 / Wikimedia Commons",
        "source_page": "https://commons.wikimedia.org/wiki/File:Khatu_darbar.jpg",
    },
    {
        "id": "wiki-khatu-temple-03",
        "category": "khatu-temple",
        "title": {"hi": "खाटू श्याम प्रवेश द्वार", "en": "Entrance Gate"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/1/12/Khatu_Shyam_Ji_Entrance_Gate.jpg",
        "license": "CC BY-SA 4.0",
        "attribution": "TheSlumPanda / Wikimedia Commons",
        "source_page": "https://commons.wikimedia.org/wiki/File:Khatu_Shyam_Ji_Entrance_Gate.jpg",
    },
    {
        "id": "wiki-khatu-temple-04",
        "category": "khatu-temple",
        "title": {"hi": "श्याम कुंड", "en": "Shyam Kund"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/2/23/Shyam_Kund%2C_Khatu_Shyam%2C_Rajasthan.jpg",
        "license": "CC BY-SA 4.0",
        "attribution": "Vadaykeviv / Wikimedia Commons",
        "source_page": "https://commons.wikimedia.org/wiki/File:Shyam_Kund,_Khatu_Shyam,_Rajasthan.jpg",
    },
    {
        "id": "wiki-khatu-temple-05",
        "category": "khatu-temple",
        "title": {"hi": "श्री श्री खाटू श्याम मंदिर", "en": "Shree Shree Khatu Shyam Temple"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/c/c1/Shree_Shree_Khatu_Shyam_Temple.jpg",
        "license": "CC BY 4.0",
        "attribution": "SayandeepDutta / Wikimedia Commons",
        "source_page": "https://commons.wikimedia.org/wiki/File:Shree_Shree_Khatu_Shyam_Temple.jpg",
    },
    {
        "id": "wiki-khatu-temple-06",
        "category": "khatu-temple",
        "title": {"hi": "खाटू श्याम जी", "en": "Khatu Shyam Ji panorama"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/9/9d/Khatu_Shyam_Ji_-_panoramio.jpg",
        "license": "CC BY-SA 3.0",
        "attribution": "Indrapal Jangid / Wikimedia Commons",
        "source_page": "https://commons.wikimedia.org/wiki/File:Khatu_Shyam_Ji_-_panoramio.jpg",
    },
    {
        "id": "wiki-khatu-temple-07",
        "category": "khatu-temple",
        "title": {"hi": "खाटू श्याम सीकर", "en": "Khatu Shyam Sikar"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/5/5c/Khatu_shyam_sikar.jpg",
        "license": "CC BY-SA 4.0",
        "attribution": "Dhruvi agarwal / Wikimedia Commons",
        "source_page": "https://commons.wikimedia.org/wiki/File:Khatu_shyam_sikar.jpg",
    },
    {
        "id": "wiki-festival-01",
        "category": "festival",
        "title": {"hi": "फाल्गुन मेला", "en": "Falgun Mela 2014"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/9/98/Khatu_shyam_ji_Falgun_Mela_2014_by_niks.jpg",
        "license": "CC BY-SA 3.0",
        "attribution": "Niru786 / Wikimedia Commons",
        "source_page": "https://commons.wikimedia.org/wiki/File:Khatu_shyam_ji_Falgun_Mela_2014_by_niks.jpg",
    },
    {
        "id": "wiki-festival-02",
        "category": "festival",
        "title": {"hi": "खाटू श्याम झूलना", "en": "Khatu Shyam in Jhoolna"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/9/9e/Khatu_Shyam_in_Jhoolna.jpg",
        "license": "CC BY-SA 4.0",
        "attribution": "Pratha Bopche / Wikimedia Commons",
        "source_page": "https://commons.wikimedia.org/wiki/File:Khatu_Shyam_in_Jhoolna.jpg",
    },
    {
        "id": "wiki-festival-03",
        "category": "festival",
        "title": {"hi": "पadyatra कोटा से", "en": "Pad Yatra from Kota"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/9/9d/Khatushyamji_Pad_Yatra_from_Kota.JPG",
        "license": "CC BY-SA 2.5",
        "attribution": "Wikimedia Commons contributor",
        "source_page": "https://commons.wikimedia.org/wiki/File:Khatushyamji_Pad_Yatra_from_Kota.JPG",
    },
    {
        "id": "wiki-baba-01",
        "category": "baba-darshan",
        "title": {"hi": "श्री श्याम", "en": "Shree Shyam"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/5/5e/Shree_Shyam.jpg",
        "license": "CC0",
        "attribution": "Nanda2512 / Wikimedia Commons (CC0)",
        "source_page": "https://commons.wikimedia.org/wiki/File:Shree_Shyam.jpg",
    },
    {
        "id": "wiki-baba-02",
        "category": "baba-darshan",
        "title": {"hi": "खाटू श्याम जी", "en": "Khatu Shyam Ji"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/5/55/Khatu_Shyam_Ji.jpg",
        "license": "CC BY-SA 4.0",
        "attribution": "AdityaSharma92 / Wikimedia Commons",
        "source_page": "https://commons.wikimedia.org/wiki/File:Khatu_Shyam_Ji.jpg",
    },
    {
        "id": "wiki-baba-03",
        "category": "baba-darshan",
        "title": {"hi": "प्राचीन बाबा श्याम मंदिर", "en": "Ancient Baba Shyam temple"},
        "url": "https://upload.wikimedia.org/wikipedia/commons/4/49/Ancient_Baba_Shyam_temple_%E0%A4%AA%E0%A5%8D%E0%A4%B0%E0%A4%BE%E0%A4%9A%E0%A5%80%E0%A4%A8_%E0%A4%AC%E0%A4%BE%E0%A4%AC%E0%A4%BE_%E0%A4%B6_%28Ancient_Baba_Khatu_Shyam_Temple._%E0%A4%AA%E0%A5%8D%E0%A4%B0%E0%A4%BE%E0%A4%9A%E0%A5%80%E0%A4%A8_%E0%A4%B6%E0%A5%8D%E0%A4%B0%E0%A5%80_%E0%A4%B6%E0%A5%8D%E0%A4%AF%E0%A4%BE%E0%A4%AE_%E0%A4%AC%E0%A4%BE%E0%A4%AC%E0%A4%BE_%E0%A4%AE%E0%A4%82%E0%A4%A6%E0%A4%BF%E0%A4%B0_%E0%A4%AA%E0%A4%B0%E0%A4%BF%E0%A4%B8%E0%A4%B0%29.jpg",
        "license": "CC BY-SA 4.0",
        "attribution": "VIKAS KUMAR HINDUSTANI / Wikimedia Commons",
        "source_page": "https://commons.wikimedia.org/wiki/File:Ancient_Baba_Shyam_temple_%E0%A4%AA%E0%A5%8D%E0%A4%B0%E0%A4%BE%E0%A4%9A%E0%A5%80%E0%A4%A8_%E0%A4%AC%E0%A4%BE%E0%A4%AC%E0%A4%BE_%E0%A4%B6_(Ancient_Baba_Khatu_Shyam_Temple._%E0%A4%AA%E0%A5%8D%E0%A4%B0%E0%A4%BE%E0%A4%9A%E0%A5%80%E0%A4%A8_%E0%A4%B6%E0%A5%8D%E0%A4%B0%E0%A5%80_%E0%A4%B6%E0%A5%8D%E0%A4%AF%E0%A4%BE%E0%A4%AE_%E0%A4%AC%E0%A4%BE%E0%A4%AC%E0%A4%BE_%E0%A4%AE%E0%A4%82%E0%A4%A6%E0%A4%BF%E0%A4%B0_%E0%A4%AA%E0%A4%B0%E0%A4%BF%E0%A4%B8%E0%A4%B0).jpg",
    },
]

QUOTES = [
    ("जय श्री श्याम", "Jai Shree Shyam"),
    ("हे श्याम बाबा कृपा करो", "Shyam Baba, bless us"),
    ("बालेला मुकुट श्याम के", "Blessed crown of Shyam"),
    ("हाथ जोड़े खड़े हैं द्वारे", "Hands folded at your door"),
    ("श्याम नाम सुमिरन करो", "Remember the name of Shyam"),
    ("मेरे श्याम मेरे राम", "My Shyam, my Ram"),
    ("एकादशी व्रत फलदायी", "Ekadashi brings merit"),
    ("फाल्गुन मेला श्याम धाम", "Falgun Mela at Shyam Dham"),
    ("खाटू वाले श्याम", "Khatu Wale Shyam"),
    ("श्याम शरणम् गच्छामि", "I seek refuge in Shyam"),
]

PALETTES = {
    "baba-darshan": [(120, 20, 30), (200, 80, 40), (255, 200, 120)],
    "khatu-temple": [(20, 40, 80), (180, 90, 40), (250, 210, 150)],
    "festival": [(160, 30, 60), (230, 120, 40), (255, 220, 100)],
    "ekadashi": [(10, 20, 50), (40, 70, 120), (220, 230, 255)],
    "quotes": [(80, 30, 20), (190, 90, 40), (255, 230, 180)],
}

RINGTONE_CATS = {
    "jai-shree-shyam": {
        "label": {"hi": "जय श्री श्याम", "en": "Jai Shree Shyam"},
        # Ascending bright motif
        "motif": [392, 440, 494, 523, 587, 659, 698, 784],
    },
    "shyam-mantra": {
        "label": {"hi": "श्याम मंत्र", "en": "Shyam Mantra"},
        "motif": [294, 330, 349, 392, 440, 392, 349, 330],
    },
    "bhajan": {
        "label": {"hi": "भजन स्वर", "en": "Bhajan tone"},
        "motif": [262, 294, 330, 349, 392, 440, 494, 523],
    },
    "notification": {
        "label": {"hi": "सूचना ध्वनि", "en": "Notification"},
        "motif": [880, 988, 1047, 1175],
    },
}


def ensure_dirs() -> None:
    for cat in PALETTES:
        (ROOT / "wallpapers" / cat).mkdir(parents=True, exist_ok=True)
    for cat in RINGTONE_CATS:
        (ROOT / "ringtones" / cat).mkdir(parents=True, exist_ok=True)


def download(url: str, dest: Path) -> None:
    if dest.exists() and dest.stat().st_size > 1000:
        return
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as resp:
        dest.write_bytes(resp.read())


def fit_cover(img: Image.Image, w: int, h: int) -> Image.Image:
    src_w, src_h = img.size
    scale = max(w / src_w, h / src_h)
    nw, nh = int(src_w * scale), int(src_h * scale)
    img = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - w) // 2
    top = (nh - h) // 2
    return img.crop((left, top, left + w, top + h))


def gradient_base(colors: list[tuple[int, int, int]], seed: int) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new("RGB", (WALLPAPER_W, WALLPAPER_H))
    draw = ImageDraw.Draw(img)
    c1, c2, c3 = colors
    for y in range(WALLPAPER_H):
        t = y / (WALLPAPER_H - 1)
        if t < 0.55:
            u = t / 0.55
            r = int(c1[0] + (c2[0] - c1[0]) * u)
            g = int(c1[1] + (c2[1] - c1[1]) * u)
            b = int(c1[2] + (c2[2] - c1[2]) * u)
        else:
            u = (t - 0.55) / 0.45
            r = int(c2[0] + (c3[0] - c2[0]) * u)
            g = int(c2[1] + (c3[1] - c2[1]) * u)
            b = int(c2[2] + (c3[2] - c2[2]) * u)
        draw.line([(0, y), (WALLPAPER_W, y)], fill=(r, g, b))

    # Soft decorative orbs
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for _ in range(8):
        x = rng.randint(0, WALLPAPER_W)
        y = rng.randint(0, WALLPAPER_H)
        rad = rng.randint(80, 280)
        od.ellipse(
            (x - rad, y - rad, x + rad, y + rad),
            fill=(255, 220, 150, rng.randint(20, 45)),
        )
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    return img


def draw_centered_text(
    img: Image.Image,
    lines: list[str],
    fill: tuple[int, int, int] = (255, 245, 220),
) -> None:
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Unicode.ttf", 72)
        font_sm = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Unicode.ttf", 36)
    except OSError:
        font = ImageFont.load_default()
        font_sm = font

    y = WALLPAPER_H // 2 - 80
    for i, line in enumerate(lines):
        f = font if i == 0 else font_sm
        bbox = draw.textbbox((0, 0), line, font=f)
        tw = bbox[2] - bbox[0]
        x = (WALLPAPER_W - tw) // 2
        # shadow
        draw.text((x + 3, y + 3), line, font=f, fill=(40, 20, 10))
        draw.text((x, y), line, font=f, fill=fill)
        y += 90 if i == 0 else 56


def make_generated_wallpaper(category: str, index: int, dest: Path) -> dict:
    colors = PALETTES[category]
    img = gradient_base(colors, seed=hash((category, index)) % 10_000_000)
    hi, en = QUOTES[index % len(QUOTES)]
    if category == "quotes":
        draw_centered_text(img, [hi, en, "जय श्री श्याम"])
    elif category == "ekadashi":
        draw_centered_text(img, ["एकादशी", hi, "व्रत · भक्ति · शांति"])
    elif category == "festival":
        draw_centered_text(img, ["फाल्गुन मेला", hi, "खाटू धाम"])
    elif category == "baba-darshan":
        draw_centered_text(img, ["श्याम बाबा", hi, "दर्शन"])
    else:
        draw_centered_text(img, ["खाटू मंदिर", hi, "श्याम धाम"])

    dest.parent.mkdir(parents=True, exist_ok=True)
    img.save(dest, "JPEG", quality=88, optimize=True)
    asset_id = f"gen-{category}-{index:02d}"
    return {
        "id": asset_id,
        "type": "wallpaper",
        "category": category,
        "title": {"hi": hi, "en": en},
        "file": str(dest.relative_to(ROOT)),
        "format": "jpg",
        "width": WALLPAPER_W,
        "height": WALLPAPER_H,
        "license": "Original / App-owned",
        "attribution": "Generated for Khatu Shyam Superapp",
        "premium": True,
        "source": "generated",
    }


def write_tone_wav(path: Path, freqs: list[float], duration: float = 2.4) -> None:
    rate = 44100
    n = int(rate * duration)
    frames = bytearray()
    for i in range(n):
        t = i / rate
        # envelope
        env = min(1.0, t * 12) * max(0.0, 1.0 - (t / duration) ** 2)
        # pick note from motif
        note_i = min(int(t / (duration / len(freqs))), len(freqs) - 1)
        f = freqs[note_i]
        # soft bell-ish: fundamental + quiet harmonic
        sample = 0.45 * math.sin(2 * math.pi * f * t)
        sample += 0.18 * math.sin(2 * math.pi * f * 2 * t)
        sample *= env
        frames += struct.pack("<h", int(max(-1, min(1, sample)) * 30000))
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        wf.writeframes(frames)


def wav_to_m4a(wav: Path, m4a: Path) -> None:
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            str(wav),
            "-c:a",
            "aac",
            "-b:a",
            "128k",
            str(m4a),
        ],
        check=True,
    )


def make_ringtone(category: str, index: int) -> dict:
    meta = RINGTONE_CATS[category]
    base = list(meta["motif"])
    # vary each track slightly
    freqs = [f * (1.0 + 0.03 * ((index % 5) - 2)) for f in base]
    if category == "notification":
        duration = 1.2 + (index % 3) * 0.15
        freqs = freqs[: 2 + (index % 3)]
    else:
        duration = 2.2 + (index % 4) * 0.25
        # rotate motif
        rot = index % len(freqs)
        freqs = freqs[rot:] + freqs[:rot]

    stem = f"{category}-{index:02d}"
    wav = ROOT / "ringtones" / category / f"{stem}.wav"
    m4a = ROOT / "ringtones" / category / f"{stem}.m4a"
    write_tone_wav(wav, freqs, duration=duration)
    wav_to_m4a(wav, m4a)
    wav.unlink(missing_ok=True)

    titles = {
        "jai-shree-shyam": [
            ("जय श्री श्याम स्वर", "Jai Shree Shyam tone"),
            ("श्याम वंदना", "Shyam Vandana"),
            ("आरती घंटी", "Aarti bell"),
            ("मंदिर घंटा", "Temple bell"),
            ("भक्ति नाद", "Bhakti note"),
            ("श्याम जयकारा", "Shyam call"),
            ("प्रणाम स्वर", "Pranam tone"),
            ("दरबार ध्वनि", "Darbar chime"),
            ("मंगल स्वर", "Mangal tone"),
            ("श्याम कीर्तन स्वर", "Kirtan tone"),
        ],
        "shyam-mantra": [
            ("श्याम मंत्र १", "Mantra tone 1"),
            ("श्याम मंत्र २", "Mantra tone 2"),
            ("ध्यान स्वर", "Dhyan tone"),
            ("नाम जप", "Naam jap"),
            ("शांत मंत्र", "Calm mantra"),
            ("प्रातः स्मरण", "Morning recall"),
            ("संध्या मंत्र", "Evening mantra"),
            ("माला स्वर", "Mala tone"),
            ("ॐ श्याम", "Om Shyam"),
            ("मंत्र घंटी", "Mantra chime"),
        ],
        "bhajan": [
            ("भजन स्वर १", "Bhajan tone 1"),
            ("भजन स्वर २", "Bhajan tone 2"),
            ("कीर्तन धुन", "Kirtan tune"),
            ("मधुर भजन", "Sweet bhajan"),
            ("राग भक्ति", "Bhakti raga"),
            ("श्याम भजन", "Shyam bhajan"),
            ("आरती धुन", "Aarti tune"),
            ("संत स्वर", "Saint tone"),
            ("भक्ति संगीत", "Devotional music"),
            ("हार्मोनियम स्वर", "Harmonium tone"),
        ],
        "notification": [
            ("सूचना घंटी", "Notify bell"),
            ("लघु चाइम", "Short chime"),
            ("डिंग श्याम", "Shyam ding"),
            ("अलर्ट स्वर", "Alert tone"),
            ("पॉप चाइम", "Pop chime"),
            ("सॉफ्ट पिंग", "Soft ping"),
            ("डबल बेल", "Double bell"),
            ("ट्रिपल चाइम", "Triple chime"),
            ("मंदिर टिंग", "Temple ting"),
            ("हल्की घंटी", "Light bell"),
        ],
    }
    hi, en = titles[category][index]
    return {
        "id": f"tone-{category}-{index:02d}",
        "type": "ringtone",
        "category": category,
        "title": {"hi": hi, "en": en},
        "file": str(m4a.relative_to(ROOT)),
        "format": "m4a",
        "durationSec": round(duration, 2),
        "license": "Original / App-owned",
        "attribution": "Synthesized for Khatu Shyam Superapp (placeholder until licensed vocals)",
        "premium": True,
        "source": "generated",
        "note": "Replace with licensed singer recordings before marketing as real bhajans.",
    }


def main() -> None:
    ensure_dirs()
    assets: list[dict] = []
    by_cat: dict[str, int] = {c: 0 for c in PALETTES}

    # 1) Wikimedia wallpapers
    for item in WIKI:
        cat = item["category"]
        dest = ROOT / "wallpapers" / cat / f"{item['id']}.jpg"
        print(f"download {item['id']} ...")
        try:
            download(item["url"], dest)
            with Image.open(dest) as im:
                out = fit_cover(im.convert("RGB"), WALLPAPER_W, WALLPAPER_H)
                out.save(dest, "JPEG", quality=88, optimize=True)
            assets.append(
                {
                    "id": item["id"],
                    "type": "wallpaper",
                    "category": cat,
                    "title": item["title"],
                    "file": str(dest.relative_to(ROOT)),
                    "format": "jpg",
                    "width": WALLPAPER_W,
                    "height": WALLPAPER_H,
                    "license": item["license"],
                    "attribution": item["attribution"],
                    "sourcePage": item["source_page"],
                    "premium": True,
                    "source": "wikimedia",
                }
            )
            by_cat[cat] = by_cat.get(cat, 0) + 1
        except Exception as exc:  # noqa: BLE001
            print(f"  SKIP {item['id']}: {exc}")

    # 2) Fill each wallpaper category to 10 with generated art
    for cat in PALETTES:
        n = by_cat.get(cat, 0)
        i = 1
        while n < 10:
            dest = ROOT / "wallpapers" / cat / f"gen-{cat}-{i:02d}.jpg"
            print(f"generate wallpaper {cat} #{i}")
            assets.append(make_generated_wallpaper(cat, i - 1, dest))
            n += 1
            i += 1
        by_cat[cat] = n

    # 3) 10 original ringtones per category
    for cat in RINGTONE_CATS:
        for i in range(10):
            print(f"tone {cat} #{i + 1}")
            assets.append(make_ringtone(cat, i))

    meta = {
        "version": 1,
        "bucketHint": "s3://YOUR_BUCKET/khatu-shyam-content/",
        "cdnBaseUrlHint": "https://YOUR_CLOUDFRONT/",
        "categories": {
            "wallpapers": list(PALETTES.keys()),
            "ringtones": list(RINGTONE_CATS.keys()),
        },
        "counts": {
            "wallpapers": sum(1 for a in assets if a["type"] == "wallpaper"),
            "ringtones": sum(1 for a in assets if a["type"] == "ringtone"),
            "byCategory": {
                cat: sum(1 for a in assets if a.get("category") == cat) for cat in {**PALETTES, **RINGTONE_CATS}
            },
        },
        "licenseNote": (
            "Wikimedia assets require attribution (and ShareAlike for BY-SA). "
            "Generated tones/wallpapers are app-owned placeholders. "
            "Do not ship third-party bhajan vocals without a license."
        ),
        "assets": assets,
    }
    (ROOT / "metadata.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")
    print("Wrote", ROOT / "metadata.json")
    print("Counts:", meta["counts"])


if __name__ == "__main__":
    main()
