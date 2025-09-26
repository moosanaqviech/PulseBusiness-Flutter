// lib/models/deal_template.dart

import 'package:flutter/material.dart';
import 'business.dart';
import 'deal.dart';

enum TemplateCategory { 
  timeBased, 
  discount, 
  seasonal, 
  inventory,
  customer,
}

enum TemplatePriority { low, medium, high, urgent }

abstract class DealTemplate {
  String get id;
  String get name;
  String get description;
  String get shortDescription;
  String get icon;
  TemplateCategory get category;
  Color get primaryColor;
  
  // Performance indicators
  double? get averageConversionRate;
  int? get suggestedDiscount;
  Duration get suggestedDuration;
  
  // Smart features
  List<String> get smartSuggestions;
  List<String> get targetBusinessTypes;
  TemplatePriority get priority;
  
  // Availability
  bool get isAvailable;
  bool get isSeasonallyAvailable;
  bool get isNew;
  bool get isPopular;
  
  // Core functionality
  Deal generateDeal(Business business);
  bool isApplicableFor(Business business);
  
  // Customization helpers
  Map<String, dynamic> getSmartDefaults(Business business);
  List<String> getOptimizationTips(Business business);
}

// Base template implementation
abstract class BaseTemplate implements DealTemplate {
  @override
  bool isApplicableFor(Business business) {
    return targetBusinessTypes.isEmpty || 
           targetBusinessTypes.contains(business.category.toLowerCase());
  }
  
  @override
  bool get isAvailable => true;
  
  @override
  bool get isSeasonallyAvailable {
    // Override in seasonal templates
    return true;
  }
  
  @override
  bool get isNew => false;
  
  @override
  bool get isPopular => averageConversionRate != null && averageConversionRate! > 30.0;
  
  @override
  TemplatePriority get priority => TemplatePriority.medium;
  
  @override
  Map<String, dynamic> getSmartDefaults(Business business) {
    return {
      'businessName': business.name,
      'category': business.category,
      'location': '${business.latitude},${business.longitude}',
    };
  }
  
  @override
  List<String> getOptimizationTips(Business business) {
    return [
      'Consider your target audience when setting quantity',
      'Images increase engagement by 40%',
      'Clear terms and conditions build trust',
    ];
  }

  
}
 
// Template Performance Data
class TemplatePerformanceData {
  final String templateId;
  final double conversionRate;
  final double averageRevenue;
  final int usageCount;
  final DateTime lastUsed;
  final Map<String, dynamic> metadata;
  
  TemplatePerformanceData({
    required this.templateId,
    required this.conversionRate,
    required this.averageRevenue,
    required this.usageCount,
    required this.lastUsed,
    this.metadata = const {},
  });
  
  factory TemplatePerformanceData.fromMap(Map<String, dynamic> map) {
    return TemplatePerformanceData(
      templateId: map['templateId'] ?? '',
      conversionRate: (map['conversionRate'] ?? 0.0).toDouble(),
      averageRevenue: (map['averageRevenue'] ?? 0.0).toDouble(),
      usageCount: map['usageCount'] ?? 0,
      lastUsed: DateTime.parse(map['lastUsed'] ?? DateTime.now().toIso8601String()),
      metadata: map['metadata'] ?? {},
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'templateId': templateId,
      'conversionRate': conversionRate,
      'averageRevenue': averageRevenue,
      'usageCount': usageCount,
      'lastUsed': lastUsed.toIso8601String(),
      'metadata': metadata,
    };
  }
}

// Template Recommendation
class TemplateRecommendation {
  final DealTemplate template;
  final double confidenceScore;
  final String reason;
  final Map<String, dynamic> predictions;
  final TemplatePriority priority;
  
  TemplateRecommendation({
    required this.template,
    required this.confidenceScore,
    required this.reason,
    this.predictions = const {},
    this.priority = TemplatePriority.medium,
  });
}

// Concrete Template Implementations

class HappyHourTemplate extends BaseTemplate {
  @override
  String get id => 'happy_hour';
  
  @override
  String get name => 'Happy Hour Special';
  
  @override
  String get description => 'Perfect for restaurants and bars to attract after-work crowd';
  
  @override
  String get shortDescription => 'After-work crowd magnet';
  
  @override
  String get icon => '🍺';
  
  @override
  TemplateCategory get category => TemplateCategory.timeBased;
  
  @override
  Color get primaryColor => Colors.orange;
  
  @override
  double get averageConversionRate => 28.4;
  
  @override
  int get suggestedDiscount => 25;
  
  @override
  Duration get suggestedDuration => Duration(hours: 3);
  
  @override
  List<String> get smartSuggestions => [
    'Best performance: Tuesday-Thursday 4-7 PM',
    'Include appetizers for higher ticket size',
    'Consider 2-for-1 drinks instead of percentage off',
    'Dine-in only increases foot traffic',
  ];
  
  @override
  List<String> get targetBusinessTypes => ['restaurant', 'cafe', 'bar'];
  
  @override
  Deal generateDeal(Business business, {DateTime? customStartTime}) {
    final defaults = getSmartDefaults(business);
    final basePrice = _calculateBasePrice(business);
    
    return Deal(
      title: '${business.name} Happy Hour Special',
      description: 'Join us for discounted drinks and appetizers during our happy hour! Perfect way to unwind after work.',
      category: business.category,
      latitude: business.latitude,
      longitude: business.longitude,
      originalPrice: basePrice,
      dealPrice: basePrice * 0.75, // 25% off
      totalQuantity: _calculateOptimalQuantity(business),
      businessId: business.id!,
      businessName: business.name,
      expirationTime: _getNextHappyHourTime(),
      termsAndConditions: 'Valid Monday-Friday 4-7 PM only. Dine-in only. Cannot be combined with other offers.',
      startTime: customStartTime,  
      isScheduled: customStartTime != null,
    );
  }
  
  double _calculateBasePrice(Business business) {
    // Smart pricing based on business category and location
    final categoryPricing = {
      'restaurant': 22.0,
      'cafe': 15.0,
      'bar': 18.0,
    };
    return categoryPricing[business.category.toLowerCase()] ?? 20.0;
  }
  
  int _calculateOptimalQuantity(Business business) {
    // Base quantity on business type and expected demand
    final categoryQuantity = {
      'restaurant': 25,
      'cafe': 20,
      'bar': 30,
    };
    return categoryQuantity[business.category.toLowerCase()] ?? 20;
  }
  
  DateTime _getNextHappyHourTime() {
    final now = DateTime.now();
    DateTime nextHappyHour;
    
    // If it's before 7 PM today and it's a weekday, use today
    if (now.weekday <= 5 && now.hour < 19) {
      nextHappyHour = DateTime(now.year, now.month, now.day, 19, 0); // 7 PM today
    } else {
      // Otherwise, use next weekday
      int daysUntilNextWeekday = 1;
      while ((now.weekday + daysUntilNextWeekday) % 7 == 6 || 
             (now.weekday + daysUntilNextWeekday) % 7 == 0) {
        daysUntilNextWeekday++;
      }
      nextHappyHour = now.add(Duration(days: daysUntilNextWeekday));
      nextHappyHour = DateTime(nextHappyHour.year, nextHappyHour.month, nextHappyHour.day, 19, 0);
    }
    
    return nextHappyHour;
  }
}

class BOGOTemplate extends BaseTemplate {
  @override
  String get id => 'bogo';
  
  @override
  String get name => 'Buy One Get One';
  
  @override
  String get description => 'Classic BOGO promotion that works across all business types';
  
  @override
  String get shortDescription => 'Double the value, double the fun';
  
  @override
  String get icon => '🎁';
  
  @override
  TemplateCategory get category => TemplateCategory.discount;
  
  @override
  Color get primaryColor => Colors.green;
  
  @override
  double get averageConversionRate => 35.2;
  
  @override
  int get suggestedDiscount => 50;
  
  @override
  Duration get suggestedDuration => Duration(days: 7);
  
  @override
  List<String> get smartSuggestions => [
    'Works best for coffee shops and retail',
    'Consider BOGO 50% off instead of free for better margins',
    'Limit to lower-cost items for profitability',
    'Great for introducing new products',
  ];
  
  @override
  List<String> get targetBusinessTypes => ['cafe', 'shop', 'restaurant'];
  
  @override
  Deal generateDeal(Business business, {DateTime? customStartTime}) {
    final basePrice = _calculateBasePrice(business);
    
    return Deal(
      title: 'Buy One Get One Free!',
      description: 'Bring a friend and get double the value! Buy any item and get a second one absolutely free.',
      category: business.category,
      latitude: business.latitude,
      longitude: business.longitude,
      originalPrice: basePrice * 2,
      dealPrice: basePrice,
      totalQuantity: 15,
      businessId: business.id!,
      businessName: business.name,
      startTime: customStartTime,
      isScheduled: customStartTime != null,
      expirationTime: DateTime.now().add(Duration(days: 7)),
      termsAndConditions: 'Free item must be of equal or lesser value. One per customer. Cannot be combined with other offers.',
    );
  }
  
  double _calculateBasePrice(Business business) {
    final categoryPricing = {
      'cafe': 8.0,
      'shop': 15.0,
      'restaurant': 12.0,
    };
    return categoryPricing[business.category.toLowerCase()] ?? 10.0;
  }
}

class FlashSaleTemplate extends BaseTemplate {
  @override
  String get id => 'flash_sale';
  
  @override
  String get name => 'Flash Sale';
  
  @override
  String get description => 'Create urgency with time-limited massive discounts';
  
  @override
  String get shortDescription => 'Lightning fast savings';
  
  @override
  String get icon => '⚡';
  
  @override
  TemplateCategory get category => TemplateCategory.inventory;
  
  @override
  Color get primaryColor => Colors.red;
  
  @override
  double get averageConversionRate => 45.8;
  
  @override
  int get suggestedDiscount => 40;
  
  @override
  Duration get suggestedDuration => Duration(hours: 4);
  
  @override
  TemplatePriority get priority => TemplatePriority.high;
  
  @override
  bool get isNew => true;
  
  @override
  List<String> get smartSuggestions => [
    'Best for clearing inventory or slow days',
    'Higher discount = higher urgency = better conversion',
    'Limit quantities to create scarcity',
    'Promote heavily on social media',
  ];
  
  @override
  List<String> get targetBusinessTypes => ['shop', 'restaurant', 'cafe'];
  
  @override
  Deal generateDeal(Business business,  {DateTime? customStartTime}) {
    final basePrice = _calculateBasePrice(business);
    
    return Deal(
      title: '⚡ FLASH SALE - ${suggestedDiscount}% OFF!',
      description: 'Lightning deal! Massive savings for the next few hours only. Don\'t miss out!',
      category: business.category,
      latitude: business.latitude,
      longitude: business.longitude,
      originalPrice: basePrice,
      dealPrice: basePrice * 0.6, // 40% off
      totalQuantity: 10, // Limited quantity for urgency
      businessId: business.id!,
      businessName: business.name,
       startTime: customStartTime,  
      isScheduled: customStartTime != null,
      expirationTime: DateTime.now().add(Duration(hours: 4)),
      termsAndConditions: 'Extremely limited time. While supplies last. No rain checks.',
    );
  }
  
  double _calculateBasePrice(Business business) {
    final categoryPricing = {
      'shop': 25.0,
      'restaurant': 20.0,
      'cafe': 12.0,
    };
    return categoryPricing[business.category.toLowerCase()] ?? 18.0;
  }
}

class FirstTimeCustomerTemplate extends BaseTemplate {
  @override
  String get id => 'first_time_customer';
  
  @override
  String get name => 'New Customer Welcome';
  
  @override
  String get description => 'Attract new customers with exclusive first-visit discount';
  
  @override
  String get shortDescription => 'Welcome new faces';
  
  @override
  String get icon => '👋';
  
  @override
  TemplateCategory get category => TemplateCategory.customer;
  
  @override
  Color get primaryColor => Colors.blue;
  
  @override
  double get averageConversionRate => 31.7;
  
  @override
  int get suggestedDiscount => 30;
  
  @override
  Duration get suggestedDuration => Duration(days: 30);
  
  @override
  List<String> get smartSuggestions => [
    'Great for building customer base',
    'Consider follow-up offers for repeat visits',
    'Ask for reviews from new customers',
    'Collect contact info for marketing',
  ];
  
  @override
  List<String> get targetBusinessTypes => [];
  
  @override
  Deal generateDeal(Business business,  {DateTime? customStartTime}) {
    final basePrice = _calculateBasePrice(business);
    
    return Deal(
      title: 'New Customer Special - ${suggestedDiscount}% OFF',
      description: 'Welcome to ${business.name}! Enjoy ${suggestedDiscount}% off your first visit. We can\'t wait to serve you!',
      category: business.category,
      latitude: business.latitude,
      longitude: business.longitude,
      originalPrice: basePrice,
      dealPrice: basePrice * 0.7, // 30% off
      totalQuantity: 25,
      businessId: business.id!,
      businessName: business.name,
       startTime: customStartTime,  
      isScheduled: customStartTime != null,
      expirationTime: DateTime.now().add(Duration(days: 30)),
      termsAndConditions: 'Valid for first-time customers only. ID may be required for verification.',
    );
  }
  
  double _calculateBasePrice(Business business) {
    final categoryPricing = {
      'restaurant': 25.0,
      'cafe': 15.0,
      'shop': 30.0,
      'activity': 40.0,
    };
    return categoryPricing[business.category.toLowerCase()] ?? 22.0;
  }
}

class WeekendSpecialTemplate extends BaseTemplate {
  @override
  String get id => 'weekend_special';
  
  @override
  String get name => 'Weekend Special';
  
  @override
  String get description => 'Perfect for weekend traffic and family time';
  
  @override
  String get shortDescription => 'Weekend vibes only';
  
  @override
  String get icon => '🎉';
  
  @override
  TemplateCategory get category => TemplateCategory.timeBased;
  
  @override
  Color get primaryColor => Colors.purple;
  
  @override
  double get averageConversionRate => 26.3;
  
  @override
  int get suggestedDiscount => 20;
  
  @override
  Duration get suggestedDuration => Duration(days: 2);
  
  @override
  List<String> get smartSuggestions => [
    'Saturday performs better than Sunday',
    'Family-friendly messaging increases appeal',
    'Consider brunch or lunch timing',
    'Great for activities and entertainment',
  ];
  
  @override
  List<String> get targetBusinessTypes => ['restaurant', 'activity', 'cafe'];
  
  @override
  Deal generateDeal(Business business,  {DateTime? customStartTime}) {
    final basePrice = _calculateBasePrice(business);
    
    return Deal(
      title: 'Weekend Special at ${business.name}',
      description: 'Make your weekend special! Enjoy great savings on your favorite items this Saturday and Sunday.',
      category: business.category,
      latitude: business.latitude,
      longitude: business.longitude,
      originalPrice: basePrice,
      dealPrice: basePrice * 0.8, // 20% off
      totalQuantity: 20,
      businessId: business.id!,
      businessName: business.name,
       startTime: customStartTime,  
      isScheduled: customStartTime != null,
      expirationTime: _getNextSundayEvening(),
      termsAndConditions: 'Valid Saturday and Sunday only. Cannot be combined with other weekend offers.',
    );
  }
  
  double _calculateBasePrice(Business business) {
    final categoryPricing = {
      'restaurant': 28.0,
      'activity': 35.0,
      'cafe': 18.0,
    };
    return categoryPricing[business.category.toLowerCase()] ?? 25.0;
  }
  
  DateTime _getNextSundayEvening() {
    final now = DateTime.now();
    int daysUntilSunday = 7 - now.weekday;
    if (daysUntilSunday == 0 && now.hour >= 20) daysUntilSunday = 7; // If past 8 PM Sunday
    
    final nextSunday = now.add(Duration(days: daysUntilSunday));
    return DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 20, 0);
  }
}