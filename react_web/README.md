# Tadreeb Institute Desktop

Desktop dashboard for institute owners, built with React, TypeScript, and Electron.
It follows the active mobile theme tokens: green `#176B4D`, coral `#D9574F`,
warm sand background `#FAF5E9`, and bundled Cairo/Poppins fonts.

## Run locally

1. Copy `.env.example` to `.env`.
2. Set `VITE_API_BASE_URL` to the backend origin (without `/api`).
3. Start the Tadreeb backend.
4. Run `npm install` and `npm run dev` for development.

The default API origin is `http://127.0.0.1:5000`. The desktop client uses the existing `/api` routes and does not change the backend or mobile app.
For a desktop run without the Vite development server, run `npm run build` after changing `.env`, then `npm start`.

## Institute management

- **Courses:** create and edit draft courses, upload an optional JPG/PNG/WEBP cover (up to 5 MB), publish drafts, close or reopen registration, and delete empty drafts.
- **Reservations:** review all reservation and payment records, approve or reject submitted transfers, add in-person registrations, search previous student names by international phone number, and resubmit a rejected in-person receipt while its review window is still open.
- **Balance payments:** record cash payments immediately or submit transfer receipts for review. Amounts are checked against the reservation's saved payment policy and remaining balance.
- **Institute settings:** update institute contact details and configure installment/full-balance policy and rejected-receipt resubmission hours.

The UI validates common input constraints before submission, while the backend remains authoritative for availability, payment policy, and permissions. Attendance marking and a separate student directory are not included because the current institute API does not expose those operations.

## Build

- `npm run typecheck`
- `npm test`
- `npm run build`
- `npm run package:win` to create a Windows NSIS installer in `release/`

The login token is encrypted with Electron `safeStorage` and kept in the app's user-data directory. Arabic UI fonts are bundled with the app.
