# SportSync Cloud Functions

Backend for PayMongo payments. Two HTTPS endpoints:

- `createCheckoutSession` (callable) — auth-required, returns a PayMongo `checkout_url` for the app to open.
- `paymongoWebhook` (raw HTTPS) — receives PayMongo events, verifies the signature, updates `bookings/{refCode}.status`.

Region: `asia-southeast1`. Runtime: Node 20.

## First-time setup

```bash
cd functions
npm install
firebase login
firebase use --add        # pick sportsync-376d7
```

Set secrets (test keys to start; rotate to live when going to production):

```bash
firebase functions:secrets:set PAYMONGO_SECRET_KEY
# paste sk_test_xxx
```

The webhook secret comes from PayMongo after we register the webhook — see below.

## Deploy

```bash
npm run build
firebase deploy --only functions:createCheckoutSession,functions:paymongoWebhook
```

After deploy, you'll see the function URLs in the console output. The webhook URL looks like:

```
https://asia-southeast1-sportsync-376d7.cloudfunctions.net/paymongoWebhook
```

## Register the webhook with PayMongo

```bash
PAYMONGO_SECRET_KEY=sk_test_xxx \
FUNCTION_URL=https://asia-southeast1-sportsync-376d7.cloudfunctions.net/paymongoWebhook \
npm run register-webhook
```

The script prints a `whsec_*` secret. Save it:

```bash
firebase functions:secrets:set PAYMONGO_WEBHOOK_SECRET
# paste whsec_xxx
```

Then re-deploy `paymongoWebhook` so it picks up the secret:

```bash
firebase deploy --only functions:paymongoWebhook
```

## Local development

```bash
npm run build:watch        # in one terminal
firebase emulators:start --only functions
```

Simulate a webhook delivery against the emulator (or a deployed test function):

```bash
PAYMONGO_WEBHOOK_SECRET=whsec_xxx \
TARGET_URL=http://127.0.0.1:5001/sportsync-376d7/asia-southeast1/paymongoWebhook \
REF_CODE=SS-C1-1234 \
HOLD_ID=c1_2026-05-20_abc \
USER_ID=anon-uid \
EVENT_TYPE=checkout_session.payment.paid \
npm run simulate-webhook
```

## Firestore TTL setup (one time)

Enable TTL on `slotHolds.expiresAt` so expired holds clean themselves up:

Firebase console → Firestore → TTL policies → add `slotHolds.expiresAt`.

## PayMongo test mode

Default. Uses `sk_test_*` keys. Card numbers for testing:

| Card | Behavior |
|---|---|
| `4343 4343 4343 4345` | success |
| `4571 7360 0000 0014` | generic decline |
| `4400 0000 0000 0016` | insufficient funds |

GCash on test mode shows a "test GCash" page that auto-succeeds or auto-fails without real OTP.

## Going to production

1. Get `sk_live_*` keys from PayMongo dashboard (requires KYC approval).
2. Rotate the secrets: `firebase functions:secrets:set PAYMONGO_SECRET_KEY` with the new value.
3. Re-register the webhook against the *production* URL — PayMongo distinguishes test/live webhooks.
4. Rebuild the app with the live public key: `flutter build apk --dart-define=PAYMONGO_PUBLIC_KEY=pk_live_xxx` (etc).
