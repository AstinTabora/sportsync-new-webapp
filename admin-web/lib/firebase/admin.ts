import {
  getApps,
  initializeApp,
  cert,
  applicationDefault,
  App,
} from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

function ensureApp(): App {
  if (getApps().length) return getApps()[0]!;

  const rawCreds = process.env.FIREBASE_ADMIN_CREDENTIALS;
  if (rawCreds) {
    const parsed = JSON.parse(rawCreds);
    return initializeApp({ credential: cert(parsed) });
  }
  // Falls back to GOOGLE_APPLICATION_CREDENTIALS env var or
  // metadata-server creds when running on Google infra.
  return initializeApp({ credential: applicationDefault() });
}

export const adminApp = ensureApp();
export const adminAuth = getAuth(adminApp);
