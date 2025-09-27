import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/deal.dart';
import '../utils/theme.dart';

class MyDealCard extends StatelessWidget {
  final Deal deal;
  final Function(Deal) onToggleActive;
  final Function(Deal) onEdit;
  final Function(Deal) onDelete;
  final Function(Deal) onViewDetails;

  const MyDealCard({
    super.key,
    required this.deal,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => onViewDetails(deal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildImage(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 4),
                    _buildDescription(context),
                    const SizedBox(height: 8),
                    _buildPriceAndDiscount(context),
                    const SizedBox(height: 4),
                    _buildQuantityAndExpiration(context),
                    const SizedBox(height: 8),
                    _buildStats(context),
                    const SizedBox(height: 8),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 80,
      height: 80,
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
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  color: AppTheme.textHint,
                ),
              ),
            )
          : const Icon(
              Icons.image,
              color: AppTheme.textHint,
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            deal.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      deal.description,
      style: const TextStyle(
        fontSize: 14,
        color: AppTheme.textSecondary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceAndDiscount(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: NumberFormat.currency(symbol: '\$').format(deal.dealPrice),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.priceColor,
                  ),
                ),
                if (deal.originalPrice > deal.dealPrice)
                  TextSpan(
                    text: ' (was ${NumberFormat.currency(symbol: '\$').format(deal.originalPrice)})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (deal.discountPercentage > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.discountBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${deal.discountPercentage}% OFF',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityAndExpiration(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${deal.remainingQuantity} of ${deal.totalQuantity} left',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Text(
          _getExpirationText(),
          style: TextStyle(
            fontSize: 12,
            color: _getExpirationColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Views: ${deal.viewCount}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Text(
          'Claims: ${deal.claimCount}',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: () => onViewDetails(deal),
          icon: const Icon(Icons.visibility),
          iconSize: 20,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
          tooltip: 'View details',
        ),
        IconButton(
          onPressed: _canToggleActive() ? () => onToggleActive(deal) : null,
          icon: Icon(deal.isActive ? Icons.pause : Icons.play_arrow),
          iconSize: 20,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
          tooltip: deal.isActive ? 'Pause deal' : 'Activate deal',
        ),
        IconButton(
          onPressed: () => onEdit(deal),
          icon: const Icon(Icons.edit),
          iconSize: 20,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
          tooltip: 'Edit deal',
        ),
        IconButton(
          onPressed: () => onDelete(deal),
          icon: const Icon(Icons.delete),
          iconSize: 20,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
          tooltip: 'Delete deal',
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String status;

    if (deal.isExpired) {
      color = AppTheme.statusExpired;
      status = 'EXPIRED';
    } else if (deal.isSoldOut) {
      color = AppTheme.statusSoldOut;
      status = 'SOLD OUT';
    } else if (!deal.isActive) {
      color = AppTheme.statusPaused;
      status = 'PAUSED';
    } else {
      color = AppTheme.statusActive;
      status = 'ACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getExpirationText() {
    if (deal.isExpired) {
      return 'Expired';
    } else {
      return 'Expires: ${deal.timeRemaining}';
    }
  }

  Color _getExpirationColor() {
    if (deal.isExpired) {
      return Colors.red;
    }
    
    final timeRemaining = deal.timeRemaining;
    if (timeRemaining.contains('m') && !timeRemaining.contains('h')) {
      // Less than 1 hour remaining
      return Colors.red;
    } else if (timeRemaining.contains('1h') || timeRemaining.contains('2h')) {
      // 1-2 hours remaining
      return Colors.orange;
    } else {
      return AppTheme.textSecondary;
    }
  }

  bool _canToggleActive() {
    return !deal.isExpired && !deal.isSoldOut;
  }
}