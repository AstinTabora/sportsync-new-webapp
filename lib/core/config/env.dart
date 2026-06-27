/// Build-time configuration read from --dart-define flags.
///
/// Usage:
///   flutter run --dart-define=PAYMONGO_PUBLIC_KEY=pk_test_xxx
class Env {
  static const paymongoPublicKey =
      String.fromEnvironment('PAYMONGO_PUBLIC_KEY', defaultValue: '');

  static const functionsRegion = String.fromEnvironment(
    'CLOUD_FUNCTIONS_REGION',
    defaultValue: 'asia-southeast1',
  );

  static const paymentDeepLinkScheme = 'sportsync';
  static const paymentDeepLinkHost = 'payment';

  static bool get isConfigured => paymongoPublicKey.isNotEmpty;
}
