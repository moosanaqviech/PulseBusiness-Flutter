// lib/models/deal_structure_templates.dart
// New layer: Deal Structure Templates (user-facing)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'business.dart';
import 'deal.dart';

enum TemplateCategory {
  timeBased,
  discount,
  combo,
  //loyalty,
  inventory,
  //seasonal,
  customer
}


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

  TemplateCategory get category;
  
  //TAGS FOR MORE FLEXIBLE FILTERING
  List<String> get tags => [];
  
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
  String get icon => '💰';
  
  @override
  Color get primaryColor => Colors.green;

  @override
  TemplateCategory get category => TemplateCategory.discount;
  
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
    /*const TemplateField(
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
    ),*/
    const TemplateField(
      id: 'description',
      label: 'Description',
      description: 'Add deal description',
      type: FieldType.text,
      required: false,
      
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

// Simple Combo Deal Template Implementation

class ComboDealTemplate extends DealStructureTemplate {
  @override
  String get id => 'combo_deal';
  
  @override
  String get name => 'Combo Deal';
  
  @override
  String get description => 'Bundle items together for a discounted price';
  
  @override
  String get icon => '📦';
  
  @override
  Color get primaryColor => Colors.orange;

  @override
  TemplateCategory get category => TemplateCategory.combo;
  
  @override
  List<TemplateField> get requiredFields => [
    const TemplateField(
      id: 'combo_title',
      label: 'Combo Title',
      description: 'Name for your combo (e.g., "Lunch Special", "Coffee & Pastry")',
      type: FieldType.text,
      required: true,
      constraints: {
        'maxLength': 50,
      },
    ),
    const TemplateField(
      id: 'combo_items',
      label: 'What\'s Included',
      description: 'List the items in your combo (e.g., "Burger + Fries + Drink")',
      type: FieldType.text,
      required: true,
      constraints: {
        'placeholder': 'Item 1 + Item 2 + Item 3',
        'maxLength': 150,
      },
    ),
    const TemplateField(
      id: 'combo_price',
      label: 'Combo Price',
      description: 'Your combo deal price',
      type: FieldType.currency,
      required: true,
      constraints: {
        'min': 1.00,
        'max': 500.00,
      },
    ),
  ];
  
  @override
  List<TemplateField> get optionalFields => [
    const TemplateField(
      id: 'combo_description',
      label: 'Extra Details',
      description: 'Any additional details about choices or upgrades',
      type: FieldType.text,
      required: false,
      constraints: {
        'placeholder': 'Choose your drink, substitutions available, etc.',
        'maxLength': 100,
      },
    ),
  ];
  
  @override
  Map<String, String?> validateFields(Map<String, dynamic> data) {
    final errors = <String, String?>{};
    
    // Validate title
    final title = data['combo_title']?.toString()?.trim();
    if (title == null || title.isEmpty) {
      errors['combo_title'] = 'Combo title is required';
    }
    
    // Validate items
    final items = data['combo_items']?.toString()?.trim();
    if (items == null || items.isEmpty) {
      errors['combo_items'] = 'Please list what\'s included in the combo';
    }
    
    // Validate price
    final comboPrice = data['combo_price'];
    if (comboPrice == null || comboPrice <= 0) {
      errors['combo_price'] = 'Combo price must be greater than 0';
    }
    
    return errors;
  }
  
  @override
  String generatePreview(Map<String, dynamic> data, Business business) {
    final title = data['combo_title'] ?? 'Combo Deal';
    final items = data['combo_items'] ?? 'Multiple items';
    final comboPrice = data['combo_price'] ?? 0.0;
    final extraDetails = data['combo_description'] ?? '';
    
    String preview = '$title\n';
    preview += '$items\n';
    preview += 'Price: \$${comboPrice.toStringAsFixed(2)}';
    
    if (extraDetails.isNotEmpty) {
      preview += '\n$extraDetails';
    }
    
    return preview;
  }
  
  @override
  Map<String, dynamic> getSmartDefaults(Business business, TemplateContext context) {
    final defaults = <String, dynamic>{};
    
    // Simple business-based defaults
    switch (business.category.toLowerCase()) {
      case 'restaurant':
        defaults['combo_title'] = 'Lunch Combo';
        defaults['combo_items'] = 'Entree + Side + Drink';
        defaults['combo_price'] = 14.99;
        break;
        
      case 'cafe':
        defaults['combo_title'] = 'Coffee & Pastry';
        defaults['combo_items'] = 'Specialty Coffee + Fresh Pastry';
        defaults['combo_price'] = 6.99;
        break;
        
      default:
        defaults['combo_title'] = 'Value Bundle';
        defaults['combo_items'] = 'Main Item + Bonus Item';
        defaults['combo_price'] = 12.99;
    }
    
    return defaults;
  }
}

class FlashSaleTemplate extends DealStructureTemplate {
  @override
  String get id => 'flash_sale';
  
  @override
  String get name => 'Flash Sale';
  
  @override
  String get description => 'Limited time offer that starts immediately with high discount and limited quantity';
  
  @override
  String get icon => '⚡';
  
  @override
  Color get primaryColor => Colors.red;
  

  @override
  TemplateCategory get category => TemplateCategory.timeBased;

  @override
  List<TemplateField> get requiredFields => [
    const TemplateField(
      id: 'flash_title',
      label: 'Flash Sale Title',
      description: 'Catchy title for your flash sale (e.g., "24-Hour Flash Sale!")',
      type: FieldType.text,
      required: true,
      constraints: {
        'maxLength': 60,
        'placeholder': '24-Hour Flash Sale!',
      },
    ),
    const TemplateField(
      id: 'discount_percentage',
      label: 'Discount Percentage',
      description: 'Flash sales need at least 25% off to create urgency',
      type: FieldType.percentage,
      required: true,
      defaultValue: 25.0,
      constraints: {
        'min': 25,
        'max': 75,
        'step': 5,
      },
    ),
    const TemplateField(
      id: 'original_price',
      label: 'Original Price',
      description: 'Regular price before the flash sale discount',
      type: FieldType.currency,
      required: true,
      constraints: {
        'min': 1.00,
        'max': 1000.00,
      },
    ),
    const TemplateField(
      id: 'quantity_available',
      label: 'Limited Quantity',
      description: 'How many items available (creates scarcity)',
      type: FieldType.number,
      required: true,
      defaultValue: 50,
      constraints: {
        'min': 1,
        'max': 500,
      },
    ),
  ];
  
  @override
  List<TemplateField> get optionalFields => [
    const TemplateField(
      id: 'flash_description',
      label: 'Additional Details',
      description: 'Extra details about the flash sale or item',
      type: FieldType.text,
      required: false,
      constraints: {
        'maxLength': 150,
        'placeholder': 'Limited time only! First come, first served.',
      },
    ),
  ];
  
  @override
  Map<String, String?> validateFields(Map<String, dynamic> data) {
    final errors = <String, String?>{};
    
    // Validate title
    final title = data['flash_title']?.toString()?.trim();
    if (title == null || title.isEmpty) {
      errors['flash_title'] = 'Flash sale title is required';
    }
    
    // Validate discount percentage (minimum 25%)
    final discountPercent = data['discount_percentage'];
    if (discountPercent == null || discountPercent < 25) {
      errors['discount_percentage'] = 'Flash sales require at least 25% discount';
    }
    
    // Validate original price
    final originalPrice = data['original_price'];
    if (originalPrice == null || originalPrice <= 0) {
      errors['original_price'] = 'Original price must be greater than 0';
    }
    
    // Validate quantity
    final quantity = data['quantity_available'];
    if (quantity == null || quantity <= 0) {
      errors['quantity_available'] = 'Quantity must be at least 1';
    }
    
    return errors;
  }
   @override
  String generatePreview(Map<String, dynamic> data, Business business) {
    final title = data['flash_title'] ?? 'Flash Sale';
    final discountPercent = data['discount_percentage'] ?? 25;
    final originalPrice = data['original_price'] ?? 0.0;
    final quantity = data['quantity_available'] ?? 50;
    final extraDetails = data['flash_description'] ?? '';
    
    final discountedPrice = originalPrice * (1 - discountPercent / 100);
    final savings = originalPrice - discountedPrice;
    
    String preview = '🔥 $title\n\n';
    preview += 'FLASH SALE - Starting NOW!\n';
    preview += 'Save $discountPercent% - Only \${discountedPrice.toStringAsFixed(2)} ';
    preview += '(was \${originalPrice.toStringAsFixed(2)})\n';
    preview += 'You save \${savings.toStringAsFixed(2)}!\n\n';
    preview += '⚡ LIMITED: Only $quantity available\n';
    preview += '⏰ HURRY: Sale ends soon!\n';
    
    if (extraDetails.isNotEmpty) {
      preview += '\n$extraDetails';
    }
    
    preview += '\n\nAvailable at ${business.name}';
    
    return preview;
  }
  
  @override
  Map<String, dynamic> getSmartDefaults(Business business, TemplateContext context) {
    final Map<String, dynamic> defaults = {
      'flash_title': '⚡ Flash Sale Alert!',
      'discount_percentage': 30.0, // Higher default for flash sales
      'quantity_available': 25, // Limited quantity creates urgency
    };
    
    // Context-based adjustments
    switch (context.detectedContext) {
      case 'happy_hour':
        defaults['flash_title'] = '🍻 Happy Hour Flash Sale!';
        defaults['discount_percentage'] = 35.0;
        break;
      case 'lunch_special':
        defaults['flash_title'] = '🍽️ Lunch Rush Flash Sale!';
        defaults['quantity_available'] = 50;
        break;
      case 'weekend_special':
        defaults['flash_title'] = '🎉 Weekend Flash Sale!';
        defaults['discount_percentage'] = 40.0;
        break;
      case 'morning_rush':
        defaults['flash_title'] = '☀️ Morning Flash Sale!';
        defaults['quantity_available'] = 30;
        break;
    }
    
    // Business type adjustments
    switch (business.category.toLowerCase()) {
      case 'restaurant':
      case 'food':
        defaults['flash_title'] = '🍽️ Flash Food Deal!';
        break;
      case 'retail':
      case 'clothing':
        defaults['flash_title'] = '👕 Flash Fashion Sale!';
        defaults['quantity_available'] = 15; // Clothing usually lower qty
        break;
      case 'service':
        defaults['flash_title'] = '⚡ Service Flash Deal!';
        defaults['quantity_available'] = 10; // Services are limited
        break;
    }
    
    return defaults;
  }
}
