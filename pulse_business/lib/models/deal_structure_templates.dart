// lib/models/deal_structure_templates.dart
// New layer: Deal Structure Templates (user-facing)

import 'package:flutter/material.dart';
import 'business.dart';
import 'deal.dart';

// Base class for deal structure templates
abstract class DealStructureTemplate {
  String get id;
  String get name;
  String get description;
  String get icon;
  Color get primaryColor;
  
  // Form field definitions
  List<TemplateField> get requiredFields;
  List<TemplateField> get optionalFields;
  
  // Validation
  Map<String, String?> validateFields(Map<String, dynamic> data);
  
  // Preview generation
  String generatePreview(Map<String, dynamic> data, Business business);
  
  // Smart defaults based on context
  Map<String, dynamic> getSmartDefaults(Business business, TemplateContext context);
}

// Field definition for dynamic forms
class TemplateField {
  final String id;
  final String label;
  final String description;
  final FieldType type;
  final bool required;
  final dynamic defaultValue;
  final Map<String, dynamic> constraints;
  final List<FieldOption>? options; // For dropdowns, radio buttons
  
  const TemplateField({
    required this.id,
    required this.label,
    required this.description,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.constraints = const {},
    this.options,
  });
}

enum FieldType {
  text,
  number,
  currency,
  percentage,
  dropdown,
  multiSelect,
  radio,
  checkbox,
  dateTime,
  duration,
}

class FieldOption {
  final String value;
  final String label;
  final String? description;
  
  const FieldOption({
    required this.value,
    required this.label,
    this.description,
  });
}

// Context information for smart suggestions
class TemplateContext {
  final String businessType;
  final DateTime currentTime;
  final int dayOfWeek;
  final String? detectedContext; // 'happy_hour', 'lunch', 'weekend', etc.
  final double confidence;
  final Map<String, dynamic> suggestions;
  
  TemplateContext({
    required this.businessType,
    required this.currentTime,
    required this.dayOfWeek,
    this.detectedContext,
    required this.confidence,
    this.suggestions = const {},
  });
}

// Percentage Off Template Implementation
class PercentageOffTemplate extends DealStructureTemplate {
  @override
  String get id => 'percentage_off';
  
  @override
  String get name => 'Percentage Off';
  
  @override
  String get description => 'Classic discount - save X% off regular price';
  
  @override
  String get icon => '%';
  
  @override
  Color get primaryColor => Colors.green;
  
  @override
  List<TemplateField> get requiredFields => [
    const TemplateField(
      id: 'discount_percentage',
      label: 'Discount Percentage',
      description: 'How much % off to offer',
      type: FieldType.percentage,
      required: true,
      constraints: {
        'min': 5,
        'max': 70,
        'step': 5,
      },
    ),
    const TemplateField(
      id: 'original_price',
      label: 'Original Price',
      description: 'Regular price before discount',
      type: FieldType.currency,
      required: true,
      constraints: {
        'min': 1.00,
        'max': 1000.00,
      },
    ),
  ];
  
  @override
  List<TemplateField> get optionalFields => [
    const TemplateField(
      id: 'minimum_purchase',
      label: 'Minimum Purchase',
      description: 'Minimum amount to qualify for discount',
      type: FieldType.currency,
      required: false,
      constraints: {
        'min': 0.00,
        'max': 500.00,
      },
    ),
    const TemplateField(
      id: 'maximum_discount',
      label: 'Maximum Discount Cap',
      description: 'Maximum dollar amount discount (optional)',
      type: FieldType.currency,
      required: false,
      constraints: {
        'min': 1.00,
        'max': 200.00,
      },
    ),
    const TemplateField(
      id: 'excluded_categories',
      label: 'Excluded Items',
      description: 'Categories not eligible for discount',
      type: FieldType.multiSelect,
      required: false,
      options: [
        FieldOption(value: 'alcohol', label: 'Alcoholic Beverages'),
        FieldOption(value: 'tobacco', label: 'Tobacco Products'),
        FieldOption(value: 'gift_cards', label: 'Gift Cards'),
        FieldOption(value: 'sale_items', label: 'Already Discounted Items'),
      ],
    ),
  ];
  
  @override
  Map<String, String?> validateFields(Map<String, dynamic> data) {
    final errors = <String, String?>{};
    
    // Validate discount percentage
    final discountPercent = data['discount_percentage'];
    if (discountPercent == null || discountPercent < 5 || discountPercent > 70) {
      errors['discount_percentage'] = 'Discount must be between 5% and 70%';
    }
    
    // Validate original price
    final originalPrice = data['original_price'];
    if (originalPrice == null || originalPrice <= 0) {
      errors['original_price'] = 'Original price must be greater than \$0';
    }
    
    // Validate minimum purchase doesn't exceed deal value
    final minPurchase = data['minimum_purchase'];
    if (minPurchase != null && originalPrice != null && minPurchase > originalPrice) {
      errors['minimum_purchase'] = 'Minimum purchase cannot exceed item price';
    }
    
    // Validate maximum discount makes sense
    final maxDiscount = data['maximum_discount'];
    if (maxDiscount != null && originalPrice != null && discountPercent != null) {
      final calculatedDiscount = originalPrice * (discountPercent / 100);
      if (maxDiscount < calculatedDiscount * 0.5) {
        errors['maximum_discount'] = 'Maximum discount cap seems too low for this percentage';
      }
    }
    
    return errors;
  }
  
  @override
  String generatePreview(Map<String, dynamic> data, Business business) {
    final discountPercent = data['discount_percentage'] ?? 0;
    final originalPrice = data['original_price'] ?? 0.0;
    final finalPrice = originalPrice * (1 - discountPercent / 100);
    final savings = originalPrice - finalPrice;
    
    String preview = '${discountPercent}% Off Special at ${business.name}\n';
    preview += 'Was \$${originalPrice.toStringAsFixed(2)}, Now \$${finalPrice.toStringAsFixed(2)}\n';
    preview += 'Save \$${savings.toStringAsFixed(2)}!';
    
    final minPurchase = data['minimum_purchase'];
    if (minPurchase != null && minPurchase > 0) {
      preview += '\nMinimum purchase: \$${minPurchase.toStringAsFixed(2)}';
    }
    
    final maxDiscount = data['maximum_discount'];
    if (maxDiscount != null && maxDiscount > 0) {
      preview += '\nMaximum discount: \$${maxDiscount.toStringAsFixed(2)}';
    }
    
    return preview;
  }
  
  @override
  Map<String, dynamic> getSmartDefaults(Business business, TemplateContext context) {
    final defaults = <String, dynamic>{};
    
    // Base defaults for percentage off
    defaults['discount_percentage'] = 20; // Safe default
    defaults['original_price'] = _getTypicalPrice(business.category);
    
    // Context-specific optimizations
    if (context.detectedContext == 'happy_hour') {
      defaults.addAll(_getHappyHourDefaults(business, context));
    } else if (context.detectedContext == 'lunch_special') {
      defaults.addAll(_getLunchSpecialDefaults(business, context));
    } else if (context.detectedContext == 'weekend_special') {
      defaults.addAll(_getWeekendDefaults(business, context));
    }
    
    return defaults;
  }
  
  double _getTypicalPrice(String businessCategory) {
    final typicalPrices = {
      'restaurant': 15.99,
      'cafe': 6.99,
      'shop': 24.99,
      'salon': 45.99,
      'fitness': 19.99,
    };
    return typicalPrices[businessCategory.toLowerCase()] ?? 15.99;
  }
  
  Map<String, dynamic> _getHappyHourDefaults(Business business, TemplateContext context) {
    return {
      'discount_percentage': 25, // Higher discount for happy hour
      'original_price': business.category.toLowerCase() == 'bar' ? 9.99 : 12.99,
      'suggested_timing': {
        'start_time': '16:00', // 4 PM
        'end_time': '19:00',   // 7 PM
        'days': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
      },
      'suggested_title': '${business.name} Happy Hour Special',
      'suggested_description': 'Beat the rush! Join us for discounted drinks and appetizers during our happy hour.',
      'suggested_terms': 'Valid Monday-Friday 4:00 PM - 7:00 PM only. Dine-in only. Cannot be combined with other offers.',
      'target_audience': 'After-work professionals',
      'expected_conversion': 32.5,
    };
  }
  
  Map<String, dynamic> _getLunchSpecialDefaults(Business business, TemplateContext context) {
    return {
      'discount_percentage': 20,
      'original_price': business.category.toLowerCase() == 'restaurant' ? 14.99 : 8.99,
      'suggested_timing': {
        'start_time': '11:30',
        'end_time': '14:30',
        'days': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
      },
      'suggested_title': 'Express Lunch Special',
      'suggested_description': 'Quick, delicious, and affordable lunch perfect for busy professionals.',
      'target_audience': 'Business lunch crowd',
      'expected_conversion': 28.7,
    };
  }
  
  Map<String, dynamic> _getWeekendDefaults(Business business, TemplateContext context) {
    return {
      'discount_percentage': 15, // Lower discount, higher volume
      'original_price': _getTypicalPrice(business.category),
      'suggested_timing': {
        'start_time': '10:00',
        'end_time': '22:00',
        'days': ['saturday', 'sunday'],
      },
      'suggested_title': 'Weekend Special',
      'suggested_description': 'Make your weekend extra special with our weekend discount!',
      'target_audience': 'Weekend leisure customers',
      'expected_conversion': 24.3,
    };
  }
}