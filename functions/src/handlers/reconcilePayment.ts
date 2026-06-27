import { HttpsError, onCall, CallableRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { firestore } from "firebase-admin";
import { PaymongoClient, PaymongoError } from "../paymongo/client";
import { markBookingPaid, markSlotsBookedForBooking } from "../domain/bookings";
import { markHoldConsumed } from "../domain/slotHolds";

const PAYMONGO_SECRET_KEY = defineSecret("PAYMONGO_SECRET_KEY");

interface Input {
  refCode: string;
}

/**
 * Confirm a payment on demand by asking PayMongo directly, then flip the
 * booking — a fallback for when the webhook or deep-link return are missed
 * (notably PayMongo test-mode QRPh). Idempotent: mirrors `paymongoWebhook`'s
 * `markBookingPaid` + `markHoldConsumed`, so re-running or a later webhook is
 * harmless.
 */
export const reconcilePayment = onCall(
  {
    region: "asia-southeast1",
    secrets: [PAYMONGO_SECRET_KEY],
    cors: true,
    invoker: "public",
  },
  async (req: CallableRequest<Input>) => {
    if (!req.auth) {
      throw new HttpsError("unauthenticated", "Sign-in required.");
    }
    const uid = req.auth.uid;
    const refCode = req.data?.refCode;
    if (typeof refCode !== "string" || refCode.length === 0) {
      throw new HttpsError("invalid-argument", "refCode required");
    }

    const db = firestore();
    const ref = db.collection("bookings").doc(refCode);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }

    const booking = snap.data() as {
      userId?: string;
      status?: string;
      paymongoCheckoutSessionId?: string;
      holdId?: string;
    };
    if (booking.userId !== uid) {
      throw new HttpsError("permission-denied", "Not your booking.");
    }

    // Already resolved — no PayMongo round-trip needed.
    if (booking.status === "paid") return { status: "paid" };
    if (booking.status === "paymentFailed") return { status: "paymentFailed" };

    const sessionId = booking.paymongoCheckoutSessionId;
    if (!sessionId) {
      return { status: booking.status ?? "pendingPayment" };
    }

    const client = new PaymongoClient(PAYMONGO_SECRET_KEY.value());
    let result;
    try {
      result = await client.getCheckoutSession(sessionId);
    } catch (e) {
      if (e instanceof PaymongoError) {
        logger.error("reconcile: paymongo error", {
          refCode,
          err: e.message,
        });
        throw new HttpsError("internal", "Could not reach payment provider.");
      }
      throw new HttpsError("internal", (e as Error).message);
    }

    if (result.paid) {
      await markBookingPaid(db, refCode, result.paymentId ?? "reconciled");
      if (booking.holdId) {
        try {
          await markHoldConsumed(db, booking.holdId);
        } catch (e) {
          logger.warn("reconcile: hold consume failed (non-fatal)", {
            holdId: booking.holdId,
            err: (e as Error).message,
          });
        }
      }
      try {
        await markSlotsBookedForBooking(db, refCode);
      } catch (e) {
        logger.warn("reconcile: bookedSlots write failed (non-fatal)", {
          refCode,
          err: (e as Error).message,
        });
      }
      return { status: "paid" };
    }

    return { status: booking.status ?? "pendingPayment" };
  }
);
