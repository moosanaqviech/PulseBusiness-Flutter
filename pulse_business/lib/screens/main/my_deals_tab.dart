import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deals_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/deal.dart';
import '../../utils/theme.dart';
import '../../widgets/my_deal_card.dart';

class MyDealsTab extends StatelessWidget {
  const MyDealsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton.icon(
            onPressed: () => _manualRefresh(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Deals'),
          ),
        ),

        _buildFilterChips(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refreshDeals(context),
            child: Consumer<DealsProvider>(
              builder: (context, dealsProvider, child) {
                if (dealsProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final deals = dealsProvider.filteredDeals;

                if (deals.isEmpty) {
                  return _buildEmptyState(context, dealsProvider);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: deals.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MyDealCard(
                        deal: deals[index],
                        onToggleActive: (deal) => _toggleDealStatus(context, deal),
                        onEdit: (deal) => _editDeal(context, deal),
                        onDelete: (deal) => _deleteDeal(context, deal),
                        onViewDetails: (deal) => _viewDealDetails(context, deal),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Consumer<DealsProvider>(
          builder: (context, dealsProvider, child) {
            return Row(
              children: [
                _buildFilterChip(
                  context,
                  'All',
                  DealFilter.all,
                  dealsProvider.currentFilter == DealFilter.all,
                  () => dealsProvider.setFilter(DealFilter.all),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Active',
                  DealFilter.active,
                  dealsProvider.currentFilter == DealFilter.active,
                  () => dealsProvider.setFilter(DealFilter.active),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Expired',
                  DealFilter.expired,
                  dealsProvider.currentFilter == DealFilter.expired,
                  () => dealsProvider.setFilter(DealFilter.expired),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Sold Out',
                  DealFilter.soldOut,
                  dealsProvider.currentFilter == DealFilter.soldOut,
                  () => dealsProvider.setFilter(DealFilter.soldOut),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    DealFilter filter,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DealsProvider dealsProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(dealsProvider.currentFilter),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              dealsProvider.getEmptyStateMessage(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            if (dealsProvider.currentFilter == DealFilter.all) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navigateToCreateDeal(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Deal'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getEmptyStateIcon(DealFilter filter) {
    switch (filter) {
      case DealFilter.active:
        return Icons.local_offer_outlined;
      case DealFilter.expired:
        return Icons.schedule_outlined;
      case DealFilter.soldOut:
        return Icons.inventory_2_outlined;
      case DealFilter.all:
      default:
        return Icons.store_outlined;
    }
  }

  Future<void> _refreshDeals(BuildContext context) async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final dealsProvider = Provider.of<DealsProvider>(context, listen: false);

    if (businessProvider.currentBusiness != null) {
      await dealsProvider.loadDeals(businessProvider.currentBusiness!.id!);
    }
  }

  Future<void> _toggleDealStatus(BuildContext context, Deal deal) async {
    if (deal.isExpired || deal.isSoldOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deal.isExpired 
                ? 'Cannot activate expired deals' 
                : 'Cannot activate sold out deals'
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final dealsProvider = Provider.of<DealsProvider>(context, listen: false);
    final success = await dealsProvider.updateDealStatus(deal.id!, !deal.isActive);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deal.isActive ? 'Deal paused' : 'Deal activated'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (context.mounted && dealsProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dealsProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editDeal(BuildContext context, Deal deal) {
    // TODO: Navigate to edit deal screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _deleteDeal(BuildContext context, Deal deal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deal'),
        content: Text(
          'Are you sure you want to delete "${deal.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final dealsProvider = Provider.of<DealsProvider>(context, listen: false);
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      
      final success = await dealsProvider.deleteDeal(deal.id!);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deal deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Update business stats
        await businessProvider.updateBusinessStats(-1);
      } else if (context.mounted && dealsProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dealsProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewDealDetails(BuildContext context, Deal deal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deal Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Title', deal.title),
              _buildDetailRow('Description', deal.description),
              _buildDetailRow('Category', deal.category.toUpperCase()),
              const SizedBox(height: 8),
              _buildDetailRow('Original Price', '\$${deal.originalPrice.toStringAsFixed(2)}'),
              _buildDetailRow('Deal Price', '\$${deal.dealPrice.toStringAsFixed(2)}'),
              _buildDetailRow('Discount', '${deal.discountPercentage}%'),
              const SizedBox(height: 8),
              _buildDetailRow('Total Quantity', '${deal.totalQuantity}'),
              _buildDetailRow('Remaining', '${deal.remainingQuantity}'),
              _buildDetailRow('Sold', '${deal.totalQuantity - deal.remainingQuantity}'),
              const SizedBox(height: 8),
              _buildDetailRow('Views', '${deal.viewCount}'),
              _buildDetailRow('Claims', '${deal.claimCount}'),
              _buildDetailRow('Conversion Rate', '${deal.conversionRate.toStringAsFixed(1)}%'),
              _buildDetailRow('Revenue', '\$${(deal.claimCount * deal.dealPrice).toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _buildDetailRow('Status', deal.status.toUpperCase()),
              _buildDetailRow('Created', deal.formattedExpirationTime),
              _buildDetailRow('Expires', deal.formattedExpirationTime),
              if (deal.termsAndConditions != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Terms', deal.termsAndConditions!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!deal.isExpired && !deal.isSoldOut)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editDeal(context, deal);
              },
              child: const Text('Edit'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateDeal(BuildContext context) {
    // Navigate to create deal tab
    final mainScreenState = context.findAncestorStateOfType<State>();
    if (mainScreenState != null) {
      // This would typically use a TabController or similar navigation
      // For now, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switch to the "Create Deal" tab to get started!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _manualRefresh(BuildContext context) async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final dealsProvider = Provider.of<DealsProvider>(context, listen: false);

    print('🔧 Manual refresh started');
    
    // First make sure business is loaded
    if (businessProvider.currentBusiness == null) {
      print('🔧 Loading business first...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await businessProvider.loadBusiness(authProvider.currentUser!.uid);
    }

    // Then load deals
    if (businessProvider.currentBusiness?.id != null) {
      print('🔧 Loading deals for business: ${businessProvider.currentBusiness!.id}');
      await dealsProvider.loadDeals(businessProvider.currentBusiness!.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${dealsProvider.allDeals.length} deals'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No business profile found'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}