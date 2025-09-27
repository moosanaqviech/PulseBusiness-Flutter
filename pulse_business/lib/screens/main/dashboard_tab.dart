import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/business_provider.dart';
import '../../providers/deals_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/deal_card.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const SizedBox(height: 16),
            _buildQuickStatsCard(context),
            const SizedBox(height: 16),
            _buildPerformanceCard(context),
            const SizedBox(height: 16),
            _buildRecentDealsCard(context),
            const SizedBox(height: 16),
            _buildQuickActionsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        final businessName = businessProvider.currentBusiness?.name ?? 'Business Owner';
        final currentHour = DateTime.now().hour;
        String greeting;
        
        if (currentHour < 12) {
          greeting = 'Good Morning';
        } else if (currentHour < 17) {
          greeting = 'Good Afternoon';
        } else {
          greeting = 'Good Evening';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              businessName,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getMotivationalMessage(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  String _getMotivationalMessage() {
    final messages = [
      "Let's make today profitable! 💰",
      "Your business is growing! 📈",
      "Time to create some amazing deals! ✨",
      "Ready to boost your sales? 🚀",
      "Let's attract more customers today! 🎯",
    ];
    final random = DateTime.now().millisecondsSinceEpoch % messages.length;
    return messages[random];
  }

  Widget _buildQuickStatsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<DealsProvider>(
              builder: (context, dealsProvider, child) {
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildStatItem(
                          context,
                          'Active Deals',
                          dealsProvider.totalActiveDeals.toString(),
                          AppTheme.primaryColor,
                          Icons.local_offer,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          context,
                          'Total Views',
                          NumberFormat.compact().format(dealsProvider.totalViews),
                          AppTheme.accentColor,
                          Icons.visibility,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatItem(
                          context,
                          'Claims Today',
                          NumberFormat.compact().format(dealsProvider.totalClaims),
                          AppTheme.priceColor,
                          Icons.shopping_cart,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          context,
                          'Revenue',
                          NumberFormat.compactCurrency(symbol: '\$').format(dealsProvider.totalRevenue),
                          AppTheme.priceColor,
                          Icons.attach_money,
                          isRevenue: true,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, 
    String label, 
    String value, 
    Color color, 
    IconData icon,
    {bool isRevenue = false}
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isRevenue ? 16 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(width: 12);
  }

  Widget _buildPerformanceCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Metrics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<DealsProvider>(
              builder: (context, dealsProvider, child) {
                return Column(
                  children: [
                    _buildPerformanceMetric(
                      context,
                      'Conversion Rate',
                      '${dealsProvider.conversionRate.toStringAsFixed(1)}%',
                      dealsProvider.conversionRate / 100,
                      AppTheme.primaryColor,
                      Icons.abc,
                    ),
                    const SizedBox(height: 16),
                    _buildPerformanceMetric(
                      context,
                      'Average Discount',
                      '${dealsProvider.averageDiscount.toStringAsFixed(0)}%',
                      (dealsProvider.averageDiscount / 100).clamp(0.0, 1.0),
                      AppTheme.discountBg,
                      Icons.percent,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(
    BuildContext context,
    String label,
    String value,
    double progress,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: AppTheme.placeholderBg,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildRecentDealsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recent Deals',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToMyDeals(context),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<DealsProvider>(
              builder: (context, dealsProvider, child) {
                final recentDeals = dealsProvider.recentDeals;
                
                if (dealsProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (recentDeals.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No deals yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first deal to get started!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToCreateDeal(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Deal'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: recentDeals.map((deal) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RecentDealCard(
                        deal: deal,
                        onTap: () => _viewDealDetails(context, deal),
                      ),
                    )
                  ).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionButton(
                  context,
                  'Create Deal',
                  Icons.add_circle,
                  AppTheme.primaryColor,
                  () => _navigateToCreateDeal(context),
                ),
                _buildQuickActionButton(
                  context,
                  'View Analytics',
                  Icons.analytics,
                  AppTheme.accentColor,
                  () => _showAnalytics(context),
                ),
                _buildQuickActionButton(
                  context,
                  'Edit Profile',
                  Icons.edit,
                  Colors.orange,
                  () => _editProfile(context),
                ),
                _buildQuickActionButton(
                  context,
                  'Share Business',
                  Icons.share,
                  Colors.green,
                  () => _shareBusiness(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData(BuildContext context) async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final dealsProvider = Provider.of<DealsProvider>(context, listen: false);

    if (businessProvider.currentBusiness != null) {
      await Future.wait([
        businessProvider.loadBusiness(businessProvider.currentBusiness!.ownerId),
        dealsProvider.loadDeals(businessProvider.currentBusiness!.id!),
      ]);
    }
  }

  void _navigateToCreateDeal(BuildContext context) {
    // Navigate to create deal tab (index 1)
    final mainScreenState = context.findAncestorStateOfType<State>();
    if (mainScreenState != null) {
      // This would use a callback to parent or tab controller
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switch to the "Create Deal" tab to get started!'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  void _navigateToMyDeals(BuildContext context) {
    // Navigate to my deals tab (index 2)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Switch to the "My Deals" tab to view all deals!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _viewDealDetails(BuildContext context, deal) {
    // Show deal details in a modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deal.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: \$${deal.dealPrice.toStringAsFixed(2)}'),
            Text('Views: ${deal.viewCount}'),
            Text('Claims: ${deal.claimCount}'),
            Text('Status: ${deal.status.toUpperCase()}'),
            const SizedBox(height: 8),
            Text(
              deal.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAnalytics(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detailed analytics feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit profile feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _shareBusiness(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share business feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}