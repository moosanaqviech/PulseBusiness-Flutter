// Create: pulse_business/lib/screens/legal/terms_of_service_screen.dart

import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pulse Business - Terms of Service',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last Updated: ${DateTime.now().toString().substring(0, 10)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          _buildSection(
            '1. Agreement to Terms',
            'By accessing and using Pulse Business ("the Platform"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
          ),

          _buildSection(
            '2. Eligibility',
            'You must:\n'
            '• Be at least 18 years old\n'
            '• Have legal authority to enter into these terms\n'
            '• Operate a legitimate business with proper licensing\n'
            '• Provide accurate and complete information',
          ),

          _buildSection(
            '3. Prohibited Business Types',
            'The following businesses are strictly prohibited from using Pulse:\n\n'
            '• Alcohol sales or alcoholic beverage services\n'
            '• Gambling, betting, or lottery services\n'
            '• Cannabis or cannabis-related products\n'
            '• Tobacco or vaping products\n'
            '• Adult entertainment or services\n'
            '• Illegal activities or fraudulent services\n\n'
            'Violation of this section will result in immediate account termination.',
          ),

          _buildSection(
            '4. Business Responsibilities',
            'As a business on Pulse, you agree to:\n'
            '• Honor all deals and vouchers sold through the platform\n'
            '• Maintain accurate business information\n'
            '• Respond to customer inquiries promptly\n'
            '• Comply with all local laws and regulations\n'
            '• Not discriminate against customers\n'
            '• Provide quality products/services as advertised',
          ),

          _buildSection(
            '5. Deal Terms',
            '• Deals must clearly state terms, conditions, and expiration\n'
            '• You cannot refuse valid, unexpired vouchers\n'
            '• Prices must be accurate and not misleading\n'
            '• You are responsible for inventory management\n'
            '• Pulse reserves the right to remove deals that violate policies',
          ),

          _buildSection(
            '6. Commission & Payments',
            '• Pulse charges 8-12% commission on each transaction\n'
            '• Payments are processed via Stripe Connect\n'
            '• Payouts occur on a rolling 2-day basis after redemption\n'
            '• You are responsible for all applicable taxes\n'
            '• Refunds may be issued according to our refund policy',
          ),

          _buildSection(
            '7. Intellectual Property',
            '• You retain ownership of your business content and branding\n'
            '• You grant Pulse license to display your content on the platform\n'
            '• You must have rights to all images and content you upload\n'
            '• Pulse owns all platform technology and trademarks',
          ),

          _buildSection(
            '8. Account Termination',
            'Pulse may suspend or terminate your account for:\n'
            '• Violation of these terms\n'
            '• Fraudulent activity\n'
            '• Selling prohibited items\n'
            '• Poor customer service or excessive complaints\n'
            '• Non-payment of fees\n\n'
            'You may close your account at any time from settings.',
          ),

          _buildSection(
            '9. Limitation of Liability',
            'Pulse is not liable for:\n'
            '• Lost profits or revenue\n'
            '• Customer disputes\n'
            '• Technical issues or downtime\n'
            '• Third-party actions\n\n'
            'Our maximum liability is limited to fees paid in the last 12 months.',
          ),

          _buildSection(
            '10. Changes to Terms',
            'We may update these terms at any time. Continued use of the platform after changes constitutes acceptance of new terms. We will notify you of material changes via email.',
          ),

          _buildSection(
            '11. Governing Law',
            'These terms are governed by the laws of Ontario, Canada. Any disputes will be resolved in Toronto courts.',
          ),

          _buildSection(
            '12. Contact Information',
            'For questions about these terms:\n\n'
            'Email: legal@checkpulse.shop\n'
            'Website: checkpulse.shop\n'
            'Address: Toronto, Ontario, Canada',
          ),

          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Questions?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you have any questions about these terms, please contact our support team.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}