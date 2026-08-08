# Khatu Shyam content library

S3-ready media pack for wallpapers and ringtones.

```
khatu-shyam-content/
├── wallpapers/
│   ├── baba-darshan/
│   ├── khatu-temple/
│   ├── festival/
│   ├── ekadashi/
│   └── quotes/
├── ringtones/
│   ├── jai-shree-shyam/
│   ├── shyam-mantra/
│   ├── bhajan/
│   └── notification/
├── metadata.json
├── LICENSES.md
└── scripts/seed_library.py
```

## What is included

| Type | Per category | Notes |
|------|--------------|--------|
| Wallpapers | 10 each (50 total) | Mix of Wikimedia Commons (CC) temple photos + original generated phone art (1080×1920) |
| Ringtones | 10 each (40 total) | Original synthesized `.m4a` tones — **placeholders**, not licensed singer bhajans |

## Important (copyright)

We **cannot** legally scrape Google Images / YouTube bhajans into your app store product.

- Wikimedia photos: keep attribution (see `metadata.json` + `LICENSES.md`).
- Generated tones/wallpapers: you own them; replace bhajan tones with studio/licensed vocals before marketing them as real bhajans.
- For commercial darshan murti photos and famous bhajan recordings: commission or buy a license.

## Regenerate

```bash
cd khatu-shyam-content
python3 scripts/seed_library.py
```

## Upload to S3

```bash
aws s3 sync . s3://YOUR_BUCKET/khatu-shyam-content/ \
  --exclude "scripts/*" \
  --exclude "README.md" \
  --exclude "LICENSES.md" \
  --exclude ".DS_Store"
```

Point the app CDN / `CLOUDFRONT_BASE_URL` at that prefix and serve `metadata.json` as the catalog.
