// Updated qr_scanner_tab.dart with navigation fixes
// Replaces all dialog calls with SnackBars to prevent Go Router conflicts

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/purchase.dart';
import '../../services/redemption_service.dart';
import 'redemption_success_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  bool _isRedeemingVoucher = false;
  String? _currentVoucherData;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              controller.toggleTorch();
            },
            icon: const Icon(Icons.flash_on, color: Colors.yellow),
          ),
          IconButton(
            onPressed: () {
              controller.switchCamera();
            },
            icon: const Icon(Icons.camera_rear, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          
          // Overlay with scanning frame
          _buildScanningOverlay(),
          
          // Status indicator
          if (_isRedeemingVoucher)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing voucher...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
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

  Widget _buildScanningOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: _isScanning ? Colors.green : Colors.grey,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _isScanning 
              ? 'Point camera at QR code'
              : 'Scanning paused',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCornerOverlays() {
    const double cornerSize = 40;
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
      _currentVoucherData = qrCodeData;
    });

    try {
      final redemptionService = Provider.of<RedemptionService>(context, listen: false);
      
      // First verify the voucher
      final voucher = await redemptionService.verifyVoucher(qrCodeData);
      
      if (voucher == null) {
        _showErrorSnackBar(redemptionService.errorMessage ?? 'Invalid voucher');
        return;
      }

      // Check voucher status
      if (voucher.isRedeemed) {
        _showErrorSnackBar('This voucher has already been redeemed');
        return;
      }

      if (voucher.isExpired) {
        _showErrorSnackBar('This voucher has expired');
        return;
      }

      // Show confirmation bottom sheet instead of dialog
      final shouldRedeem = await _showRedemptionConfirmationBottomSheet(voucher);
      
      if (shouldRedeem) {
        // Continue processing in the background while showing loading
        _redeemVoucher(qrCodeData, redemptionService);
      } else {
        // User cancelled, resume scanning
        _resumeScanning();
      }

    } catch (e) {
      debugPrint('❌ Error processing QR code: $e');
      _showErrorSnackBar('Error processing voucher: $e');
    }
  }

  Future<void> _redeemVoucher(String qrCodeData, RedemptionService redemptionService) async {
    try {
      // Redeem the voucher
      final redeemedVoucher = await redemptionService.redeemVoucher(qrCodeData);
      
      if (redeemedVoucher != null) {
        // Navigate to success screen using Go Router
        if (mounted && context.canPop()) {
          // Use Go Router navigation instead of Navigator
          context.go('/redemption-success', extra: redeemedVoucher);
        }
      } else {
        _showErrorSnackBar(redemptionService.errorMessage ?? 'Failed to redeem voucher');
      }
    } catch (e) {
      debugPrint('❌ Error redeeming voucher: $e');
      _showErrorSnackBar('Error redeeming voucher: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRedeemingVoucher = false;
          _isScanning = true;
          _currentVoucherData = null;
        });
      }
    }
  }

  Future<bool> _showRedemptionConfirmationBottomSheet(Purchase voucher) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Confirm Redemption',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Voucher details
              _buildDetailRow('Deal:', voucher.dealTitle),
              const SizedBox(height: 12),
              _buildDetailRow('Business:', voucher.businessName),
              const SizedBox(height: 12),
              _buildDetailRow('Amount:', '\$${voucher.amount.toStringAsFixed(2)} CAD'),
              const SizedBox(height: 12),
              _buildDetailRow('Voucher ID:', voucher.id.substring(0, 8).toUpperCase()),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Are you sure you want to redeem this voucher?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Redeem'),
                    ),
                  ),
                ],
              ),
              
              // Add bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
    
    return result ?? false;
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
    
    // Resume scanning after showing error
    _resumeScanning();
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resumeScanning() {
    if (mounted) {
      setState(() {
        _isRedeemingVoucher = false;
        _isScanning = true;
        _currentVoucherData = null;
      });
    }
  }
}

// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    Path oval = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, path, oval);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final borderLength = this.borderLength > cutOutSize / 2 + borderWidth * 2
        ? borderWidthSize / 2
        : this.borderLength;
    final cutOutWidth = cutOutSize + borderWidth;
    final cutOutHeight = cutOutSize + borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutWidth / 2 + borderOffset,
      rect.top + height / 2 - cutOutHeight / 2 + borderOffset,
      cutOutWidth - borderOffset * 2,
      cutOutHeight - borderOffset * 2,
    );

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final backgroundRect = Rect.fromLTWH(0, 0, rect.width, rect.height);

    // Draw overlay background
    canvas.saveLayer(backgroundRect, backgroundPaint);
    canvas.drawRect(backgroundRect, backgroundPaint);

    // Cut out the scanning area
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // Draw corner borders
    final path = Path()
      // Top left corner
      ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top + borderLength)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top)
      ..lineTo(cutOutRect.left + borderLength, cutOutRect.top)
      // Top right corner
      ..moveTo(cutOutRect.right - borderLength, cutOutRect.top)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top + borderLength)
      // Bottom right corner
      ..moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderLength)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom)
      ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom)
      // Bottom left corner
      ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}