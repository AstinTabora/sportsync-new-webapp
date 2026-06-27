import { initializeApp } from "firebase-admin/app";

initializeApp();

export { createCheckoutSession } from "./handlers/createCheckoutSession";
export { reconcilePayment } from "./handlers/reconcilePayment";
export { paymongoWebhook } from "./handlers/paymongoWebhook";

// NOTE: The admin web app (court owner dashboard) intentionally uses NO Cloud
// Functions. Owner signup, approval, court/schedule/blockout management are all
// done directly against Firestore, gated by security rules (see firestore.rules
// — role/status live on the ownerProfiles doc). `onBookingPaid.ts` remains in
// the tree as an optional future "email the owner when paid" trigger; export it
// here and set the EMAILJS_* secrets if/when you want it.
