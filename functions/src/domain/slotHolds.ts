import { firestore } from "firebase-admin";

export type SlotHoldStatus = "active" | "consumed" | "cancelled" | "expired";

export interface SlotHold {
  userId: string;
  courtId: string;
  date: string;
  slots: Array<{ court: string; time: string }>;
  amountCents: number;
  expiresAt: firestore.Timestamp;
  status: SlotHoldStatus;
  createdAt: firestore.Timestamp;
}

/**
 * Read a hold and assert it belongs to `uid`, is `active`, and hasn't
 * expired. Throws with a stable message that the caller maps to an
 * appropriate HttpsError code.
 */
export async function assertHoldValid(
  db: firestore.Firestore,
  holdId: string,
  uid: string
): Promise<SlotHold> {
  const snap = await db.collection("slotHolds").doc(holdId).get();
  if (!snap.exists) throw new Error("hold_not_found");
  const data = snap.data() as SlotHold;
  if (data.userId !== uid) throw new Error("hold_not_owned");
  if (data.status !== "active") throw new Error("hold_inactive");
  if (data.expiresAt.toMillis() < Date.now()) throw new Error("hold_expired");
  return data;
}

export async function markHoldConsumed(
  db: firestore.Firestore,
  holdId: string
): Promise<void> {
  await db.collection("slotHolds").doc(holdId).update({ status: "consumed" });
}
