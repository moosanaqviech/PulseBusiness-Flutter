import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart';
import '../services/stripe_connect_service.dart';

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
    debugPrint('✅ Handling Stripe completion deep link');
    
    // Show loading message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Verifying payment setup...'),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

    // Get the business and check Stripe status
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final stripeService = Provider.of<StripeConnectService>(context, listen: false);
    
    if (businessProvider.currentBusiness?.stripeConnectedAccountId != null) {
      _checkStripeStatusAndNavigate(
        context, 
        businessProvider, 
        stripeService,
        businessProvider.currentBusiness!.stripeConnectedAccountId!,
      );
    } else {
      // Navigate to settings if no account ID
      _navigateToSettings(context);
    }
  }

  static Future<void> _checkStripeStatusAndNavigate(
    BuildContext context,
    BusinessProvider businessProvider,
    StripeConnectService stripeService,
    String accountId,
  ) async {
    try {
      // Check account status
      final statusResult = await stripeService.checkAccountStatus(accountId);
      
      if (statusResult != null && statusResult['success'] == true) {
        // Reload business data to get updated Stripe status
        await businessProvider.loadBusiness(businessProvider.currentBusiness!.ownerId);
        
        // Navigate to settings to show updated status
        _navigateToSettings(context);
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    statusResult['stripeAccountOnboarded'] == true 
                      ? Icons.check_circle 
                      : Icons.warning,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      statusResult['stripeAccountOnboarded'] == true
                        ? 'Payment setup complete! You can now receive payments.'
                        : 'Payment setup in progress. Please complete all required steps.',
                    ),
                  ),
                ],
              ),
              backgroundColor: statusResult['stripeAccountOnboarded'] == true 
                ? Colors.green 
                : Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        _showErrorAndNavigate(context, 'Failed to verify payment setup');
      }
    } catch (e) {
      debugPrint('❌ Error checking Stripe status: $e');
      _showErrorAndNavigate(context, 'Error verifying payment setup');
    }
  }

  static void _handleStripeRefresh(BuildContext context) {
    debugPrint('⚠️ Handling Stripe refresh deep link');
    
    // Navigate to settings
    _navigateToSettings(context);
    
    // Show refresh message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 16),
            Text('Please complete all required steps'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  static void _navigateToSettings(BuildContext context) {
    // Use GoRouter to navigate to main screen with settings tab
    if (GoRouter.of(context).canPop()) {
      context.go('/main');
    }
    
    // Small delay to ensure navigation completes, then switch to settings tab
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        // Try to find the main screen and switch to settings tab
        final navigator = Navigator.of(context);
        navigator.popUntil((route) => route.isFirst);
      }
    });
  }

  static void _showErrorAndNavigate(BuildContext context, String message) {
    _navigateToSettings(context);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  static void dispose() {
    _subscription?.cancel();
    _appLinks = null;
  }
}