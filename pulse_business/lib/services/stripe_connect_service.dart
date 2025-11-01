import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeConnectService extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Create Stripe Connected Account (Express type for easy onboarding)
  Future<String?> createConnectedAccount({
    required String businessId,
    required String businessEmail,
    required String businessName,
    String country = 'CA', // Default to Canada
  }) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('🔵 Creating Stripe Connected Account for: $businessName');

      final callable = FirebaseFunctions.instance
          .httpsCallable('createConnectedAccount');

      final response = await callable.call({
        'businessId': businessId,
        'email': businessEmail,
        'businessName': businessName,
        'country': country,
        'type': 'express', // Easiest onboarding flow
      });

      if (response.data['success'] == true) {
        final accountId = response.data['accountId'] as String;
        debugPrint('✅ Stripe account created: $accountId');
        return accountId;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to create account');
      }
    } catch (e) {
      _errorMessage = 'Failed to create Stripe account: $e';
      debugPrint('❌ Error creating connected account: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Generate Account Link for onboarding (returns URL to open in browser)
  Future<String?> createAccountLink({
    required String connectedAccountId,
    required String businessId,
  }) async {
    try {
      _clearError();

      debugPrint('🔵 Creating account link for: $connectedAccountId');

      final callable = FirebaseFunctions.instance
          .httpsCallable('createAccountLink');

      final response = await callable.call({
        'connectedAccountId': connectedAccountId,
        // Deep links to return to app
        'refreshUrl': 'pulse://business/stripe-refresh',
        'returnUrl': 'pulse://business/stripe-complete',
      });

      if (response.data['success'] == true) {
        final url = response.data['url'] as String;
        debugPrint('✅ Account link created');
        return url;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to create link');
      }
    } catch (e) {
      _errorMessage = 'Failed to create onboarding link: $e';
      debugPrint('❌ Error creating account link: $e');
      return null;
    }
  }

  /// Launch Stripe onboarding in browser
  Future<bool> launchOnboarding(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        _errorMessage = 'Could not launch onboarding URL';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to launch onboarding: $e';
      return false;
    }
  }

  /// Check Stripe account status and update Firestore
  Future<Map<String, dynamic>?> checkAccountStatus(String connectedAccountId) async {
    try {
      debugPrint('🔵 Checking account status: $connectedAccountId');

      final callable = FirebaseFunctions.instance
          .httpsCallable('getAccountStatus');

      final response = await callable.call({
        'connectedAccountId': connectedAccountId,
      });

      if (response.data['success'] == true) {
        debugPrint('✅ Account status retrieved');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to get status');
      }
    } catch (e) {
      debugPrint('❌ Error checking account status: $e');
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}