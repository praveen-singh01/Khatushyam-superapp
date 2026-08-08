# Khatu Shyam Admin

Web console for uploading library content (wallpapers / ringtones) and managing users.

## Production

Deployed on Vercel: https://khatu-shyam-admin.vercel.app

Set `VITE_API_BASE_URL` in the Vercel project to your public API base URL (not localhost), and allow that Vercel origin in backend `APP_ORIGIN`.

## Setup

```bash
cd admin
cp .env.example .env
npm install
npm run dev
```

Open http://127.0.0.1:5173

## Auth

1. Start the API with fake auth:
   ```bash
   cd ../backend
   npm run local
   ```
2. On the login screen, use token `admin`.

In production, paste a Firebase Google ID token for an email listed in backend `ADMIN_EMAILS`.

## Features

- Dashboard stats (users, premium, wallpapers, ringtones)
- Content upload via S3 presigned URL + Mongo catalog entry
- Publish / archive library assets
- User search, role changes, and premium grant/revoke
