/* eslint-disable no-console */
/**
 * Simulate a PayMongo webhook delivery against the local emulator (or
 * a deployed function). Signs the payload with PAYMONGO_WEBHOOK_SECRET
 * using the same scheme our verifier expects.
 *
 * Usage:
 *   PAYMONGO_WEBHOOK_SECRET=whsec_xxx \
 *   TARGET_URL=http://127.0.0.1:5001/<project>/asia-southeast1/paymongoWebhook \
 *   REF_CODE=SS-C1-1234 \
 *   HOLD_ID=c1_2026-05-20_abc \
 *   USER_ID=anon-uid \
 *   EVENT_TYPE=checkout_session.payment.paid \
 *   npm run simulate-webhook
 */
import * as crypto from "crypto";
import axios from "axios";

async function main() {
  const secret = process.env.PAYMONGO_WEBHOOK_SECRET;
  const target = process.env.TARGET_URL;
  const refCode = process.env.REF_CODE ?? "SS-TEST-0000";
  const holdId = process.env.HOLD_ID ?? "test-hold";
  const userId = process.env.USER_ID ?? "test-uid";
  const eventType =
    process.env.EVENT_TYPE ?? "checkout_session.payment.paid";

  if (!secret || !target) {
    console.error("Set PAYMONGO_WEBHOOK_SECRET and TARGET_URL.");
    process.exit(1);
  }

  const eventId = `evt_test_${Date.now()}`;
  const paymentId = `pay_test_${Date.now()}`;

  const payload = {
    data: {
      id: eventId,
      type: "event",
      attributes: {
        type: eventType,
        livemode: false,
        data: {
          id: `cs_test_${Date.now()}`,
          type: "checkout_session",
          attributes: {
            status: "paid",
            metadata: { refCode, holdId, userId },
            payments: [{ id: paymentId, attributes: { status: "paid" } }],
          },
        },
      },
    },
  };

  const body = JSON.stringify(payload);
  const t = Math.floor(Date.now() / 1000).toString();
  const signature = crypto
    .createHmac("sha256", secret)
    .update(`${t}.${body}`)
    .digest("hex");
  const header = `t=${t},te=${signature}`;

  const res = await axios.post(target, body, {
    headers: {
      "Content-Type": "application/json",
      "Paymongo-Signature": header,
    },
    validateStatus: () => true,
  });
  console.log(`status: ${res.status}`);
  console.log(`body:   ${JSON.stringify(res.data)}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
