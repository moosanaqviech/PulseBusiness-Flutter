// pulse_business/lib/screens/qr_scanner/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../services/redemption_service.dart';
import '../../models/purchase.dart';
import 'redemption_success_screen.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  bool _isFlashOn = false;
  bool _isRedeemingVoucher = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Customer Voucher'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
              cameraController.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          
          // Scan Area Overlay
          _buildScanOverlay(),
          
          // Instructions
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Point camera at customer\'s voucher QR code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Make sure the QR code is clearly visible',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Loading Overlay
          if (_isRedeemingVoucher)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing voucher...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isScanning ? Colors.green : Colors.white,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Corner decorations
            ..._buildCornerDecorations(),
            
            // Scan animation
            if (_isScanning)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


Future<void> testDirectFirestoreAccess(String purchaseId) async {
  try {
    debugPrint('🔍 === DIRECT FIRESTORE TEST ===');
    
    // Check authentication
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('🔍 User authenticated: ${user != null}');
    debugPrint('🔍 User ID: ${user?.uid}');
    
    if (user == null) {
      debugPrint('❌ User not authenticated');
      return;
    }
    
    // Try to read the specific purchase directly
    debugPrint('🔍 Attempting to read purchase: $purchaseId');
    
    final doc = await FirebaseFirestore.instance
        .collection('purchases')
        .doc(purchaseId)
        .get();
    
    debugPrint('🔍 Document exists: ${doc.exists}');
    
    if (doc.exists) {
      final data = doc.data();
      debugPrint('🔍 Document data: $data');
      debugPrint('🔍 Status: ${data?['status']}');
      debugPrint('🔍 QR Code: ${data?['qrCode']}');
      debugPrint('🔍 User ID: ${data?['userId']}');
    } else {
      debugPrint('❌ Document does not exist');
      
      // List all purchases to see what's available
      final allPurchases = await FirebaseFirestore.instance
          .collection('purchases')
          .limit(5)
          .get();
      
      debugPrint('🔍 Available purchases:');
      for (final purchase in allPurchases.docs) {
        debugPrint('  - ID: ${purchase.id}, Status: ${purchase.data()['status']}');
      }
    }
    
  } catch (e) {
    debugPrint('❌ Firestore access error: $e');
    
    // Check if it's a permission error
    if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
      debugPrint('❌ This is a PERMISSION ERROR - Check your Firestore Rules!');
    }
  }
}

// Call this in your QR scanner when you scan the code:
// await testDirectFirestoreAccess('TaloKk1tVM44du6xhYDy');
  List<Widget> _buildCornerDecorations() {
    const double cornerSize = 30;
    const double cornerThickness = 4;
    final Color cornerColor = _isScanning ? Colors.green : Colors.white;

    return [
      // Top Left
      Positioned(
        top: -cornerThickness,
        left: -cornerThickness,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: cornerColor, width: cornerThickness),
              left: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
      // Top Right
      Positioned(
        top: -cornerThickness,
        right: -cornerThickness,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: cornerColor, width: cornerThickness),
              right: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
      // Bottom Left
      Positioned(
        bottom: -cornerThickness,
        left: -cornerThickness,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cornerColor, width: cornerThickness),
              left: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
      // Bottom Right
      Positioned(
        bottom: -cornerThickness,
        right: -cornerThickness,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cornerColor, width: cornerThickness),
              right: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
    ];
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isRedeemingVoucher) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? qrCodeData = barcode.rawValue;
      
      if (qrCodeData != null && qrCodeData.isNotEmpty) {
        debugPrint('🔍 QR Code detected: $qrCodeData');
        _processQRCode(qrCodeData);
        break; // Process only the first valid QR code
      }
    }
  }

  Future<void> _processQRCode(String qrCodeData) async {
    setState(() {
      _isScanning = false;
      _isRedeemingVoucher = true;
    });

    try {
      final redemptionService = Provider.of<RedemptionService>(context, listen: false);
      
      //await testDirectFirestoreAccess('TaloKk1tVM44du6xhYDy');
      // First verify the voucher
      final voucher = await redemptionService.verifyVoucher(qrCodeData);
      
      if (voucher == null) {
        _showErrorDialog(redemptionService.errorMessage ?? 'Invalid voucher');
        return;
      }

      // Check voucher status
      if (voucher.isRedeemed) {
        _showErrorDialog('This voucher has already been redeemed');
        return;
      }

      if (voucher.isExpired) {
        _showErrorDialog('This voucher has expired');
        return;
      }

      // Show confirmation dialog
      final shouldRedeem = await _showRedemptionConfirmationDialog(voucher);
      
      if (shouldRedeem) {
        // Redeem the voucher
        final redeemedVoucher = await redemptionService.redeemVoucher(qrCodeData);
        
        if (redeemedVoucher != null) {
          // Navigate to success screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => RedemptionSuccessScreen(
                  redeemedVoucher: redeemedVoucher,
                ),
              ),
            );
          }
        } else {
          _showErrorDialog(redemptionService.errorMessage ?? 'Failed to redeem voucher');
        }
      }

    } catch (e) {
      debugPrint('❌ Error processing QR code: $e');
      _showErrorDialog('Error processing voucher: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRedeemingVoucher = false;
          _isScanning = true;
        });
      }
    }
  }

  Future<bool> _showRedemptionConfirmationDialog(Purchase voucher) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Redemption'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deal: ${voucher.dealTitle}'),
              const SizedBox(height: 8),
              Text('Business: ${voucher.businessName}'),
              const SizedBox(height: 8),
              Text('Amount: \$${voucher.amount.toStringAsFixed(2)} CAD'),
              const SizedBox(height: 8),
              Text('Voucher ID: ${voucher.id.substring(0, 8).toUpperCase()}'),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to redeem this voucher?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Redeem'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isScanning = true;
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}