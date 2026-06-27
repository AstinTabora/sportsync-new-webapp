import { firestore } from "firebase-admin";

export interface PendingBookingInput {
  refCode: string;
  holdId: string;
  userId: string;
  courtId: string;
  courtName: string;
  courtType: string;
  date: string;
  slots: Array<{ court: string; time: string }>;
  totalAmount: number;
  amountCents: number;
  userName: string;
  userEmail: string;
  userPhone: string;
  payment: "gcash" | "card" | "qrph";
  paymongoCheckoutSessionId: string;
  checkoutUrl: string;
}

export async function upsertPendingBooking(
  db: firestore.Firestore,
  input: PendingBookingInput
): Promise<void> {
  const ref = db.collection("bookings").doc(input.refCode);
  await ref.set(
    {
      userId: input.userId,
      courtId: input.courtId,
      courtName: input.courtName,
      courtType: input.courtType,
      date: firestore.Timestamp.fromDate(parseDate(input.date)),
      slots: input.slots,
      totalAmount: input.totalAmount,
      amountCents: input.amountCents,
      payment: input.payment,
      status: "pendingPayment",
      refCode: input.refCode,
      userName: input.userName,
      userEmail: input.userEmail,
      userPhone: input.userPhone,
      paymongoCheckoutSessionId: input.paymongoCheckoutSessionId,
      holdId: input.holdId,
      checkoutUrl: input.checkoutUrl,
      createdAt: firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

export async function markBookingPaid(
  db: firestore.Firestore,
  refCode: string,
  paymongoPaymentId: string,
  tx?: firestore.Transaction
): Promise<void> {
  const ref = db.collection("bookings").doc(refCode);
  const patch = {
    status: "paid",
    paymongoPaymentId,
    paidAt: firestore.FieldValue.serverTimestamp(),
  };
  if (tx) tx.set(ref, patch, { merge: true });
  else await ref.set(patch, { merge: true });
}

export async function markBookingFailed(
  db: firestore.Firestore,
  refCode: string,
  tx?: firestore.Transaction
): Promise<void> {
  const ref = db.collection("bookings").doc(refCode);
  const patch = { status: "paymentFailed" };
  if (tx) tx.set(ref, patch, { merge: true });
  else await ref.set(patch, { merge: true });
}

function parseDate(yyyymmdd: string): Date {
  const [y, m, d] = yyyymmdd.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

const pad = (n: number): string => String(n).padStart(2, "0");

/**
 * Write one `bookedSlots` doc per slot of a (paid) booking so the court
 * calendar reflects the booking for everyone. Idempotent via deterministic
 * ids, so duplicate webhook deliveries / a later reconcile are harmless.
 */
export async function markSlotsBookedForBooking(
  db: firestore.Firestore,
  refCode: string
): Promise<void> {
  const snap = await db.collection("bookings").doc(refCode).get();
  if (!snap.exists) return;
  const b = snap.data() as {
    courtId?: string;
    date?: firestore.Timestamp;
    slots?: Array<{ court: string; time: string }>;
  };
  if (!b.courtId || !b.date || !Array.isArray(b.slots)) return;

  const d = b.date.toDate();
  const dateStr = `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(
    d.getUTCDate()
  )}`;

  const batch = db.batch();
  for (const s of b.slots) {
    const id = `${b.courtId}_${dateStr}_${s.time}`.replace(/[^\w-]/g, "_");
    batch.set(
      db.collection("bookedSlots").doc(id),
      {
        courtId: b.courtId,
        date: dateStr,
        court: s.court,
        time: s.time,
        refCode,
      },
      { merge: true }
    );
  }
  await batch.commit();
}
