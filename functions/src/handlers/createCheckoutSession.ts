import { HttpsError, onCall, CallableRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { firestore } from "firebase-admin";
import { PaymongoClient, PaymongoError } from "../paymongo/client";
import { assertHoldValid } from "../domain/slotHolds";
import { upsertPendingBooking } from "../domain/bookings";

const PAYMONGO_SECRET_KEY = defineSecret("PAYMONGO_SECRET_KEY");

const DEEP_LINK_SCHEME = "sportsync";
const DEEP_LINK_HOST = "payment";
const DEEP_LINK_PATH = "callback";

// QRPh ("scan to pay") is the only method enabled on the account until the
// business permit clears GCash/Card. PayMongo renders a QR on the checkout page.
const FALLBACK_PAYMENT_METHODS: ("gcash" | "card" | "qrph")[] = ["qrph"];

interface Input {
  holdId: string;
  refCode: string;
  amountCentavos: number;
  courtId: string;
  courtName: string;
  courtType: string;
  pricePerSlot: number;
  date: string;
  slots: Array<{ court: string; time: string }>;
  userEmail: string;
  userName: string;
  userPhone: string;
  payment?: "gcash" | "card" | "qrph";
}

export const createCheckoutSession = onCall(
  {
    region: "asia-southeast1",
    secrets: [PAYMONGO_SECRET_KEY],
    cors: true,
    // Grant allUsers Cloud Run Invoker on every deploy. Functions v2 is
    // private by default; client SDKs can't reach it without this.
    invoker: "public",
  },
  async (req: CallableRequest<Input>) => {
    if (!req.auth) {
      throw new HttpsError("unauthenticated", "Sign-in required.");
    }
    const uid = req.auth.uid;
    const input = req.data;

    requireString(input.holdId, "holdId");
    requireString(input.refCode, "refCode");
    requireString(input.courtId, "courtId");
    requireString(input.date, "date");
    requireString(input.userEmail, "userEmail");
    requireString(input.userName, "userName");
    // PayMongo validates billing.email and rejects malformed values (e.g.
    // "a@a") when minting the QR, which dead-ends on its hosted page. Catch it
    // here so the client gets a clear, actionable error instead.
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.userEmail)) {
      throw new HttpsError(
        "invalid-argument",
        "A valid email is required for the receipt.",
      );
    }
    if (!Array.isArray(input.slots) || input.slots.length === 0) {
      throw new HttpsError("invalid-argument", "slots required");
    }
    if (!Number.isFinite(input.pricePerSlot) || input.pricePerSlot <= 0) {
      throw new HttpsError("invalid-argument", "pricePerSlot invalid");
    }

    const db = firestore();

    // 1. Validate hold.
    try {
      await assertHoldValid(db, input.holdId, uid);
    } catch (e) {
      const msg = (e as Error).message;
      throw new HttpsError(
        msg === "hold_expired" || msg === "hold_inactive"
          ? "failed-precondition"
          : msg === "hold_not_owned"
          ? "permission-denied"
          : "not-found",
        msg
      );
    }

    // 2. Server-derive the amount. Reject mismatched client value.
    const serverAmountCentavos =
      Math.round(input.pricePerSlot * 100) * input.slots.length;
    if (serverAmountCentavos !== input.amountCentavos) {
      logger.warn("amount mismatch", {
        client: input.amountCentavos,
        server: serverAmountCentavos,
      });
      throw new HttpsError("invalid-argument", "amount mismatch");
    }

    // 3. Build deep-link return URLs.
    const successUrl =
      `${DEEP_LINK_SCHEME}://${DEEP_LINK_HOST}/${DEEP_LINK_PATH}` +
      `?ref=${encodeURIComponent(input.refCode)}&status=success`;
    const cancelUrl =
      `${DEEP_LINK_SCHEME}://${DEEP_LINK_HOST}/${DEEP_LINK_PATH}` +
      `?ref=${encodeURIComponent(input.refCode)}&status=cancel`;

    // 4. Create the Checkout Session with PayMongo.
    const paymentMethodTypes = FALLBACK_PAYMENT_METHODS;
    const client = new PaymongoClient(PAYMONGO_SECRET_KEY.value());
    let session;
    try {
      session = await client.createCheckoutSession({
        billing: {
          name: input.userName,
          email: input.userEmail,
          ...(input.userPhone ? { phone: input.userPhone } : {}),
        },
        amountCentavos: serverAmountCentavos,
        lineItemName: `Court booking — ${input.refCode}`,
        referenceNumber: input.refCode,
        successUrl,
        cancelUrl,
        paymentMethodTypes,
        metadata: {
          refCode: input.refCode,
          holdId: input.holdId,
          userId: uid,
        },
      });
    } catch (e) {
      if (e instanceof PaymongoError) {
        if (e.status === 422) {
          throw new HttpsError("invalid-argument", e.message);
        }
        logger.error("paymongo upstream error", { err: e.message, raw: e.raw });
        throw new HttpsError("internal", "Payment provider unavailable.");
      }
      throw new HttpsError("internal", (e as Error).message);
    }

    // 5. Pre-create the booking doc as `pendingPayment`.
    try {
      await upsertPendingBooking(db, {
        refCode: input.refCode,
        holdId: input.holdId,
        userId: uid,
        courtId: input.courtId,
        courtName: input.courtName,
        courtType: input.courtType,
        date: input.date,
        slots: input.slots,
        totalAmount: serverAmountCentavos / 100,
        amountCents: serverAmountCentavos,
        userName: input.userName,
        userEmail: input.userEmail,
        userPhone: input.userPhone,
        payment: input.payment ?? "qrph",
        paymongoCheckoutSessionId: session.id,
        checkoutUrl: session.checkoutUrl,
      });
    } catch (e) {
      const msg = (e as Error).message;
      logger.error("failed to persist pending booking", {
        refCode: input.refCode,
        err: msg,
      });
      throw new HttpsError("internal", `Could not save booking: ${msg}`);
    }

    return {
      checkoutUrl: session.checkoutUrl,
      sessionId: session.id,
    };
  }
);

function requireString(v: unknown, name: string): asserts v is string {
  if (typeof v !== "string" || v.length === 0) {
    throw new HttpsError("invalid-argument", `${name} required`);
  }
}
