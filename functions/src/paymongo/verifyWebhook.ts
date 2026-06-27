import * as crypto from "crypto";

const MAX_AGE_SECONDS = 5 * 60;

export interface VerifyResult {
  ok: boolean;
  reason?: "missing_header" | "bad_format" | "stale" | "mismatch";
}

/**
 * Verify a PayMongo webhook signature.
 *
 * Signature header format: `t=<unix>,te=<test-sig>,li=<live-sig>`
 * We HMAC-SHA256 `${t}.${rawBody}` with the webhook secret and compare in
 * constant time against `te` (test mode) or `li` (live mode).
 *
 * Pass `mode` based on which key your function is configured with — when
 * deployed against test keys, only `te` will be present.
 */
export function verifyWebhookSignature(
  signatureHeader: string | undefined,
  rawBody: Buffer | string,
  secret: string,
  nowSeconds: number = Math.floor(Date.now() / 1000)
): VerifyResult {
  if (!signatureHeader) return { ok: false, reason: "missing_header" };

  const parts = parseHeader(signatureHeader);
  const t = parts.get("t");
  if (!t) return { ok: false, reason: "bad_format" };

  const timestamp = Number(t);
  if (!Number.isFinite(timestamp)) return { ok: false, reason: "bad_format" };
  if (Math.abs(nowSeconds - timestamp) > MAX_AGE_SECONDS) {
    return { ok: false, reason: "stale" };
  }

  const provided = parts.get("te") ?? parts.get("li");
  if (!provided) return { ok: false, reason: "bad_format" };

  const payload = `${t}.${typeof rawBody === "string" ? rawBody : rawBody.toString("utf8")}`;
  const expected = crypto
    .createHmac("sha256", secret)
    .update(payload)
    .digest("hex");

  const a = Buffer.from(expected, "utf8");
  const b = Buffer.from(provided, "utf8");
  if (a.length !== b.length) return { ok: false, reason: "mismatch" };
  if (!crypto.timingSafeEqual(a, b)) return { ok: false, reason: "mismatch" };

  return { ok: true };
}

function parseHeader(h: string): Map<string, string> {
  const map = new Map<string, string>();
  for (const pair of h.split(",")) {
    const idx = pair.indexOf("=");
    if (idx === -1) continue;
    map.set(pair.slice(0, idx).trim(), pair.slice(idx + 1).trim());
  }
  return map;
}
