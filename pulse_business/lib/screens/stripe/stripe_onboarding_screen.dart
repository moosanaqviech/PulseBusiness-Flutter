import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business.dart';
import '../../services/stripe_connect_service.dart';
import '../../providers/business_provider.dart';
import '../../utils/theme.dart';

class StripeOnboardingScreen extends StatefulWidget {
  final bool canSkip; // Allow businesses to skip initially

  const StripeOnboardingScreen({
    super.key,
    this.canSkip = true,
  });

  @override
  State<StripeOnboardingScreen> createState() => _StripeOnboardingScreenState();
}

class _StripeOnboardingScreenState extends State<StripeOnboardingScreen> {
  bool _isProcessing = false;

  Future<void> _startOnboarding() async {
    setState(() => _isProcessing = true);

    final businessProvider = context.read<BusinessProvider>();
    final stripeService = context.read<StripeConnectService>();
    final business = businessProvider.currentBusiness;

    if (business == null) {
      _showError('Business information not found');
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // Step 1: Create Stripe Connected Account (if doesn't exist)
      String? accountId = business.stripeConnectedAccountId;
      
      if (accountId == null) {
        debugPrint('🔵 No Stripe account found, creating new one...');
        accountId = await stripeService.createConnectedAccount(
          businessId: business.id!,
          businessEmail: business.email,
          businessName: business.name,
          country: 'CA',
        );

        if (accountId == null) {
          throw Exception('Failed to create Stripe account');
        }

        // Update business with Stripe account ID
        final updatedBusiness = business.copyWith(
          stripeConnectedAccountId: accountId,
          stripeAccountStatus: 'pending',
        );
        await businessProvider.updateBusiness(updatedBusiness);
      }

      // Step 2: Generate onboarding link
      debugPrint('🔵 Generating onboarding link...');
      final onboardingUrl = await stripeService.createAccountLink(
        connectedAccountId: accountId,
        businessId: business.id!,
      );

      if (onboardingUrl == null) {
        throw Exception('Failed to generate onboarding link');
      }

      // Step 3: Launch onboarding in browser
      debugPrint('🔵 Launching onboarding...');
      final launched = await stripeService.launchOnboarding(onboardingUrl);

      if (!launched) {
        throw Exception('Failed to launch onboarding');
      }

      // Show instructions
      if (mounted) {
        _showOnboardingInstructions();
      }

    } catch (e) {
      if (mounted) {
        _showError('Error: $e');
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showOnboardingInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Setup in Browser'),
        content: const Text(
          'Please complete the Stripe setup process in your browser. '
          'Once finished, return to this app and we\'ll verify your account.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _verifyOnboarding(); // Check status
            },
            child: const Text('I\'ve Completed Setup'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOnboarding() async {
    final businessProvider = context.read<BusinessProvider>();
    final stripeService = context.read<StripeConnectService>();
    final business = businessProvider.currentBusiness;

    if (business?.stripeConnectedAccountId == null) {
      _showError('No Stripe account found');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Check account status
      final status = await stripeService.checkAccountStatus(
        business!.stripeConnectedAccountId!,
      );

      if (status == null) {
        throw Exception('Failed to check account status');
      }

      final chargesEnabled = status['chargesEnabled'] ?? false;
      final payoutsEnabled = status['payoutsEnabled'] ?? false;

      if (chargesEnabled && payoutsEnabled) {
        // Success! Update business
        final updatedBusiness = business.copyWith(
          stripeAccountOnboarded: true,
          stripePayoutsEnabled: true,
          stripeAccountStatus: 'active',
          stripeOnboardingCompletedAt: DateTime.now(),
        );
        await businessProvider.updateBusiness(updatedBusiness);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Payment setup complete!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Go back to main screen
        }
      } else {
        _showError('Setup not complete. Please finish all required steps.');
      }
    } catch (e) {
      _showError('Error verifying setup: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _skipForNow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Payment Setup?'),
        content: const Text(
          'You can create deals without payment setup, but you won\'t receive '
          'payouts until you complete this step.\n\n'
          'You can setup payments anytime from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to main
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>().currentBusiness;

    // If already onboarded, show status
    if (business?.hasActiveStripeAccount ?? false) {
      return _buildCompletedView(business!);
    }

    // Otherwise show onboarding
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Setup'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.canSkip)
            TextButton(
              onPressed: _skipForNow,
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _buildOnboardingView(),
    );
  }

  Widget _buildOnboardingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance,
              size: 80,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Setup Your Payouts',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Connect your bank account to receive payments when customers purchase your deals.',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildBenefitCard(
            icon: Icons.speed,
            title: 'Fast Payouts',
            description: 'Receive money in your account daily',
          ),
          const SizedBox(height: 16),
          _buildBenefitCard(
            icon: Icons.account_balance_wallet,
            title: 'Keep 88% of Sales',
            description: 'Only 12% platform fee - way better than competitors',
          ),
          const SizedBox(height: 16),
          _buildBenefitCard(
            icon: Icons.security,
            title: 'Bank-Level Security',
            description: 'Powered by Stripe - trusted by millions',
          ),
          const SizedBox(height: 16),
          _buildBenefitCard(
            icon: Icons.trending_up,
            title: 'Track Earnings',
            description: 'View all your payouts and sales in one place',
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _startOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Setup Payouts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/b/ba/Stripe_Logo%2C_revised_2016.svg',
                height: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Powered by Stripe',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          if (widget.canSkip) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: _skipForNow,
              child: const Text('I\'ll setup payments later'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedView(Business business) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Setup'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            const Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'Payments Setup Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You\'re all set to start receiving payouts from your deals.',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatusRow(
                      'Status',
                      'Active',
                      Colors.green,
                      Icons.check_circle,
                    ),
                    const Divider(height: 32),
                    _buildStatusRow(
                      'Payout Schedule',
                      'Daily',
                      AppTheme.primaryColor,
                      Icons.schedule,
                    ),
                    const Divider(height: 32),
                    _buildStatusRow(
                      'Account ID',
                      business.stripeConnectedAccountId!.substring(0, 20) + '...',
                      AppTheme.textSecondary,
                      Icons.info_outline,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: valueColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
