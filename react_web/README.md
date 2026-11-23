# Tadreeb Institute Desktop

Desktop dashboard for institute owners, built with React, TypeScript, and Electron.
It follows the active mobile theme tokens: green `#176B4D`, coral `#D9574F`,
warm sand background `#FAF5E9`, and bundled Cairo/Poppins fonts.

## Run locally

1. Copy `.env.example` to `.env`.
2. Set `VITE_API_BASE_URL` to the backend origin (without `/api`).
3. Start the Tadreeb backend.
4. Run `npm install` and `npm run dev`.

The default API origin is `http://127.0.0.1:5000`. The desktop client uses the existing `/api` routes and does not change the backend or mobile app.

## Build

- `npm run typecheck`
- `npm test`
- `npm run build`
- `npm run package:win` to create a Windows NSIS installer in `release/`

The login token is encrypted with Electron `safeStorage` and kept in the app's user-data directory. Arabic UI fonts are bundled with the app.
