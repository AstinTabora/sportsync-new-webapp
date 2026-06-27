# SportSync Admin Web

Next.js 14 + Firebase dashboard for court owners. Same Firebase project
(`sportsync-376d7`) as the Flutter mobile app — courts, schedules, and
block-outs created here flow straight to customers.

**No Cloud Functions required.** Owner signup, approval, and all court /
schedule / block-out management run directly against Firestore, gated by
security rules (role + status live as fields on each `ownerProfiles` doc).

## Setup

1. `cp .env.local.example .env.local` and fill in the Firebase Web SDK config
   (already pre-filled from `lib/firebase_options.dart` if you copied it there).
2. `npm install`
3. `npm run dev`
4. Make sure the Firestore rules are live: from the repo root run
   `firebase deploy --only firestore:rules` (one-time; needed so the app can
   write owner profiles and courts). Also enable **Email/Password** under
   Firebase Console → Authentication → Sign-in method.

Visit `http://localhost:3000`. Sign up to request an owner account, then
approve yourself from the Firebase Console (see below).

## Approving an owner (and your first super admin)

After signup, the account sits at `status: pending`. Approval is a direct edit
to the owner's Firestore doc — no Cloud Function, no service account:

1. Firebase Console → **Firestore Database** → `ownerProfiles` → open the doc
   whose id is your user's uid (find the uid under Authentication → Users).
2. Set **`status`** to `approved`.
3. For your own super-admin account, also add a field **`role`** = `superAdmin`.
4. Reload the app — it picks up the change live and drops you on the dashboard.

Once you're a super admin, you can approve other owners the same way (or, later,
through an in-app approvals screen). Clients can only ever create their own doc
as `pending`; security rules forbid self-approval, so this Console edit is the
only path to `approved`.

## Migrating the 5 hardcoded sample courts to Firestore

From the `/functions` directory:

```bash
npm run build
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
  node lib/scripts/migrateSampleCourts.js
```

The script writes courts under `ownerId: 'seed'` with a default 06:00–22:00
hourly schedule. Reassign to a real owner uid from the Firebase Console.

## Scripts

- `npm run dev` — local dev server
- `npm run build` — production build
- `npm run start` — serve the production build
- `npm run type-check` — TypeScript only
