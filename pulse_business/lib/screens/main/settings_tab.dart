// ============================================
// NEW FILE: pulse_business/lib/screens/main/settings_tab.dart
// Minimal settings screen that's easy to extend
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../services/stripe_connect_service.dart';
import '../../utils/theme.dart';
import '../stripe/stripe_onboarding_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer<BusinessProvider>(
        builder: (context, businessProvider, child) {
          final business = businessProvider.currentBusiness;

          if (business == null) {
            return const Center(
              child: Text('No business profile found'),
            );
          }

          return ListView(
            children: [
              // Payment Setup Section
              _buildPaymentSection(context, business),
              
              const SizedBox(height: 8),
              
              // Account Section
              _buildAccountSection(context, business),
              
              const SizedBox(height: 8),
              
              // App Section
              _buildAppSection(context),
              
              const SizedBox(height: 24),
              
              // Logout Button
              _buildLogoutButton(context),
              
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // ============================================
  // PAYMENT SETUP SECTION (Stripe Connect)
  // ============================================
  Widget _buildPaymentSection(BuildContext context, Business business) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'PAYMENT SETUP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          _buildPaymentSetupTile(context, business),
        ],
      ),
    );
  }

  Widget _buildPaymentSetupTile(BuildContext context, Business business) {
    if (business.hasActiveStripeAccount) {
      // Payment setup complete
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ),
        title: const Text(
          'Payment Setup',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('Active • Daily payouts'),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StripeOnboardingScreen(canSkip: false),
            ),
          );
        },
      );
    } else {
      // Payment setup incomplete - show prominent banner
      return Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              ),
              title: const Text(
                'Payment Setup Required',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: const Text(
                'Setup payouts to start earning from your deals',
                style: TextStyle(fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StripeOnboardingScreen(canSkip: false),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(
                    'Setup Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // ============================================
  // ACCOUNT SECTION
  // ============================================
  Widget _buildAccountSection(BuildContext context, Business business) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Business Profile'),
            subtitle: Text(business.name),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // TODO: Navigate to business profile edit screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(business.email),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // TODO: Navigate to email settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email settings coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone'),
            subtitle: Text(business.phoneNumber),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // TODO: Navigate to phone settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone settings coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================
  // APP SECTION
  // ============================================
  Widget _buildAppSection(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'APP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Push notifications, email alerts'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // TODO: Navigate to notification settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // TODO: Navigate to help screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help center coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0 (Beta)'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  // ============================================
  // LOGOUT BUTTON
  // ============================================
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.logout),
          label: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // DIALOGS
  // ============================================
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Pulse Business'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pulse Business helps local businesses create and manage deals to attract more customers.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Version: 1.0.0 (Beta)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '© 2025 Pulse',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// UPDATE: pulse_business/lib/screens/main/main_screen.dart
// Replace the placeholder in _tabs list
// ============================================

// BEFORE (in your current main_screen.dart):
// final List<Widget> _tabs = [
//   const SmartTemplatesTab(),
//   const EnhancedDealCreationScreen(),
//   const QRScannerScreen(),
//   const MyDealsTab(),
//   // const SettingsScreen(),  // ← This was commented out
// ];

// AFTER:
// 1. Add import at the top:
// import 'settings_tab.dart';

// 2. Update _tabs list:
// final List<Widget> _tabs = [
//   const SmartTemplatesTab(),
//   const EnhancedDealCreationScreen(),
//   const QRScannerScreen(),
//   const MyDealsTab(),
//   const SettingsTab(),  // ← Add this
// ];

// That's it! The settings screen will now work when users tap the Settings tab.