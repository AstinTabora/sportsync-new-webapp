export type PaymentMethodType = "gcash" | "card" | "qrph";

export interface CreateCheckoutSessionInput {
  billing: {
    name: string;
    email: string;
    phone?: string;
  };
  amountCentavos: number;
  lineItemName: string;
  referenceNumber: string;
  successUrl: string;
  cancelUrl: string;
  paymentMethodTypes: PaymentMethodType[];
  metadata: Record<string, string>;
  description?: string;
}

export interface CheckoutSession {
  id: string;
  checkoutUrl: string;
  paymentMethodTypes: PaymentMethodType[];
}

export interface PaymongoEvent {
  id: string;
  type: string;
  data: {
    id: string;
    attributes: {
      type: string;
      // The wrapped resource (Payment / Checkout Session) lives here.
      // PayMongo's nesting: event.data.attributes.data.attributes.metadata
      data?: {
        id: string;
        attributes: {
          status?: string;
          payment_intent_id?: string;
          metadata?: Record<string, string>;
          payments?: Array<{ id: string; attributes: { status: string } }>;
        };
      };
    };
  };
}
