// lib/services/template_transformation_service.dart
// Complete Template Transformation Service - Transforms deal structure templates into existing Deal model

import 'package:flutter/foundation.dart';
import '../models/business.dart';
import '../models/deal.dart';
import '../models/deal_structure_templates.dart';
import 'context_analyzer.dart';

class TemplateTransformationService {
  static final TemplateTransformationService _instance = TemplateTransformationService._internal();
  factory TemplateTransformationService() => _instance;
  TemplateTransformationService._internal();
  
  final ContextAnalyzer _contextAnalyzer = ContextAnalyzer();
  
  /// Transform template data into a Deal object
  /// This is the key method that bridges new templates to existing Deal model
  Deal transformToDeal({
    required DealStructureTemplate template,
    required Map<String, dynamic> templateData,
    required Business business,
    DateTime? customStartTime,
  }) {
    // Analyze context for smart enhancements
    final context = _contextAnalyzer.analyzeContext(business, customTime: customStartTime);
    
    // Get smart defaults and merge with user data
    final smartDefaults = template.getSmartDefaults(business, context);
    final finalData = {...smartDefaults, ...templateData};
    
    // Transform based on template type
    switch (template.id) {
      case 'percentage_off':
        return _transformPercentageOffToDeal(finalData, business, context, customStartTime);
      
      // Future templates will be added here
      case 'bogo':
        return _transformBOGOToDeal(finalData, business, context, customStartTime);
      case 'flash_sale':
        return _transformFlashSaleToDeal(finalData, business, context, customStartTime);
      
      default:
        throw Exception('Unknown template type: ${template.id}');
    }
  }
  
  /// Transform Percentage Off template to Deal
  Deal _transformPercentageOffToDeal(
    Map<String, dynamic> data,
    Business business,
    TemplateContext context,
    DateTime? customStartTime,
  ) {
    // Extract template data
    final discountPercentage = data['discount_percentage'] ?? 20;
    final originalPrice = data['original_price'] ?? 15.99;
    final minPurchase = data['minimum_purchase'];
    final maxDiscount = data['maximum_discount'];
    final excludedCategories = data['excluded_categories'] ?? <String>[];
    
    // Calculate deal price
    double dealPrice = originalPrice * (1 - discountPercentage / 100);
    
    // Apply maximum discount cap if specified
    if (maxDiscount != null) {
      final actualDiscount = originalPrice - dealPrice;
      if (actualDiscount > maxDiscount) {
        dealPrice = originalPrice - maxDiscount;
      }
    }
    
    // Generate context-aware content
    final contentData = _generateContextAwareContent(data, business, context);
    
    // Determine timing
    final timing = _getOptimalTiming(data, context, customStartTime);
    
    // Calculate optimal quantity based on context
    final quantity = _calculateOptimalQuantity(business, context);
    
    // Generate terms and conditions
    final terms = _generateTermsAndConditions(data, context, excludedCategories);
    
    return Deal(
      title: contentData['title']!,
      description: contentData['description']!,
      category: business.category,
      latitude: business.latitude,
      longitude: business.longitude,
      originalPrice: originalPrice,
      dealPrice: dealPrice,
      totalQuantity: quantity,
      remainingQuantity: quantity,
      businessId: business.id!,
      businessName: business.name,
      startTime: timing['startTime'],
      expirationTime: timing['expirationTime'],
      termsAndConditions: terms,
      isActive: timing['isActive'],
      isScheduled: timing['isScheduled'],
      createdAt: DateTime.now(),
      // Additional metadata for tracking
     
    );
  }
  
  /// Generate context-aware content (title, description)
  Map<String, String> _generateContextAwareContent(
    Map<String, dynamic> data,
    Business business,
    TemplateContext context,
  ) {
    final discountPercentage = data['discount_percentage'] ?? 20;
    final originalPrice = data['original_price'] ?? 15.99;
    final dealPrice = originalPrice * (1 - discountPercentage / 100);
    
    String title;
    String description;
    
    // Use suggested content from context if available and confidence is high
    if (context.confidence > 0.6 && data['suggested_title'] != null) {
      title = data['suggested_title'];
      description = data['suggested_description'];
    } else {
      // Generate generic content based on context
      switch (context.detectedContext) {
        case 'happy_hour':
          title = '${business.name} Happy Hour - ${discountPercentage}% Off!';
          description = 'Join us for Happy Hour! Enjoy ${discountPercentage}% off drinks and appetizers. Perfect way to unwind after work with colleagues and friends.';
          break;
        case 'lunch_special':
          title = 'Express Lunch Special - ${discountPercentage}% Off';
          description = 'Quick and delicious lunch deals for busy professionals! Get ${discountPercentage}% off our lunch menu items. Fast service guaranteed.';
          break;
        case 'weekend_special':
          title = 'Weekend Special - ${discountPercentage}% Off!';
          description = 'Make your weekend extra special! Enjoy ${discountPercentage}% off and relax with friends and family at ${business.name}.';
          break;
        case 'morning_rush':
          title = 'Morning Fuel Special - ${discountPercentage}% Off';
          description = 'Start your day right! Get ${discountPercentage}% off coffee and breakfast items. Perfect for your morning routine.';
          break;
        default:
          title = '${discountPercentage}% Off Special at ${business.name}';
          description = 'Great savings await! Enjoy ${discountPercentage}% off regular prices. Was \$${originalPrice.toStringAsFixed(2)}, now only \$${dealPrice.toStringAsFixed(2)}!';
      }
    }
    
    return {
      'title': title,
      'description': description,
    };
  }
  
  /// Determine optimal timing based on context
  Map<String, dynamic> _getOptimalTiming(
    Map<String, dynamic> data,
    TemplateContext context,
    DateTime? customStartTime,
  ) {
    final now = DateTime.now();
    DateTime startTime;
    DateTime expirationTime;
    bool isScheduled = false;
    bool isActive = true;
    
    if (customStartTime != null) {
      // User specified custom start time
      startTime = customStartTime;
      isScheduled = true;
      isActive = false;
    } else if (context.confidence > 0.6 && data['suggested_timing'] != null) {
      // Use context-suggested timing
      final timing = data['suggested_timing'];
      startTime = _parseTimeToToday(timing['start_time']);
      
      // If start time has passed today, schedule for tomorrow
      if (startTime.isBefore(now)) {
        startTime = startTime.add(Duration(days: 1));
        isScheduled = true;
        isActive = false;
      }
    } else {
      // Default to immediate start
      startTime = now;
    }
    
    // Calculate expiration based on context
    if (context.detectedContext == 'happy_hour') {
      // Happy hour typically runs for 3 hours
      expirationTime = startTime.add(Duration(hours: 3));
    } else if (context.detectedContext == 'lunch_special') {
      // Lunch special runs for 3 hours
      expirationTime = startTime.add(Duration(hours: 3));
    } else if (context.detectedContext == 'morning_rush') {
      // Morning rush for 2.5 hours
      expirationTime = startTime.add(Duration(hours: 2, minutes: 30));
    } else if (context.detectedContext == 'flash_sale') {
      // Flash sale for 4 hours
      expirationTime = startTime.add(Duration(hours: 4));
    } else {
      // Default duration: 1 week
      expirationTime = startTime.add(Duration(days: 7));
    }
    
    return {
      'startTime': startTime,
      'expirationTime': expirationTime,
      'isScheduled': isScheduled,
      'isActive': isActive,
    };
  }
  
  /// Calculate optimal quantity based on business and context
  int _calculateOptimalQuantity(Business business, TemplateContext context) {
    int baseQuantity;
    
    // Base quantity by business type
    switch (business.category.toLowerCase()) {
      case 'restaurant':
        baseQuantity = 30;
        break;
      case 'cafe':
        baseQuantity = 40;
        break;
      case 'bar':
        baseQuantity = 25;
        break;
      case 'shop':
        baseQuantity = 20;
        break;
      default:
        baseQuantity = 25;
    }
    
    // Adjust based on context
    switch (context.detectedContext) {
      case 'happy_hour':
        return (baseQuantity * 1.2).round(); // 20% more for popular time
      case 'morning_rush':
        return (baseQuantity * 1.5).round(); // 50% more for high volume
      case 'lunch_special':
        return (baseQuantity * 1.3).round(); // 30% more for lunch rush
      case 'flash_sale':
        return (baseQuantity * 0.4).round(); // Lower quantity for urgency
      case 'weekend_special':
        return (baseQuantity * 0.8).round(); // Slightly lower for leisure pace
      default:
        return baseQuantity;
    }
  }
  
  /// Generate appropriate terms and conditions
  String _generateTermsAndConditions(
    Map<String, dynamic> data,
    TemplateContext context,
    List<String> excludedCategories,
  ) {
    final terms = <String>[];
    
    // Context-specific terms
    if (data['suggested_terms'] != null) {
      terms.add(data['suggested_terms']);
    } else {
      switch (context.detectedContext) {
        case 'happy_hour':
          terms.add('Valid Monday-Friday 4:00 PM - 7:00 PM only');
          terms.add('Dine-in only');
          break;
        case 'lunch_special':
          terms.add('Valid Monday-Friday 11:30 AM - 2:30 PM only');
          terms.add('Dine-in or takeout');
          break;
        case 'morning_rush':
          terms.add('Valid weekdays 7:00 AM - 9:30 AM only');
          terms.add('One per customer');
          break;
        case 'weekend_special':
          terms.add('Valid Saturday and Sunday only');
          break;
        case 'flash_sale':
          terms.add('Limited time offer');
          terms.add('While supplies last');
          break;
      }
    }
    
    // Minimum purchase terms
    final minPurchase = data['minimum_purchase'];
    if (minPurchase != null && minPurchase > 0) {
      terms.add('Minimum purchase of \$${minPurchase.toStringAsFixed(2)} required');
    }
    
    // Maximum discount terms
    final maxDiscount = data['maximum_discount'];
    if (maxDiscount != null && maxDiscount > 0) {
      terms.add('Maximum discount of \$${maxDiscount.toStringAsFixed(2)} per transaction');
    }
    
    // Excluded categories
    if (excludedCategories.isNotEmpty) {
      final excludedText = excludedCategories.map(_formatExcludedCategory).join(', ');
      terms.add('Excludes: $excludedText');
    }
    
    // Standard terms
    terms.add('Cannot be combined with other offers');
    terms.add('One per customer per visit');
    
    return terms.join('. ') + '.';
  }
  
  String _formatExcludedCategory(String category) {
    switch (category) {
      case 'alcohol':
        return 'alcoholic beverages';
      case 'tobacco':
        return 'tobacco products';
      case 'gift_cards':
        return 'gift cards';
      case 'sale_items':
        return 'already discounted items';
      default:
        return category.replaceAll('_', ' ');
    }
  }
  
  /// Parse time string to today's date
  DateTime _parseTimeToToday(String timeString) {
    final now = DateTime.now();
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
  
  /// Future: Transform BOGO template (placeholder for future implementation)
  Deal _transformBOGOToDeal(
    Map<String, dynamic> data,
    Business business,
    TemplateContext context,
    DateTime? customStartTime,
  ) {
    // This would be implemented when BOGO template is added
    // For now, create a basic percentage off deal as fallback
    
    return Deal(
      title: 'Buy One Get One Free!',
      description: 'Bring a friend and get double the value! Buy any item and get a second one absolutely free.',
      category: business.category,
      latitude: business.latitude,
      longitude: business.longitude,
      originalPrice: data['item_price'] ?? 15.99,
      dealPrice: (data['item_price'] ?? 15.99) * 0.5, // Effectively 50% off for BOGO
      totalQuantity: 20,
      remainingQuantity: 20,
      businessId: business.id!,
      businessName: business.name,
      
      startTime: customStartTime ?? DateTime.now(),
      expirationTime: (customStartTime ?? DateTime.now()).add(Duration(days: 7)),
      termsAndConditions: 'Free item must be of equal or lesser value. One per customer. Cannot be combined with other offers.',
      isActive: customStartTime == null,
      isScheduled: customStartTime != null,
      createdAt: DateTime.now(),
    
    );
  }
  
  /// Future: Transform Flash Sale template (placeholder for future implementation)
  Deal _transformFlashSaleToDeal(
    Map<String, dynamic> data,
    Business business,
    TemplateContext context,
    DateTime? customStartTime,
  ) {
    // This would be implemented when Flash Sale template is added
    final discountPercentage = data['discount_percentage'] ?? 40; // Higher discount for flash sales
    final originalPrice = data['original_price'] ?? 25.99;
    final dealPrice = originalPrice * (1 - discountPercentage / 100);
    
    return Deal(
      title: 'FLASH SALE - ${discountPercentage}% OFF!',
      description: 'Lightning deal! Massive savings for the next few hours only. Don\'t miss out on these incredible prices!',
      category: business.category,
      latitude: business.latitude,
      longitude: business.longitude,
      originalPrice: originalPrice,
      dealPrice: dealPrice,
      totalQuantity: 10, // Limited quantity for urgency
      remainingQuantity: 10,
      businessId: business.id!,
      businessName: business.name,
     
      startTime: customStartTime ?? DateTime.now(),
      expirationTime: (customStartTime ?? DateTime.now()).add(Duration(hours: 4)), // Short duration
      termsAndConditions: 'Extremely limited time. While supplies last. No rain checks. Final sale.',
      isActive: customStartTime == null,
      isScheduled: customStartTime != null,
      createdAt: DateTime.now(),
     
    );
  }
  
  /// Get performance prediction for template + context combination
  Map<String, dynamic> getPerformancePrediction(
    DealStructureTemplate template,
    TemplateContext context,
    Business business,
  ) {
    final predictions = <String, dynamic>{};
    
    // Base conversion rates by template type
    final baseConversions = {
      'percentage_off': 25.0,
      'bogo': 35.0,
      'flash_sale': 45.0,
      'combo_deal': 30.0,
    };
    
    double expectedConversion = baseConversions[template.id] ?? 25.0;
    
    // Context multipliers
    if (context.confidence > 0.6) {
      switch (context.detectedContext) {
        case 'happy_hour':
          expectedConversion *= 1.3; // 30% boost for happy hour
          break;
        case 'morning_rush':
          expectedConversion *= 1.65; // 65% boost for morning rush
          break;
        case 'lunch_special':
          expectedConversion *= 1.15; // 15% boost for lunch
          break;
        case 'flash_sale':
          expectedConversion *= 1.8; // 80% boost for flash sales
          break;
        case 'weekend_special':
          expectedConversion *= 0.97; // Slightly lower weekend conversion
          break;
      }
    }
    
    // Business type adjustments
    switch (business.category.toLowerCase()) {
      case 'cafe':
        expectedConversion *= 1.1; // Cafes typically see higher conversion
        break;
      case 'bar':
        expectedConversion *= 0.9; // Bars slightly lower
        break;
      case 'restaurant':
        expectedConversion *= 1.05; // Restaurants slightly higher
        break;
      case 'shop':
        expectedConversion *= 0.95; // Retail slightly lower
        break;
    }
    
    predictions['expectedConversion'] = expectedConversion.clamp(10.0, 80.0);
    predictions['confidenceLevel'] = context.confidence;
    predictions['estimatedReach'] = _estimateReach(business, context);
    predictions['recommendationStrength'] = _getRecommendationStrength(context.confidence);
    predictions['optimalTiming'] = _getOptimalTimingDescription(context);
    predictions['estimatedRevenue'] = _estimateRevenue(business, context, expectedConversion);
    
    return predictions;
  }
  
  int _estimateReach(Business business, TemplateContext context) {
    int baseReach = 100; // Base estimated reach
    
    // Adjust by business type
    switch (business.category.toLowerCase()) {
      case 'restaurant':
        baseReach = 150;
        break;
      case 'cafe':
        baseReach = 200;
        break;
      case 'bar':
        baseReach = 120;
        break;
      case 'shop':
        baseReach = 80;
        break;
    }
    
    // Adjust by context
    switch (context.detectedContext) {
      case 'happy_hour':
        baseReach = (baseReach * 1.4).round();
        break;
      case 'morning_rush':
        baseReach = (baseReach * 1.6).round();
        break;
      case 'lunch_special':
        baseReach = (baseReach * 1.2).round();
        break;
      case 'weekend_special':
        baseReach = (baseReach * 0.8).round();
        break;
      case 'flash_sale':
        baseReach = (baseReach * 2.0).round(); // Flash sales get wider reach
        break;
    }
    
    return baseReach;
  }
  
  String _getRecommendationStrength(double confidence) {
    if (confidence >= 0.8) return 'Highly Recommended';
    if (confidence >= 0.6) return 'Recommended';
    if (confidence >= 0.4) return 'Good Option';
    return 'Consider Alternatives';
  }
  
  String _getOptimalTimingDescription(TemplateContext context) {
    switch (context.detectedContext) {
      case 'happy_hour':
        return 'Monday-Friday, 4:00 PM - 7:00 PM';
      case 'morning_rush':
        return 'Weekdays, 7:00 AM - 9:30 AM';
      case 'lunch_special':
        return 'Monday-Friday, 11:30 AM - 2:30 PM';
      case 'weekend_special':
        return 'Saturday-Sunday, all day';
      case 'flash_sale':
        return 'Next 4 hours (creates urgency)';
      default:
        return 'Flexible timing based on your schedule';
    }
  }
  
  double _estimateRevenue(Business business, TemplateContext context, double conversionRate) {
    // Estimate based on typical deal price and conversion
    double averageDealPrice = 15.0; // Default
    
    switch (business.category.toLowerCase()) {
      case 'restaurant':
        averageDealPrice = 18.0;
        break;
      case 'cafe':
        averageDealPrice = 8.0;
        break;
      case 'bar':
        averageDealPrice = 12.0;
        break;
      case 'shop':
        averageDealPrice = 25.0;
        break;
    }
    
    final estimatedReach = _estimateReach(business, context);
    final estimatedSales = (estimatedReach * conversionRate / 100).round();
    
    return estimatedSales * averageDealPrice;
  }
  
  /// Validation helper for template data
  Map<String, String?> validateTemplateData(
    DealStructureTemplate template,
    Map<String, dynamic> data,
  ) {
    return template.validateFields(data);
  }
  
  /// Preview generation helper
  String generateDealPreview(
    DealStructureTemplate template,
    Map<String, dynamic> data,
    Business business,
  ) {
    return template.generatePreview(data, business);
  }
}