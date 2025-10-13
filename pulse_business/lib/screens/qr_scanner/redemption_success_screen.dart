// pulse_business/lib/screens/qr_scanner/redemption_success_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../models/purchase.dart';

class RedemptionSuccessScreen extends StatelessWidget {
  final Purchase redeemedVoucher;

  const RedemptionSuccessScreen({
    super.key,
    required this.redeemedVoucher,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Redeemed'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Success Message
              const Text(
                'Voucher Successfully Redeemed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Voucher Details Card
              _buildVoucherDetailsCard(context),
              
              const SizedBox(height: 32),
              
              // Single Action Button
              _buildActionButton(context),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherDetailsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deal image or placeholder
            if (redeemedVoucher.imageUrl != null && redeemedVoucher.imageUrl!.isNotEmpty)
              Container(
                height: 150,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: redeemedVoucher.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 150,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: const Icon(
                  Icons.local_offer,
                  size: 60,
                  color: Colors.grey,
                ),
              ),
            
            // Deal title
            Text(
              redeemedVoucher.dealTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildDetailRow(
              context,
              'Business',
              redeemedVoucher.businessName,
              Colors.black87,
            ),
            
            const SizedBox(height: 12),
            
            _buildDetailRow(
              context,
              'Amount',
              '\$${redeemedVoucher.amount.toStringAsFixed(2)} CAD',
              Colors.green.shade700,
            ),
            
            const SizedBox(height: 12),
            
            _buildDetailRow(
              context,
              'Redeemed At',
              redeemedVoucher.redeemedAt != null
                ? DateFormat('MMM d, yyyy h:mm a').format(redeemedVoucher.redeemedAt!)
                : DateFormat('MMM d, yyyy h:mm a').format(DateTime.now()),
              Colors.grey.shade600,
            ),
            
            const SizedBox(height: 12),
            
            _buildDetailRow(
              context,
              'Status',
              'REDEEMED',
              Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            _buildDetailRow(
              context,
              'Voucher ID',
              redeemedVoucher.id.length >= 8 
                ? redeemedVoucher.id.substring(0, 8).toUpperCase()
                : redeemedVoucher.id.toUpperCase(),
              Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          context.go('/main');
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Continue Scanning'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, [
    Color? valueColor,
  ]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}