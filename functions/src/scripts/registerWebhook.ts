/* eslint-disable no-console */
/**
 * One-shot script to register our webhook URL with PayMongo.
 *
 * Usage:
 *   PAYMONGO_SECRET_KEY=sk_test_xxx \
 *   FUNCTION_URL=https://asia-southeast1-sportsync-376d7.cloudfunctions.net/paymongoWebhook \
 *   npm run register-webhook
 *
 * Prints the webhook id + secret. Copy the secret into Firebase Secrets:
 *   firebase functions:secrets:set PAYMONGO_WEBHOOK_SECRET
 */
import { PaymongoClient } from "../paymongo/client";

const EVENTS = [
  "checkout_session.payment.paid",
  "payment.paid",
  "payment.failed",
];

async function main() {
  const secretKey = process.env.PAYMONGO_SECRET_KEY;
  const url = process.env.FUNCTION_URL;
  if (!secretKey || !url) {
    console.error(
      "Set PAYMONGO_SECRET_KEY and FUNCTION_URL env vars and re-run."
    );
    process.exit(1);
  }

  const client = new PaymongoClient(secretKey);

  const existing = await client.listWebhooks();
  const match = existing.find((w) => w.url === url);
  if (match) {
    console.log(`Webhook already registered for this URL: ${match.id}`);
    console.log(
      "If you need to rotate the secret, delete it in the PayMongo dashboard and re-run."
    );
    return;
  }

  const created = await client.registerWebhook(url, EVENTS);
  console.log("Registered webhook:");
  console.log(`  id:     ${created.id}`);
  console.log(`  url:    ${url}`);
  console.log(`  secret: ${created.secret}`);
  console.log("");
  console.log("Now run:");
  console.log("  firebase functions:secrets:set PAYMONGO_WEBHOOK_SECRET");
  console.log(`  # paste: ${created.secret}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
