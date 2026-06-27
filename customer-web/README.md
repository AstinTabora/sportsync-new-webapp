# SportSync — Customer Web

A responsive **React + Vite + TypeScript + Tailwind** port of the SportSync
mobile booking app. Works on both mobile and desktop. This is a **frontend-only
demo** — the Firebase / PayMongo / Cloud Functions backend is stubbed out and all
data is mocked in memory.

## Run

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # type-check + production build into dist/
```

## What's here

- **Design system** ported 1:1 from the Flutter app's `lib/core/theme/*` into
  `tailwind.config.js` + `src/index.css` (colors, typography, radii, shadows).
- **Routes** mirror the original `go_router` map (see `src/App.tsx`):
  `/home`, `/home/recommendations`, `/courts/:id`, `/courts/:id/book`,
  `/bookings`, `/profile`, `/profile/edit|account|about`.
- **Responsive chrome** (`src/components/layout/AppShell.tsx`): a left sidebar on
  desktop, a floating header + bottom tab bar on mobile. Modals render as centered
  dialogs on desktop and bottom sheets on mobile.
- **Mock data**: the 5 seed courts (`src/data/courts.ts`) and a couple of seeded
  bookings (`src/data/mockBookings.ts`).
- **Mock state** via React Context (`src/state/`): auth, bookings, the multi-step
  booking flow, and onboarding filters.

## Full flow (no backend)

Home → onboarding sheet → recommendations → court detail → book (pick date +
slots) → choose payment → mock "processing" → confirmation → the new booking
appears under **My Bookings**. Sign-in, profile editing, and onboarding are all
mocked.

## Relationship to the rest of the repo

The original Flutter app (`lib/`, `ios/`, `android/`, …) is left untouched. This
new app lives alongside the existing `admin-web/` Next.js dashboard and shares the
same visual identity and seed data.
