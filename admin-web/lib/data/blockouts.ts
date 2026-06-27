import { collection, getDocs, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase/client";

export interface ConflictItem {
  date: string;
  time: string;
  refCode: string;
}

/**
 * Enumerate every "YYYY-MM-DD" from start to end inclusive (UTC). Ported from
 * the old createBlockout Cloud Function so the conflict check now runs client
 * side.
 */
export function enumerateDateRange(
  startYyyymmdd: string,
  endYyyymmdd: string
): string[] {
  const start = parseDate(startYyyymmdd);
  const end = parseDate(endYyyymmdd);
  if (end.getTime() < start.getTime()) return [];
  const out: string[] = [];
  for (let t = start.getTime(); t <= end.getTime(); t += 86_400_000) {
    out.push(formatDate(new Date(t)));
  }
  return out;
}

/**
 * Find existing booked slots that would collide with a proposed block-out.
 * `slots` is either an explicit list of "HH:mm" times or "all" (whole day).
 * Returns the conflicting booked slots so the UI can show them and refuse.
 */
export async function findBookedConflicts(
  courtId: string,
  dates: string[],
  slots: string[] | "all"
): Promise<ConflictItem[]> {
  const conflicts: ConflictItem[] = [];
  for (const date of dates) {
    const snap = await getDocs(
      query(
        collection(db, "bookedSlots"),
        where("courtId", "==", courtId),
        where("date", "==", date)
      )
    );
    for (const d of snap.docs) {
      const data = d.data() as { time?: string; refCode?: string };
      const time = data.time ?? "";
      if (slots === "all" || slots.includes(time)) {
        conflicts.push({ date, time, refCode: data.refCode ?? "" });
      }
    }
  }
  return conflicts;
}

function parseDate(yyyymmdd: string): Date {
  const [y, m, d] = yyyymmdd.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

function formatDate(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getUTCFullYear()}-${pad(date.getUTCMonth() + 1)}-${pad(
    date.getUTCDate()
  )}`;
}
