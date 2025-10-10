// pulse_business/lib/services/redemption_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/purchase.dart';

class RedemptionService extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Purchase? _lastRedeemedVoucher;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Purchase? get lastRedeemedVoucher => _lastRedeemedVoucher;

  /// Redeem a voucher using QR code data
  Future<Purchase?> redeemVoucher(String qrCodeData) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('🔵 Attempting to redeem voucher: $qrCodeData');

      // Call Firebase Cloud Function to redeem voucher
      final callable = FirebaseFunctions.instance
          .httpsCallable('redeemVoucher');

      final response = await callable.call({
        'purchaseId': qrCodeData,
      });

      debugPrint('✅ Redemption response: ${response.data}');

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['purchase'] != null) {
        // Convert the purchase data to Purchase object
        final purchaseData = data['purchase'] as Map<String, dynamic>;
        final redeemedPurchase = Purchase.fromMap(purchaseData);
        
        _lastRedeemedVoucher = redeemedPurchase;
        notifyListeners();
        
        return redeemedPurchase;
      } else {
        final errorMsg = data['error']?.toString() ?? 'Failed to redeem voucher';
        _setError(errorMsg);
        return null;
      }

    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Cloud Function Error: ${e.code} - ${e.message}');
      debugPrint('❌ Details: ${e.details}');
      _setError(_getFirebaseFunctionError(e));
      return null;
    } catch (e) {
      debugPrint('❌ Error redeeming voucher: $e');
      _setError('Failed to redeem voucher: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify voucher without redeeming (check validity)
  Future<Purchase?> verifyVoucher(String qrCodeData) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('🔵 Verifying voucher: $qrCodeData');

      // Call Firebase Cloud Function to verify voucher
      final callable = FirebaseFunctions.instance
          .httpsCallable('verifyVoucher');

      final response = await callable.call({
        'purchaseId': qrCodeData,
      });

      debugPrint('✅ Verification response: ${response.data}');

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['purchase'] != null) {
        final purchaseData = data['purchase'] as Map<String, dynamic>;
        return Purchase.fromMap(purchaseData);
      } else {
        final errorMsg = data['error']?.toString() ?? 'Invalid voucher';
        _setError(errorMsg);
        return null;
      }

    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Cloud Function Error: ${e.code} - ${e.message}');
      _setError(_getFirebaseFunctionError(e));
      return null;
    } catch (e) {
      debugPrint('❌ Error verifying voucher: $e');
      _setError('Failed to verify voucher: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get user-friendly error from Firebase Function error
  String _getFirebaseFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in to redeem vouchers';
      case 'not-found':
        return 'Voucher not found';
      case 'permission-denied':
        return 'You don\'t have permission to redeem this voucher';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'invalid-argument':
        return 'Invalid voucher code';
      case 'failed-precondition':
        return e.message ?? 'Voucher cannot be redeemed';
      case 'already-exists':
        return 'Voucher has already been redeemed';
      default:
        return e.message ?? 'An error occurred';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearLastRedemption() {
    _lastRedeemedVoucher = null;
    notifyListeners();
  }
}