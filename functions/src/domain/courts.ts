import { firestore } from "firebase-admin";

export type CourtType = "badminton" | "pickleball" | "basketball";

export interface CourtDoc {
  ownerId: string;
  name: string;
  type: CourtType;
  location: string;
  price: number;
  rating: number;
  numberOfCourts: number;
  amenities: string[];
  image: string;
  description: string;
  phone?: string;
  email?: string;
  mapUrl?: string;
  latitude?: number;
  longitude?: number;
  published: boolean;
  createdAt: firestore.Timestamp;
  updatedAt: firestore.Timestamp;
}

export interface ScheduleSlot {
  time: string;          // "HH:mm", 24-hour
  durationMins: number;  // typically 60
  price: number;         // overrides court.price when set
  courtNumbers: string[];// e.g. ["Court 1", "Court 2"]; empty = all courts
}

export interface ScheduleDayDoc {
  active: boolean;
  slots: ScheduleSlot[];
  updatedAt: firestore.Timestamp;
  updatedBy: string;
}

export type DayOfWeek =
  | "monday"
  | "tuesday"
  | "wednesday"
  | "thursday"
  | "friday"
  | "saturday"
  | "sunday";

export const DAYS_OF_WEEK: DayOfWeek[] = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
];

export interface BlockoutDoc {
  startDate: string;     // "YYYY-MM-DD"
  endDate: string;       // "YYYY-MM-DD"
  slots: string[] | "all"; // ["06:00", "07:00"] or "all"
  reason: string;
  createdBy: string;
  createdAt: firestore.Timestamp;
}

export function courtsCollection(
  db: firestore.Firestore
): firestore.CollectionReference {
  return db.collection("courts");
}

export function scheduleCollection(
  db: firestore.Firestore,
  courtId: string
): firestore.CollectionReference {
  return db.collection("courts").doc(courtId).collection("schedule");
}

export function blockoutsCollection(
  db: firestore.Firestore,
  courtId: string
): firestore.CollectionReference {
  return db.collection("courts").doc(courtId).collection("blockouts");
}

export async function assertCourtOwner(
  db: firestore.Firestore,
  courtId: string,
  uid: string
): Promise<CourtDoc> {
  const snap = await courtsCollection(db).doc(courtId).get();
  if (!snap.exists) throw new Error("court_not_found");
  const data = snap.data() as CourtDoc;
  if (data.ownerId !== uid) throw new Error("court_not_owned");
  return data;
}

/**
 * Enumerate all "YYYY-MM-DD" dates from start to end inclusive (UTC).
 */
export function enumerateDateRange(
  startYyyymmdd: string,
  endYyyymmdd: string
): string[] {
  const start = parseDate(startYyyymmdd);
  const end = parseDate(endYyyymmdd);
  if (end.getTime() < start.getTime()) return [];
  const out: string[] = [];
  for (
    let t = start.getTime();
    t <= end.getTime();
    t += 24 * 60 * 60 * 1000
  ) {
    out.push(formatDate(new Date(t)));
  }
  return out;
}

export function parseDate(yyyymmdd: string): Date {
  const [y, m, d] = yyyymmdd.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

export function formatDate(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getUTCFullYear()}-${pad(date.getUTCMonth() + 1)}-${pad(
    date.getUTCDate()
  )}`;
}
