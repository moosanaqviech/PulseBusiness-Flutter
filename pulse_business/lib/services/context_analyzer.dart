// lib/services/context_analyzer.dart
// Context Analysis Engine - Detects business context for smart suggestions

import 'package:flutter/foundation.dart';
import '../models/business.dart';
import '../models/deal_structure_templates.dart';

class ContextAnalyzer {
  static final ContextAnalyzer _instance = ContextAnalyzer._internal();
  factory ContextAnalyzer() => _instance;
  ContextAnalyzer._internal();
  
  /// Analyze business and current context to provide smart suggestions
  TemplateContext analyzeContext(Business business, {DateTime? customTime}) {
    final now = customTime ?? DateTime.now();
    final hour = now.hour;
    final dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
    
    // Detect most likely context based on business type and timing
    final contextResults = _detectContexts(business, hour, dayOfWeek);
    
    // Find the highest confidence context
    final bestMatch = contextResults.entries
        .where((entry) => entry.value > 0.5) // Minimum confidence threshold
        .fold<MapEntry<String, double>?>(
          null,
          (prev, current) => prev == null || current.value > prev.value ? current : prev,
        );
    
    return TemplateContext(
      businessType: business.category,
      currentTime: now,
      dayOfWeek: dayOfWeek,
      detectedContext: bestMatch?.key,
      confidence: bestMatch?.value ?? 0.0,
      suggestions: _generateSuggestions(business, bestMatch?.key, hour, dayOfWeek),
    );
  }
  
  /// Detect all possible contexts and their confidence scores
  Map<String, double> _detectContexts(Business business, int hour, int dayOfWeek) {
    final contexts = <String, double>{};
    
    // Happy Hour Detection
    contexts['happy_hour'] = _detectHappyHour(business, hour, dayOfWeek);
    
    // Lunch Special Detection  
    contexts['lunch_special'] = _detectLunchSpecial(business, hour, dayOfWeek);
    
    // Weekend Special Detection
    contexts['weekend_special'] = _detectWeekendSpecial(business, hour, dayOfWeek);
    
    // Morning Rush Detection
    contexts['morning_rush'] = _detectMorningRush(business, hour, dayOfWeek);
    
    // Late Night Detection
    contexts['late_night'] = _detectLateNight(business, hour, dayOfWeek);
    
    // New Customer Acquisition (always available, low confidence)
    contexts['new_customer'] = 0.3;
    
    return contexts;
  }
  
  /// Happy Hour Context Detection
  double _detectHappyHour(Business business, int hour, int dayOfWeek) {
    double confidence = 0.0;
    
    // Business type compatibility
    if (['restaurant', 'cafe'].contains(business.category.toLowerCase())) {
      confidence += 0.4;
    } else {
      return 0.0; // Happy hour doesn't make sense for other business types
    }
    
    // Time compatibility (4 PM - 7 PM is peak happy hour)
    if (hour >= 16 && hour <= 19) {
      confidence += 0.4; // Peak happy hour time
    } else if (hour >= 15 && hour <= 20) {
      confidence += 0.2; // Extended happy hour time
    } else if (hour >= 14 && hour <= 16) {
      confidence += 0.1; // Planning ahead for happy hour
    }
    
    // Weekday compatibility (Monday-Friday is traditional)
    if (dayOfWeek >= 1 && dayOfWeek <= 5) {
      confidence += 0.2;
    } else if (dayOfWeek == 6) { // Saturday
      confidence += 0.1; // Some places do weekend happy hour
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Lunch Special Context Detection
  double _detectLunchSpecial(Business business, int hour, int dayOfWeek) {
    double confidence = 0.0;
    
    // Business type compatibility
    if (['restaurant', 'cafe'].contains(business.category.toLowerCase())) {
      confidence += 0.4;
    } else {
      return 0.0;
    }
    
    // Time compatibility (11:30 AM - 2:30 PM)
    if (hour >= 11 && hour <= 14) {
      confidence += 0.4;
    } else if (hour >= 10 && hour <= 11) {
      confidence += 0.2; // Planning ahead
    }
    
    // Weekday compatibility (business lunch is weekdays)
    if (dayOfWeek >= 1 && dayOfWeek <= 5) {
      confidence += 0.2;
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Weekend Special Context Detection
  double _detectWeekendSpecial(Business business, int hour, int dayOfWeek) {
    double confidence = 0.0;
    
    // Weekend timing
    if (dayOfWeek >= 6) { // Saturday or Sunday
      confidence += 0.5;
    } else if (dayOfWeek == 5 && hour >= 17) { // Friday evening
      confidence += 0.3;
    } else {
      return 0.0;
    }
    
    // Business type compatibility (most businesses can do weekend specials)
    if (['restaurant', 'cafe', 'shop', 'entertainment'].contains(business.category.toLowerCase())) {
      confidence += 0.3;
    } else {
      confidence += 0.1; // Lower but still possible
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Morning Rush Context Detection
  double _detectMorningRush(Business business, int hour, int dayOfWeek) {
    double confidence = 0.0;
    
    // Business type compatibility
    if (['cafe', 'restaurant'].contains(business.category.toLowerCase())) {
      confidence += 0.4;
    } else {
      return 0.0;
    }
    
    // Time compatibility (7 AM - 10 AM)
    if (hour >= 7 && hour <= 9) {
      confidence += 0.4;
    } else if (hour >= 6 && hour <= 10) {
      confidence += 0.2;
    }
    
    // Weekday compatibility
    if (dayOfWeek >= 1 && dayOfWeek <= 5) {
      confidence += 0.2;
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Late Night Context Detection
  double _detectLateNight(Business business, int hour, int dayOfWeek) {
    double confidence = 0.0;
    
    // Business type compatibility
    if (['restaurant', 'entertainment'].contains(business.category.toLowerCase())) {
      confidence += 0.3;
    } else {
      return 0.0;
    }
    
    // Time compatibility (9 PM - 2 AM)
    if (hour >= 21 || hour <= 2) {
      confidence += 0.4;
    } else if (hour >= 20 || hour <= 3) {
      confidence += 0.2;
    }
    
    // Weekend bonus
    if (dayOfWeek >= 5) { // Friday, Saturday, Sunday
      confidence += 0.3;
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Generate context-specific suggestions
  Map<String, dynamic> _generateSuggestions(Business business, String? context, int hour, int dayOfWeek) {
    final suggestions = <String, dynamic>{};
    
    if (context == null) return suggestions;
    
    switch (context) {
      case 'happy_hour':
        suggestions.addAll(_getHappyHourSuggestions(business));
        break;
      case 'lunch_special':
        suggestions.addAll(_getLunchSpecialSuggestions(business));
        break;
      case 'weekend_special':
        suggestions.addAll(_getWeekendSpecialSuggestions(business));
        break;
      case 'morning_rush':
        suggestions.addAll(_getMorningRushSuggestions(business));
        break;
      case 'late_night':
        suggestions.addAll(_getLateNightSuggestions(business));
        break;
    }
    
    return suggestions;
  }
  
  Map<String, dynamic> _getHappyHourSuggestions(Business business) {
    return {
      'title': '💡 Perfect for Happy Hour!',
      'description': 'Based on your ${business.category.toLowerCase()} and the current time, this works great as a Happy Hour special!',
      'benefits': [
        'Attracts after-work professionals',
        'Increases weekday traffic during slow hours', 
        'Builds customer loyalty through routine',
        'Average 32% conversion rate for similar businesses',
      ],
      'optimal_timing': {
        'start': '4:00 PM',
        'end': '7:00 PM',
        'days': 'Monday - Friday',
        'duration': '3 hours daily',
      },
      'pricing_tips': [
        '25% discount works well for drinks',
        '20% discount for food items',
        'Consider dine-in only to increase foot traffic',
        'Bundle drinks + appetizers for higher ticket',
      ],
      'marketing_angle': 'Beat the rush! Perfect way to unwind after work.',
    };
  }
  
  Map<String, dynamic> _getLunchSpecialSuggestions(Business business) {
    return {
      'title': '🍽️ Great for Lunch Special!',
      'description': 'Capture the business lunch crowd with a time-limited deal!',
      'benefits': [
        'Targets busy professionals',
        'Quick turnover increases daily revenue',
        'Builds weekday lunch loyalty',
        'Average 28% conversion rate',
      ],
      'optimal_timing': {
        'start': '11:30 AM',
        'end': '2:30 PM', 
        'days': 'Monday - Friday',
        'duration': '3 hours daily',
      },
      'pricing_tips': [
        '20% discount on combo meals',
        'Include drink for better value perception',
        'Emphasize speed and convenience',
        'Consider take-out friendly options',
      ],
      'marketing_angle': 'Quick, delicious, and budget-friendly lunch!',
    };
  }
  
  Map<String, dynamic> _getWeekendSpecialSuggestions(Business business) {
    return {
      'title': '🎉 Perfect Weekend Special!',
      'description': 'Weekend customers have more time and are often looking for experiences!',
      'benefits': [
        'Attracts leisure customers',
        'Higher average order values on weekends',
        'Great for family and group bookings',
        'Average 24% conversion rate',
      ],
      'optimal_timing': {
        'start': '10:00 AM',
        'end': '10:00 PM',
        'days': 'Saturday - Sunday',
        'duration': 'All weekend',
      },
      'pricing_tips': [
        '15-20% discount works well',
        'Consider family packages',
        'Bundle experiences or services',
        'Weekend customers less price-sensitive',
      ],
      'marketing_angle': 'Make your weekend extra special!',
    };
  }
  
  Map<String, dynamic> _getMorningRushSuggestions(Business business) {
    return {
      'title': '☕ Morning Rush Optimization!',
      'description': 'Catch the commuter crowd with a quick morning deal!',
      'benefits': [
        'High-volume, quick transactions',
        'Builds morning routine loyalty',
        'Great profit margins on coffee + pastry',
        'Average 41% conversion rate',
      ],
      'optimal_timing': {
        'start': '7:00 AM',
        'end': '9:30 AM',
        'days': 'Monday - Friday',
        'duration': '2.5 hours daily',
      },
      'pricing_tips': [
        'Bundle coffee + pastry',
        '25-30% discount on combos',
        'Speed is crucial - pre-made options',
        'Loyalty program integration',
      ],
      'marketing_angle': 'Fuel up for success! Quick, convenient, affordable.',
    };
  }
  
  Map<String, dynamic> _getLateNightSuggestions(Business business) {
    return {
      'title': '🌙 Late Night Special!',
      'description': 'Perfect for the night crowd looking for deals!',
      'benefits': [
        'Utilizes slow late-night hours',
        'Attracts younger demographic',
        'Good for clearing daily inventory',
        'Creates buzz on social media',
      ],
      'optimal_timing': {
        'start': '9:00 PM',
        'end': '12:00 AM',
        'days': 'Friday - Saturday',
        'duration': '3 hours weekend nights',
      },
      'pricing_tips': [
        '30-40% discount to create urgency',
        'Focus on shareable items',
        'Consider group deals',
        'Social media promotion crucial',
      ],
      'marketing_angle': 'Night owls deserve great deals too!',
    };
  }
  
  /// Get user-friendly context explanation
  String getContextExplanation(String context) {
    switch (context) {
      case 'happy_hour':
        return 'Perfect timing for a Happy Hour special! This is when after-work professionals look for deals.';
      case 'lunch_special':
        return 'Great time for a Lunch Special! Business professionals need quick, affordable meals.';
      case 'weekend_special':
        return 'Weekend customers are in leisure mode and often looking for experiences and deals.';
      case 'morning_rush':
        return 'Morning Rush time! Commuters want quick coffee and breakfast combinations.';
      case 'late_night':
        return 'Late night crowd is perfect for special deals and social experiences.';
      default:
        return 'Based on your business type, we can suggest optimal timing and pricing.';
    }
  }
}