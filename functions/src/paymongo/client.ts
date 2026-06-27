import axios, { AxiosError, AxiosInstance } from "axios";
import {
  CheckoutSession,
  CreateCheckoutSessionInput,
  PaymentMethodType,
} from "./types";

const BASE_URL = "https://api.paymongo.com/v1";

function authHeader(secretKey: string): string {
  // PayMongo uses HTTP Basic with the secret key as the username and an
  // empty password. The token is base64("sk_test_xxx:").
  const token = Buffer.from(`${secretKey}:`).toString("base64");
  return `Basic ${token}`;
}

export class PaymongoClient {
  private readonly http: AxiosInstance;

  constructor(secretKey: string) {
    if (!secretKey) {
      throw new Error("PaymongoClient: missing secret key");
    }
    this.http = axios.create({
      baseURL: BASE_URL,
      headers: {
        Authorization: authHeader(secretKey),
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      timeout: 15_000,
    });
  }

  async createCheckoutSession(
    input: CreateCheckoutSessionInput
  ): Promise<CheckoutSession> {
    const body = {
      data: {
        attributes: {
          billing: input.billing,
          send_email_receipt: true,
          show_description: true,
          show_line_items: true,
          payment_method_types: input.paymentMethodTypes,
          line_items: [
            {
              currency: "PHP",
              amount: input.amountCentavos,
              name: input.lineItemName,
              quantity: 1,
            },
          ],
          description: input.description ?? "SportSync court booking",
          reference_number: input.referenceNumber,
          success_url: input.successUrl,
          cancel_url: input.cancelUrl,
          metadata: input.metadata,
        },
      },
    };

    try {
      const res = await this.http.post("/checkout_sessions", body);
      const data = res.data?.data;
      return {
        id: data.id as string,
        checkoutUrl: data.attributes.checkout_url as string,
        paymentMethodTypes: data.attributes
          .payment_method_types as PaymentMethodType[],
      };
    } catch (err) {
      throw normalize(err);
    }
  }

  /// Fetch a checkout session and report whether it has been paid. Used by
  /// `reconcilePayment` to confirm a payment when the webhook/deep-link were
  /// missed (e.g. PayMongo test-mode QRPh).
  async getCheckoutSession(id: string): Promise<{
    paid: boolean;
    paymentId?: string;
    sessionStatus?: string;
    paymentStatus?: string;
  }> {
    try {
      const res = await this.http.get(`/checkout_sessions/${id}`);
      const attr = res.data?.data?.attributes ?? {};
      const payments: Array<{ id: string; attributes: { status: string } }> =
        attr.payments ?? [];
      const paidPayment = payments.find((p) => p.attributes?.status === "paid");
      const piStatus: string | undefined =
        attr.payment_intent?.attributes?.status;
      const paid =
        Boolean(paidPayment) || piStatus === "succeeded" || piStatus === "paid";
      return {
        paid,
        paymentId: paidPayment?.id,
        sessionStatus: attr.status,
        paymentStatus: paidPayment?.attributes?.status ?? piStatus,
      };
    } catch (err) {
      throw normalize(err);
    }
  }

  async registerWebhook(
    url: string,
    events: string[]
  ): Promise<{ id: string; secret: string }> {
    try {
      const res = await this.http.post("/webhooks", {
        data: { attributes: { url, events } },
      });
      const data = res.data?.data;
      return {
        id: data.id as string,
        secret: data.attributes.secret_key as string,
      };
    } catch (err) {
      throw normalize(err);
    }
  }

  async listWebhooks(): Promise<Array<{ id: string; url: string }>> {
    try {
      const res = await this.http.get("/webhooks");
      return (res.data?.data ?? []).map((w: {
        id: string;
        attributes: { url: string };
      }) => ({
        id: w.id,
        url: w.attributes.url,
      }));
    } catch (err) {
      throw normalize(err);
    }
  }
}

export class PaymongoError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly raw: unknown
  ) {
    super(message);
    this.name = "PaymongoError";
  }
}

function normalize(err: unknown): PaymongoError | Error {
  if (err instanceof AxiosError) {
    const status = err.response?.status ?? 0;
    const detail =
      err.response?.data?.errors?.[0]?.detail ??
      err.response?.data?.errors?.[0]?.code ??
      err.message;
    return new PaymongoError(
      `PayMongo ${status}: ${detail}`,
      status,
      err.response?.data
    );
  }
  return err instanceof Error ? err : new Error(String(err));
}
