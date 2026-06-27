/// The 8-state machine for the payment bottom sheet. Letters match the
/// design doc (screens-payment-v2.jsx) so designers and engineers can
/// point at the same thing.
enum PaymentSheetState {
  /// A — returning user, saved method. v1 unused; reserved for v2 when we
  /// migrate to Payment Intents and have a vaulted method.
  returningSavedMethod,

  /// B — first-time user, QR Ph "scan to pay" CTA.
  firstTime,

  /// C — final-60s warning. Chrome overlay; tiles unchanged.
  finalWarning,

  /// D — "opening checkout…". User has been redirected to the QR Ph checkout
  /// page; we're waiting for them to come back via deep link.
  processing,

  /// E — "confirming…". User returned but webhook hasn't landed yet.
  confirming,

  /// F — "paid. you're in." Auto-dismiss in 3s.
  success,

  /// G — declined / cancelled. Slot still held; retry CTA visible.
  declined,

  /// H — slot expired. Hold is gone; offer 3 alternates.
  expired,
}
