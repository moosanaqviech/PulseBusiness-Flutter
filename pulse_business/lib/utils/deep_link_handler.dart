import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

class DeepLinkHandler {
  static StreamSubscription? _subscription;
  static AppLinks? _appLinks;

  static void initialize(BuildContext context) {
    _appLinks = AppLinks();
    
    // Listen to incoming links when app is already running
    _subscription = _appLinks!.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(context, uri);
    }, onError: (err) {
      debugPrint('❌ Deep link error: $err');
    });

    // Check for initial link (app was opened with deep link)
    _checkInitialLink(context);
  }

  static Future<void> _checkInitialLink(BuildContext context) async {
    try {
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(context, initialUri);
      }
    } catch (e) {
      debugPrint('❌ Error checking initial link: $e');
    }
  }

  static void _handleDeepLink(BuildContext context, Uri uri) {
    debugPrint('🔗 Deep link received: $uri');
    
    if (uri.scheme == 'pulse' && uri.host == 'business') {
      if (uri.path == '/stripe-complete') {
        // Stripe onboarding completed
        _handleStripeComplete(context);
      } else if (uri.path == '/stripe-refresh') {
        // User refreshed during onboarding - need to restart
        _handleStripeRefresh(context);
      }
    }
  }

  static void _handleStripeComplete(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verifying payment setup...'),
        duration: Duration(seconds: 2),
      ),
    );
    // Navigate back to onboarding screen to verify
    // The screen will call checkAccountStatus automatically
  }

  static void _handleStripeRefresh(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please complete all required steps'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  static void dispose() {
    _subscription?.cancel();
    _appLinks = null;
  }
}