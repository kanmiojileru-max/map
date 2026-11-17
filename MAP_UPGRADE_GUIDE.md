# May9 Interactive Map — Deployment Guide

## What is included
- Street/area search and automatic zoom to stored verified coordinates
- Interactive coverage markers and popup with salesperson, installation estimate, and Google Maps directions
- Optional one-time browser GPS lookup of covered streets within 5 km (not stored)
- User-triggered approximate OpenStreetMap Nominatim lookup for streets missing coordinates (not automatically saved)
- Existing login, Excel import, staff tracking and company logo retained

## Deploy
1. Back up your GitHub repository and export the Supabase `coverage` table.
2. Extract this ZIP and open the `cobranet-smart-tracker` folder. Upload its *contents*, preserving the `src/`, `public/`, and `supabase/` folders, into the root of the same GitHub repository. Replace old files with these new files. Do not upload the ZIP as one file.
3. Check Vercel project settings: Framework Preset **Vite**, Build Command `npm run build`, Output Directory `dist`, Root Directory the repository root (unless your files live in a subfolder).
4. Keep the existing environment variables `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` unchanged. Use the Supabase publishable/anon key, never the secret/service_role key.
5. Push/commit the changes; Vercel should deploy the latest GitHub commit automatically.
6. Test street search, marker popup, GPS permission, and directions.

## Coordinates
Your existing `coverage` table already has nullable `latitude` and `longitude` columns. Enter **verified** coordinates for each street in Supabase Table Editor. The street search works without coordinates, but no verified marker is drawn. For a temporary preview, use the **Find approximate location** button: this does not update the database and must not be treated as a precise street location. The public Nominatim service is rate-limited and unsuitable for automated bulk geocoding; use a paid/hosted provider or manual verification for large-scale location enrichment.

## Privacy and safety
GPS in the public checker is requested only when the user presses **Use my location**, and is used in memory for the nearby search. This feature does not write GPS to Supabase. Existing staff location tracking is separate, opt-in, and controlled by the existing RLS policies. Never expose staff live GPS in the public map. Do not put Supabase service_role or secret keys in VITE_ variables.

## Notes
- Only records with verified coordinates are included in nearby searches and coverage map markers.
- Search results with no coordinates still show coverage and assigned salesperson.
- `Find approximate location` calls the public Nominatim API only when clicked. Please follow the OpenStreetMap Nominatim usage policy and replace with a dedicated provider if traffic grows.
- This upgrade does not reset Supabase passwords or change administrator roles.
