import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/core/config/env.dart';

/// Routes incoming `sportsync://payment/callback?ref=...&status=...` URIs
/// from the OS into the payment state machine. Initialised once at app
/// boot from main.dart.
class PaymentDeepLinkService {
  PaymentDeepLinkService();

  final AppLinks _appLinks = AppLinks();
  final StreamController<PaymentDeepLinkCallback> _controller =
      StreamController.broadcast();
  StreamSubscription<Uri>? _sub;

  Stream<PaymentDeepLinkCallback> get stream => _controller.stream;

  Future<void> start() async {
    // Cold-start: app launched via a deep link.
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);

    // Warm: app already running.
    _sub = _appLinks.uriLinkStream.listen(_handle);
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }

  void _handle(Uri uri) {
    if (uri.scheme != Env.paymentDeepLinkScheme) return;
    if (uri.host != Env.paymentDeepLinkHost) return;
    final ref = uri.queryParameters['ref'];
    final status = uri.queryParameters['status'];
    if (ref == null || status == null) return;
    _controller.add(PaymentDeepLinkCallback(
      refCode: ref,
      status: status == 'success'
          ? PaymentCallbackStatus.success
          : PaymentCallbackStatus.cancel,
    ));
  }
}

enum PaymentCallbackStatus { success, cancel }

class PaymentDeepLinkCallback {
  const PaymentDeepLinkCallback({
    required this.refCode,
    required this.status,
  });
  final String refCode;
  final PaymentCallbackStatus status;
}

final paymentDeepLinkServiceProvider =
    Provider<PaymentDeepLinkService>((ref) {
  final service = PaymentDeepLinkService();
  ref.onDispose(service.dispose);
  return service;
});
