import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/deal.dart';
import '../utils/theme.dart';

class RecentDealCard extends StatelessWidget {
  final Deal deal;
  final VoidCallback? onTap;

  const RecentDealCard({
    super.key,
    required this.deal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            _buildImage(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          NumberFormat.currency(symbol: '\$').format(deal.dealPrice),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.priceColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${deal.claimCount} claims',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.placeholderBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: deal.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: deal.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Icon(
                  Icons.image,
                  color: AppTheme.textHint,
                  size: 20,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  color: AppTheme.textHint,
                  size: 20,
                ),
              ),
            )
          : const Icon(
              Icons.image,
              color: AppTheme.textHint,
              size: 20,
            ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String status;

    if (deal.isExpired) {
      color = AppTheme.statusExpired;
      status = 'Expired';
    } else if (deal.isSoldOut) {
      color = AppTheme.statusSoldOut;
      status = 'Sold Out';
    } else if (!deal.isActive) {
      color = AppTheme.statusPaused;
      status = 'Paused';
    } else {
      color = AppTheme.statusActive;
      status = 'Active';
    }

    return Text(
      status,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}

// Deal Statistics Card for dashboard analytics
class DealStatsCard extends StatelessWidget {
  final Deal deal;
  final VoidCallback? onViewDetails;
  final VoidCallback? onBoostDeal;

  const DealStatsCard({
    super.key,
    required this.deal,
    this.onViewDetails,
    this.onBoostDeal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deal Title
            Text(
              deal.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Statistics Row 1: Views and Claims
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Views: ${deal.viewCount}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Text(
                  'Claims: ${deal.claimCount}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Conversion Rate Section
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Conversion Rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${deal.conversionRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (deal.conversionRate / 100).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.placeholderBg,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quantity Progress Section
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quantity Sold',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${deal.totalQuantity - deal.remainingQuantity} of ${deal.totalQuantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.priceColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: deal.totalQuantity > 0 
                      ? ((deal.totalQuantity - deal.remainingQuantity) / deal.totalQuantity).clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: AppTheme.placeholderBg,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.priceColor),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Revenue and Performance
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenue',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(symbol: '\$').format(deal.claimCount * deal.dealPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.priceColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Performance',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      _getPerformanceText(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getPerformanceColor(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Divider
            const Divider(),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onViewDetails,
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: (deal.isExpired || deal.isSoldOut) ? null : onBoostDeal,
                  child: const Text('Boost'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPerformanceText() {
    final conversionRate = deal.conversionRate;
    if (conversionRate >= 15.0) return 'Excellent';
    if (conversionRate >= 10.0) return 'Good';
    if (conversionRate >= 5.0) return 'Average';
    if (conversionRate > 0) return 'Poor';
    return 'No data';
  }

  Color _getPerformanceColor() {
    final conversionRate = deal.conversionRate;
    if (conversionRate >= 10.0) return AppTheme.statusActive;
    if (conversionRate >= 5.0) return AppTheme.statusPaused;
    if (conversionRate > 0) return AppTheme.statusExpired;
    return AppTheme.textHint;
  }
}