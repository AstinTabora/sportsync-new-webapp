import 'package:flutter/widgets.dart';

/// Watches app foreground/background transitions while the payment sheet is
/// open. We use the `paused` signal as a heuristic that the user has
/// switched to the GCash / browser app — the sheet transitions to state D
/// "opening gcash…".
class PaymentLifecycleObserver with WidgetsBindingObserver {
  PaymentLifecycleObserver({required this.onBackgrounded, this.onResumed});

  final VoidCallback onBackgrounded;

  /// Fired when the app returns to the foreground — e.g. the user came back
  /// from the PayMongo checkout page. Used to reconcile the payment.
  final VoidCallback? onResumed;

  void attach() => WidgetsBinding.instance.addObserver(this);
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      onBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      onResumed?.call();
    }
  }
}
