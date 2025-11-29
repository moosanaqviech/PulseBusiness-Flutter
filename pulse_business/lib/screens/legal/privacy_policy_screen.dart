// Create: pulse_business/lib/screens/legal/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pulse Business - Privacy Policy',
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
            'Our Commitment to Privacy',
            'Pulse ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our business platform.',
          ),

          _buildSection(
            '1. Information We Collect',
            'Business Information:\n'
            '• Business name, address, and contact details\n'
            '• Business category and description\n'
            '• Business hours and location data\n'
            '• Business images and branding\n\n'
            'Account Information:\n'
            '• Email address and password\n'
            '• User ID and authentication data\n'
            '• Profile preferences\n\n'
            'Financial Information:\n'
            '• Stripe Connect account details\n'
            '• Bank account information (stored by Stripe)\n'
            '• Transaction history\n\n'
            'Usage Data:\n'
            '• App usage statistics\n'
            '• Deal performance metrics\n'
            '• Device information and IP address\n'
            '• Log data and analytics',
          ),

          _buildSection(
            '2. How We Use Your Information',
            'We use your information to:\n'
            '• Provide and maintain the Pulse platform\n'
            '• Process payments and transactions\n'
            '• Display your business to customers\n'
            '• Send important updates and notifications\n'
            '• Improve our services and user experience\n'
            '• Prevent fraud and ensure security\n'
            '• Comply with legal obligations\n'
            '• Provide customer support',
          ),

          _buildSection(
            '3. Information Sharing',
            'We may share your information with:\n\n'
            'Service Providers:\n'
            '• Firebase (Google) - database and authentication\n'
            '• Stripe - payment processing\n'
            '• Google Cloud - hosting and storage\n\n'
            'Customers:\n'
            '• Your business name, description, location\n'
            '• Deal information and pricing\n'
            '• Business hours and contact info\n\n'
            'Legal Requirements:\n'
            '• When required by law or legal process\n'
            '• To protect rights and safety\n'
            '• In connection with business transfers\n\n'
            'We do NOT sell your personal information to third parties.',
          ),

          _buildSection(
            '4. Data Security',
            'We implement industry-standard security measures:\n'
            '• Encryption of data in transit and at rest\n'
            '• Secure authentication via Firebase\n'
            '• PCI-compliant payment processing via Stripe\n'
            '• Regular security audits and updates\n'
            '• Access controls and monitoring\n\n'
            'However, no method of transmission over the internet is 100% secure.',
          ),

          _buildSection(
            '5. Data Retention',
            'We retain your information:\n'
            '• As long as your account is active\n'
            '• As needed to provide services\n'
            '• To comply with legal obligations\n'
            '• To resolve disputes and enforce agreements\n\n'
            'You can request deletion of your account and data at any time.',
          ),

          _buildSection(
            '6. Your Rights',
            'You have the right to:\n'
            '• Access your personal information\n'
            '• Correct inaccurate data\n'
            '• Request deletion of your data\n'
            '• Opt-out of marketing communications\n'
            '• Export your data\n'
            '• Withdraw consent\n\n'
            'Contact us at privacy@checkpulse.shop to exercise these rights.',
          ),

          _buildSection(
            '7. Cookies and Tracking',
            'We use cookies and similar technologies to:\n'
            '• Maintain your session\n'
            '• Remember your preferences\n'
            '• Analyze platform usage\n'
            '• Improve user experience\n\n'
            'You can control cookies through your browser settings.',
          ),

          _buildSection(
            '8. Third-Party Services',
            'Our platform integrates with:\n'
            '• Google Firebase - Privacy Policy: firebase.google.com/support/privacy\n'
            '• Stripe - Privacy Policy: stripe.com/privacy\n'
            '• Google Maps - Privacy Policy: policies.google.com/privacy\n\n'
            'These services have their own privacy policies.',
          ),

          _buildSection(
            '9. Children\'s Privacy',
            'Pulse is not intended for users under 18. We do not knowingly collect information from children. If you believe we have collected data from a minor, please contact us immediately.',
          ),

          _buildSection(
            '10. International Data Transfers',
            'Your information may be transferred to and processed in countries outside your own. We ensure appropriate safeguards are in place for such transfers.',
          ),

          _buildSection(
            '11. California Privacy Rights (CCPA)',
            'California residents have additional rights:\n'
            '• Right to know what personal information is collected\n'
            '• Right to delete personal information\n'
            '• Right to opt-out of sale (we don\'t sell data)\n'
            '• Right to non-discrimination\n\n'
            'Contact privacy@checkpulse.shop to exercise these rights.',
          ),

          _buildSection(
            '12. Changes to Privacy Policy',
            'We may update this Privacy Policy periodically. We will notify you of material changes via email or app notification. Continued use after changes constitutes acceptance.',
          ),

          _buildSection(
            '13. Contact Us',
            'For privacy-related questions or concerns:\n\n'
            'Email: privacy@checkpulse.shop\n'
            'Support: support@checkpulse.shop\n'
            'Website: checkpulse.shop\n'
            'Address: Toronto, Ontario, Canada',
          ),

          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Your Privacy Matters',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'We are committed to protecting your privacy and handling your data responsibly. If you have any concerns, please don\'t hesitate to contact us.',
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