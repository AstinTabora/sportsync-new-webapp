import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { firestore } from "firebase-admin";
import axios from "axios";

const EMAILJS_SERVICE_ID = defineSecret("EMAILJS_SERVICE_ID");
const EMAILJS_TEMPLATE_ID = defineSecret("EMAILJS_OWNER_TEMPLATE_ID");
const EMAILJS_PUBLIC_KEY = defineSecret("EMAILJS_PUBLIC_KEY");
const EMAILJS_PRIVATE_KEY = defineSecret("EMAILJS_PRIVATE_KEY");

/**
 * Notify the court owner via email when a booking flips to "paid".
 *
 * EmailJS REST endpoint mirrors the customer-side call in
 * lib/features/booking/widgets/user_form_modal.dart. Failure is non-fatal —
 * the booking is already valid; this trigger only adds a notification.
 */
export const onBookingPaid = onDocumentUpdated(
  {
    document: "bookings/{refCode}",
    region: "asia-southeast1",
    secrets: [
      EMAILJS_SERVICE_ID,
      EMAILJS_TEMPLATE_ID,
      EMAILJS_PUBLIC_KEY,
      EMAILJS_PRIVATE_KEY,
    ],
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === "paid" || after.status !== "paid") return;

    const refCode = event.params.refCode;
    const courtId = after.courtId as string | undefined;
    if (!courtId) {
      logger.warn("paid booking missing courtId", { refCode });
      return;
    }

    const db = firestore();
    const courtSnap = await db.collection("courts").doc(courtId).get();
    if (!courtSnap.exists) {
      logger.warn("court not found for paid booking", { refCode, courtId });
      return;
    }
    const court = courtSnap.data() as { ownerId?: string; name?: string };
    if (!court.ownerId) return;

    const ownerSnap = await db
      .collection("ownerProfiles")
      .doc(court.ownerId)
      .get();
    if (!ownerSnap.exists) return;
    const owner = ownerSnap.data() as {
      email?: string;
      displayName?: string;
    };
    if (!owner.email) return;

    const slots = (after.slots ?? []) as Array<{ court: string; time: string }>;
    const slotsText = slots.map((s) => `${s.court}: ${s.time}`).join(" | ");
    const date = after.date as firestore.Timestamp | undefined;
    const dateStr = date
      ? date.toDate().toISOString().slice(0, 10)
      : "";

    try {
      await axios.post(
        "https://api.emailjs.com/api/v1.0/email/send",
        {
          service_id: EMAILJS_SERVICE_ID.value(),
          template_id: EMAILJS_TEMPLATE_ID.value(),
          user_id: EMAILJS_PUBLIC_KEY.value(),
          accessToken: EMAILJS_PRIVATE_KEY.value(),
          template_params: {
            type: "NEW PAID BOOKING",
            heading_label: "REFERENCE CODE",
            heading_value: refCode,
            detail_1_label: "Court",
            detail_1_value: court.name ?? "",
            detail_2_label: "Date",
            detail_2_value: dateStr,
            detail_3_label: "Time Slots",
            detail_3_value: slotsText,
            detail_4_label: "Total",
            detail_4_value: `PHP ${after.totalAmount}`,
            detail_5_label: "Customer",
            detail_5_value: `${after.userName} (${after.userEmail})`,
            person_section_title: "OWNER",
            user_name: owner.displayName ?? "",
            user_email: owner.email,
            user_phone: "",
            name: owner.displayName ?? "",
            email: owner.email,
          },
        },
        { headers: { "Content-Type": "application/json" }, timeout: 10_000 }
      );
      logger.info("owner email sent", { refCode, ownerId: court.ownerId });
    } catch (e) {
      logger.error("owner email failed", {
        refCode,
        err: (e as Error).message,
      });
    }
  }
);
