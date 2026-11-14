# May9 Global Concept — Smart Sales & Fiber Tracker

A Vercel-deployable Vite web app with public fiber street lookup, admin Excel import, OpenStreetMap/Leaflet markers, protected staff sign-in, manager-assigned and salesperson-created field visits, GPS visit check-in, opt-in active-session location updates and team dashboard.

## Before deploying
1. Create a Supabase project. Open SQL Editor and execute `supabase/schema.sql` **once on a new project**. Enable Email authentication. For production, disable unrestricted public signups or use a managed staff invitation process; all new accounts start inactive.
2. Create the **first admin**: sign up through the app, then in Supabase SQL Editor run (replace email):
   ```sql
   update public.profiles set role='admin',active=true where id=(select id from auth.users where email='admin@yourcompany.com');
   ```
3. No Google Cloud account, Google Maps API key or Google Maps billing is required. This edition uses Leaflet and OpenStreetMap tiles. The public OpenStreetMap tile service has a usage policy and no uptime guarantee; use a suitable tile provider for higher traffic. Map tiles still require internet access. The map is a visual aid and does not verify fiber coverage.
4. In Vercel, import this project from GitHub or upload its contents. Framework: Vite. Set environment variables listed in `.env.example` (use only Supabase public/anon key, **never service_role**). Deploy. Add your deployed domain to Supabase Auth URL configuration.
5. The new **May9 Global Concept** logo is already installed at `public/logo.png`.
6. Sign in as approved admin, open **Excel updates**, upload street spreadsheet, inspect preview and confirm. Supported headings: Street, Area, Salesperson, Installation Duration, Available, Latitude, Longitude. Columns are heuristically mapped: review before importing. **If your existing spreadsheet uses a different layout, adapt mapping before upload.** The uploaded workbook is included as `sample-street-distribution.xlsx`, and a parsed reference is included as `sample-coverage.json`. Enterprise and Residential entries are kept distinct using the area suffix.

## Run locally
```bash
npm install
cp .env.example .env.local
# fill in environment variables
npm run dev
```

## Location and privacy notes
- A staff member must explicitly start sharing and grant browser location permission. Updates only work reliably while the page is open and active; this is **not** guaranteed background GPS tracking.
- The Stop button ends the session. If the tab closes unexpectedly, location transmission stops; server sessions can remain open until manually ended. Dashboard only shows recent updates (24h) and marks data stale after 2 minutes. For production, add a heartbeat/session expiry job and a server endpoint to close abandoned sessions.
- A manager/admin can see active-session positions; a salesperson can see their own. GPS check-ins store timestamp and coordinates.
- HTTPS is required for browser geolocation (Vercel provides HTTPS). GPS is approximate and can be spoofed; do not treat check-ins as proof of presence.
- Inform staff of location data purpose, access, retention and deletion. Establish a retention schedule and deletion jobs before real deployment.
- Public coverage includes the assigned salesperson's name because the existing customer checker requires it. Avoid putting personal phone numbers or private notes into coverage records.

## Production hardening before organization-wide use
- Add server-side audit logging, row-level limits, automated session expiry, retention policies, rate limiting, robust bulk import validation, and a proper onboarding/identity-verification workflow.
- Limit role changes to trusted administrators. Review Supabase RLS and storage policies with your security team.
- This is a functional **starter project**, not a tested production rollout. No Supabase credentials were supplied to validate live integration. The May9 logo and uploaded street workbook are bundled.


## Supplied workbook mapping
The two sheets have their header on row 4, area group separators, and the columns **Street**, **Expected Delivery**, **Sales Person Assigned To**. The app now detects these rows and imports both Enterprise and Residential. The `sample-coverage.json` is a reference only; production data is not published until an approved administrator imports the workbook through the dashboard. Source rows do not include GPS coordinates; map pins need coordinates to be supplied separately.

## OpenStreetMap edition notes
- No Google Maps API key is needed. Only `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are required in Vercel.
- Map markers appear only when GPS coordinates exist. The supplied Excel street list has no coordinates; do not assume that text-only streets have accurate pin locations.
- GPS check-in and opt-in sharing use the browser Geolocation API over HTTPS; the map itself does not perform GPS tracking.
- Public OSM tiles are subject to https://operations.osmfoundation.org/policies/tiles/ and must not be bulk-downloaded. For substantial production usage, configure a commercial or self-hosted tile provider.
- Staff GPS tracking requires consent, a documented retention policy and production security review. This remains a starter application.
