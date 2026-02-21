// pulse_business/lib/widgets/deal_preview_card.dart
// Updated with tag/flair chip display

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/deal.dart';
import '../constants/deal_tags.dart';
import '../utils/theme.dart';

class DealPreviewCard extends StatelessWidget {
  final Deal deal;
  final bool showLabel;
  final File? selectedImage;

  const DealPreviewCard({
    super.key,
    required this.deal,
    this.showLabel = true,
    this.selectedImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            'Deal Preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is how your deal will appear to customers',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(context),
              _buildContentSection(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildImage(),
          ),
        ),
        
        // Discount badge (top-left)
        if (deal.discountPercentage > 0)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${deal.discountPercentage}% OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Primary tag badge (top-right) — show first tag as overlay
        if (deal.tags.isNotEmpty)
          Positioned(
            top: 12,
            right: 12,
            child: _buildOverlayTagBadge(deal.tags.first),
          ),
        
        // Favorite button (top-right, below tag if present)
        Positioned(
          top: deal.tags.isNotEmpty ? 48 : 12,
          right: 12,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: null,
              color: Colors.grey.shade400,
              iconSize: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayTagBadge(String tagId) {
    final tag = DealTags.getById(tagId);
    if (tag == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag.emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            tag.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (selectedImage != null) {
      return Image.file(
        selectedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    
    if (deal.imageUrl != null && deal.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: deal.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade100,
          child: Center(
            child: Icon(Icons.image, color: Colors.grey.shade400, size: 48),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade100,
          child: Center(
            child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 48),
          ),
        ),
      );
    }
    
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 8),
            Text(
              'Add deal image',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business name
          Text(
            deal.businessName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          // Tag chips row (horizontal scroll)
          if (deal.tags.isNotEmpty) ...[
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: deal.tags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  return _buildTagChip(deal.tags[index]);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Deal title
          Text(
            deal.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Deal description
          Text(
            deal.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Price section
          Row(
            children: [
              if (deal.originalPrice != deal.dealPrice) ...[
                Text(
                  '\$${deal.originalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '\$${deal.dealPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.priceColor,
                ),
              ),
              const Spacer(),
              // Remaining quantity
              if (deal.remainingQuantity > 0)
                Text(
                  '${deal.remainingQuantity} left',
                  style: TextStyle(
                    fontSize: 12,
                    color: deal.remainingQuantity <= 5
                        ? Colors.red
                        : Colors.grey.shade600,
                    fontWeight: deal.remainingQuantity <= 5
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tagId) {
    final tag = DealTags.getById(tagId);
    if (tag == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tag.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tag.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag.emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            tag.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tag.color,
            ),
          ),
        ],
      ),
    );
  }
}