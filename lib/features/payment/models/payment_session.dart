/// Result of a successful `createCheckoutSession` callable.
class PaymentSession {
  const PaymentSession({
    required this.checkoutUrl,
    required this.sessionId,
    required this.refCode,
  });

  final String checkoutUrl;
  final String sessionId;
  final String refCode;
}
