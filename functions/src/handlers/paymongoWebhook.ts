import { onRequest, Request } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { Response } from "express";
import { firestore } from "firebase-admin";
import { verifyWebhookSignature } from "../paymongo/verifyWebhook";
import { PaymongoEvent } from "../paymongo/types";
import {
  markBookingFailed,
  markBookingPaid,
  markSlotsBookedForBooking,
} from "../domain/bookings";
import { markHoldConsumed } from "../domain/slotHolds";

const PAYMONGO_WEBHOOK_SECRET = defineSecret("PAYMONGO_WEBHOOK_SECRET");

export const paymongoWebhook = onRequest(
  {
    region: "asia-southeast1",
    secrets: [PAYMONGO_WEBHOOK_SECRET],
    // PayMongo's servers can't pass GCP auth — they sign the request body
    // instead. Public invoker + signature verification (below) is the gate.
    invoker: "public",
  },
  async (req: Request, res: Response) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    const signature = req.header("Paymongo-Signature");
    const verify = verifyWebhookSignature(
      signature,
      req.rawBody,
      PAYMONGO_WEBHOOK_SECRET.value()
    );
    if (!verify.ok) {
      logger.warn("webhook signature rejected", { reason: verify.reason });
      res.status(401).send("Invalid signature");
      return;
    }

    let event: PaymongoEvent;
    try {
      event = JSON.parse(req.rawBody.toString("utf8"));
    } catch {
      res.status(400).send("Invalid JSON");
      return;
    }

    const eventId = event?.data?.id;
    const eventType = event?.data?.attributes?.type;
    if (!eventId || !eventType) {
      logger.warn("webhook missing id or type", { eventId, eventType });
      res.status(200).send("ok"); // ignore malformed events
      return;
    }

    const db = firestore();

    // Filter the event types we act on. Everything else is a quiet 200.
    if (
      eventType !== "checkout_session.payment.paid" &&
      eventType !== "payment.paid" &&
      eventType !== "payment.failed"
    ) {
      res.status(200).send("ok");
      return;
    }

    const wrapped = event.data.attributes.data;
    const metadata = wrapped?.attributes?.metadata ?? {};
    const refCode = metadata.refCode;
    const holdId = metadata.holdId;

    if (!refCode) {
      logger.warn("webhook missing refCode metadata", { eventId, eventType });
      res.status(200).send("ok");
      return;
    }

    try {
      await db.runTransaction(async (tx) => {
        const eventRef = db.collection("paymentEvents").doc(eventId);
        const existing = await tx.get(eventRef);
        if (existing.exists) return; // idempotent no-op

        tx.set(eventRef, {
          type: eventType,
          refCode,
          receivedAt: firestore.FieldValue.serverTimestamp(),
          rawPayload: event as unknown as Record<string, unknown>,
        });

        if (eventType === "payment.failed") {
          await markBookingFailed(db, refCode, tx);
          return;
        }

        // Both checkout_session.payment.paid and payment.paid → mark paid.
        const paymentId =
          wrapped?.attributes?.payments?.[0]?.id ??
          wrapped?.id ??
          "unknown";
        await markBookingPaid(db, refCode, paymentId, tx);
      });

      // Side-effects outside the transaction. We accept best-effort here:
      // booking is already marked paid; failing the hold update is non-fatal.
      if (eventType !== "payment.failed" && holdId) {
        try {
          await markHoldConsumed(db, holdId);
        } catch (e) {
          logger.warn("hold consume failed (non-fatal)", {
            holdId,
            err: (e as Error).message,
          });
        }
      }

      // Reflect the booking on the court calendar for everyone.
      if (eventType !== "payment.failed") {
        try {
          await markSlotsBookedForBooking(db, refCode);
        } catch (e) {
          logger.warn("bookedSlots write failed (non-fatal)", {
            refCode,
            err: (e as Error).message,
          });
        }
      }
    } catch (e) {
      logger.error("webhook handling failed", {
        err: (e as Error).message,
        eventId,
        eventType,
      });
      // Return 200 so PayMongo doesn't retry-storm. We rely on logs/alerting.
    }

    res.status(200).send("ok");
  }
);
