import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/core/config/env.dart';
import 'package:sportsync/core/router/app_router.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/features/payment/providers/payment_providers.dart';
import 'package:sportsync/features/payment/services/payment_deep_link_service.dart';
import 'package:sportsync/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode && !Env.isConfigured) {
    throw StateError(
      'PAYMONGO_PUBLIC_KEY is missing. Run with '
      '--dart-define=PAYMONGO_PUBLIC_KEY=pk_test_xxx',
    );
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase not yet configured for this platform (e.g. iOS).
    // Run FlutterFire CLI to add platform support: `flutterfire configure`
    debugPrint('Firebase init skipped: $e');
  }

  // Ensure we have an auth identity for slot-hold ownership. Anonymous auth
  // is upgraded later when the user signs in with Google (linkWithCredential).
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Anonymous sign-in failed: $e');
  }

  final container = ProviderContainer();
  // Start the deep-link listener at app boot — handles cold-start returns
  // from the PayMongo Checkout page.
  await container.read(paymentDeepLinkServiceProvider).start();
  // Activate the listener that pipes deep-link callbacks into the state
  // machine even when no consumer is currently watching it.
  container.read(paymentDeepLinkListenerProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SportSyncApp(),
    ),
  );
}

class SportSyncApp extends ConsumerWidget {
  const SportSyncApp({super.key});

  // Apple system font stack. iOS/macOS resolve to SF Pro; web uses the CSS
  // system font; Android falls through to Roboto via fontFamilyFallback.
  static const String _fontFamily = '-apple-system';
  static const List<String> _fontFallback = [
    'BlinkMacSystemFont',
    'SF Pro Text',
    'SF Pro Display',
    'system-ui',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        surface: AppColors.white,
        onSurface: const Color(0xFF1A1A1A),
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      useMaterial3: true,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFallback,
    );

    final textTheme = base.textTheme.apply(
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFallback,
    );

    return MaterialApp.router(
      title: 'SportSync',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: base.copyWith(
        textTheme: textTheme.copyWith(
          displayLarge: textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
          displayMedium: textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
          displaySmall: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
          headlineLarge: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
          headlineMedium: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          headlineSmall: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          titleLarge: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleMedium: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleSmall: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          bodySmall: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          labelLarge: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          labelMedium: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          labelSmall: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
