// Create this as: pulse_business/lib/widgets/deal_preview_card.dart
// This matches the EXACT layout of the consumer app's DealCard

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/deal.dart';
import '../utils/theme.dart';

class DealPreviewCard extends StatelessWidget {
  final Deal deal;
  final bool showLabel;
  final File? selectedImage; // For preview mode

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
        
        // EXACT REPLICA OF CONSUMER DEAL CARD
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
        
        // Favorite button (top-right) - disabled in preview
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: null, // Disabled in preview
              color: Colors.grey.shade400,
              iconSize: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    // If we have a selected image from image picker (preview mode)
    if (selectedImage != null) {
      return Image.file(
        selectedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    
    // If deal has an image URL
    if (deal.imageUrl != null && deal.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: deal.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade100,
          child: Center(
            child: Icon(
              Icons.image,
              color: Colors.grey.shade400,
              size: 48,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade100,
          child: Center(
            child: Icon(
              Icons.broken_image,
              color: Colors.grey.shade400,
              size: 48,
            ),
          ),
        ),
      );
    }
    
    // Placeholder when no image
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              color: Colors.grey.shade400,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Add deal image',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              
              // Distance (placeholder in preview)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '0.5 mi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Bottom info row
          Row(
            children: [
              // Expiration
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                _getTimeRemaining(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              
              // Quantity remaining
              Text(
                '${deal.remainingQuantity} left',
                style: TextStyle(
                  fontSize: 12,
                  color: deal.remainingQuantity < 5 ? Colors.red.shade600 : Colors.grey.shade600,
                  fontWeight: deal.remainingQuantity < 5 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeRemaining() {
    final now = DateTime.now();
    final difference = deal.expirationTime.difference(now);
    
    if (difference.inDays > 0) {
      return 'Expires in ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'Expires in ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Expires in ${difference.inMinutes}m';
    } else {
      return 'Expired';
    }
  }
}