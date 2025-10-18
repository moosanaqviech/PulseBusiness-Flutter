// lib/services/hybrid_template_manager.dart
// Fixed version - handles type compatibility between old and new template systems

import 'package:flutter/foundation.dart';
import '../models/business.dart';
import '../models/deal.dart';
import '../models/deal_structure_templates.dart';
import '../models/deal_template.dart'; // Your existing template system
import '../services/context_analyzer.dart';
import '../services/template_transformation_service.dart';
import '../services/template_manager.dart'; // Your existing template manager

// Updated TemplateRecommendation to handle both template types
class HybridTemplateRecommendation {
  final dynamic template; // Can be either DealTemplate or DealStructureTemplate
  final String templateType; // 'legacy' or 'structure'
  final double confidenceScore;
  final String reason;
  final Map<String, dynamic> predictions;
  final TemplatePriority priority;
  
  HybridTemplateRecommendation({
    required this.template,
    required this.templateType,
    required this.confidenceScore,
    required this.reason,
    this.predictions = const {},
    this.priority = TemplatePriority.medium,
  });
  
  // Helper getters
  String get templateId {
    if (templateType == 'structure') {
      return (template as DealStructureTemplate).id;
    } else {
      return (template as DealTemplate).id;
    }
  }
  
  String get templateName {
    if (templateType == 'structure') {
      return (template as DealStructureTemplate).name;
    } else {
      return (template as DealTemplate).name;
    }
  }
  
  String get templateDescription {
    if (templateType == 'structure') {
      return (template as DealStructureTemplate).description;
    } else {
      return (template as DealTemplate).description;
    }
  }
}

class HybridTemplateManager extends ChangeNotifier {
  static final HybridTemplateManager _instance = HybridTemplateManager._internal();
  factory HybridTemplateManager() => _instance;
  HybridTemplateManager._internal();
  
  // Services
  final ContextAnalyzer _contextAnalyzer = ContextAnalyzer();
  final TemplateTransformationService _transformationService = TemplateTransformationService();
  final TemplateManager _legacyTemplateManager = TemplateManager(); // Your existing manager
  
  // New structure templates
  final List<DealStructureTemplate> _structureTemplates = [
    PercentageOffTemplate(),
    // Add more as they're implemented:
    // BOGOStructureTemplate(),
    // FlashSaleStructureTemplate(),
    // ComboStructureTemplate(),
  ];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// Get all available structure templates
  List<DealStructureTemplate> getStructureTemplates() {
    return _structureTemplates;
  }
  
  /// Get structure template by ID
  DealStructureTemplate? getStructureTemplate(String templateId) {
    try {
      return _structureTemplates.firstWhere((template) => template.id == templateId);
    } catch (e) {
      return null;
    }
  }
  
  /// Analyze business context for smart suggestions
  TemplateContext analyzeBusinessContext(Business business, {DateTime? customTime}) {
    return _contextAnalyzer.analyzeContext(business, customTime: customTime);
  }
  
  /// Create deal using new structure template system
  Future<Deal> createDealFromStructureTemplate({
    required String templateId,
    required Map<String, dynamic> templateData,
    required Business business,
    DateTime? customStartTime,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final template = getStructureTemplate(templateId);
      if (template == null) {
        throw Exception('Template not found: $templateId');
      }
      
      // Validate template data
      final validationErrors = template.validateFields(templateData);
      if (validationErrors.isNotEmpty) {
        final errorMessages = validationErrors.values.where((error) => error != null).join(', ');
        throw Exception('Validation failed: $errorMessages');
      }
      
      // Transform to Deal object
      final deal = _transformationService.transformToDeal(
        template: template,
        templateData: templateData,
        business: business,
        customStartTime: customStartTime,
      );
      
      return deal;
    } catch (e) {
      _setError('Failed to create deal: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// BACKWARD COMPATIBILITY: Get legacy business context templates
  /// This allows existing users to continue using the old system
  List<DealTemplate> getLegacyTemplates(Business business) {
    return _legacyTemplateManager.getTemplatesForBusiness(business);
  }
  
  /// BACKWARD COMPATIBILITY: Create deal using legacy template system
  Future<Deal> createDealFromLegacyTemplate({
    required String legacyTemplateId,
    required Business business,
    Map<String, dynamic>? customizations,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final legacyTemplate = _legacyTemplateManager.getTemplate(legacyTemplateId);
      if (legacyTemplate == null) {
        throw Exception('Legacy template not found: $legacyTemplateId');
      }
      
      // Use existing legacy system
      final deal = legacyTemplate.generateDeal(business);
      
      // Apply any customizations
      if (customizations != null) {
        // Apply customizations to the generated deal
        // This would depend on your existing Deal model's copyWith method
        return _applyCustomizations(deal, customizations);
      }
      
      return deal;
    } catch (e) {
      _setError('Failed to create legacy deal: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Apply customizations to a deal (helper method)
  Deal _applyCustomizations(Deal deal, Map<String, dynamic> customizations) {
    return deal.copyWith(
      title: customizations['title'] ?? deal.title,
      description: customizations['description'] ?? deal.description,
      originalPrice: customizations['original_price'] ?? deal.originalPrice,
      dealPrice: customizations['deal_price'] ?? deal.dealPrice,
      totalQuantity: customizations['quantity'] ?? deal.totalQuantity,
      expirationTime: customizations['expiration_time'] ?? deal.expirationTime,
      termsAndConditions: customizations['terms'] ?? deal.termsAndConditions,
    );
  }
  
  /// Get smart recommendations combining both systems
  Future<List<HybridTemplateRecommendation>> getSmartRecommendations(Business business) async {
    try {
      _setLoading(true);
      _clearError();
      
      final recommendations = <HybridTemplateRecommendation>[];
      
      // Get context analysis
      final context = _contextAnalyzer.analyzeContext(business);
      
      // Recommend structure templates based on context
      if (context.confidence > 0.6) {
        final contextualRecommendations = _getContextualStructureRecommendations(context, business);
        recommendations.addAll(contextualRecommendations);
      }
      
      // Get legacy template recommendations (backward compatibility)
      final legacyRecommendations = await _legacyTemplateManager.getRecommendations(
        business.id!,
        business,
      );
      
      // Convert legacy recommendations to hybrid format
      final hybridLegacyRecommendations = legacyRecommendations.map((legacyRec) => 
        HybridTemplateRecommendation(
          template: legacyRec.template,
          templateType: 'legacy',
          confidenceScore: legacyRec.confidenceScore,
          reason: legacyRec.reason,
          predictions: legacyRec.predictions,
          priority: legacyRec.priority,
        ),
      ).toList();
      
      // Merge recommendations, prioritizing new system if confidence is high
      if (context.confidence > 0.7) {
        recommendations.addAll(hybridLegacyRecommendations.take(2)); // Add a few legacy options
      } else {
        recommendations.addAll(hybridLegacyRecommendations); // Fall back to legacy system
      }
      
      // Sort by priority and confidence
      recommendations.sort((a, b) {
        final aPriority = a.priority.index;
        final bPriority = b.priority.index;
        if (aPriority != bPriority) {
          return bPriority.compareTo(aPriority); // Higher priority first
        }
        return b.confidenceScore.compareTo(a.confidenceScore);
      });
      
      return recommendations.take(6).toList();
    } catch (e) {
      _setError('Failed to get recommendations: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// Generate contextual structure template recommendations
  List<HybridTemplateRecommendation> _getContextualStructureRecommendations(
    TemplateContext context,
    Business business,
  ) {
    final recommendations = <HybridTemplateRecommendation>[];
    
    // Recommend percentage off for detected contexts
    switch (context.detectedContext) {
      case 'happy_hour':
      case 'lunch_special':
      case 'morning_rush':
      case 'weekend_special':
        final percentageOffTemplate = _structureTemplates.firstWhere((t) => t.id == 'percentage_off');
        recommendations.add(HybridTemplateRecommendation(
          template: percentageOffTemplate,
          templateType: 'structure',
          confidenceScore: context.confidence,
          reason: 'Perfect for ${context.detectedContext!.replaceAll('_', ' ')} timing',
          priority: TemplatePriority.high,
          predictions: {
            'expectedConversion': _getExpectedConversion(context.detectedContext!, business),
            'optimalDiscount': _getOptimalDiscount(context.detectedContext!, business),
          },
        ));
        break;
    }
    
    return recommendations;
  }
  
  double _getExpectedConversion(String contextType, Business business) {
    final baseRates = {
      'happy_hour': 32.5,
      'morning_rush': 41.2,
      'lunch_special': 28.7,
      'weekend_special': 24.3,
    };
    
    double rate = baseRates[contextType] ?? 25.0;
    
    // Adjust for business type
    switch (business.category.toLowerCase()) {
      case 'cafe':
        rate *= 1.1;
        break;
      case 'bar':
        rate *= 0.95;
        break;
    }
    
    return rate;
  }
  
  int _getOptimalDiscount(String contextType, Business business) {
    final optimalDiscounts = {
      'happy_hour': 25,
      'morning_rush': 30,
      'lunch_special': 20,
      'weekend_special': 15,
    };
    
    return optimalDiscounts[contextType] ?? 20;
  }
  
  /// Get performance prediction for any template type
  Map<String, dynamic> getPerformancePrediction({
    String? structureTemplateId,
    String? legacyTemplateId,
    required Business business,
  }) {
    final context = _contextAnalyzer.analyzeContext(business);
    
    if (structureTemplateId != null) {
      final template = getStructureTemplate(structureTemplateId);
      if (template != null) {
        return _transformationService.getPerformancePrediction(template, context, business);
      }
    }
    
    if (legacyTemplateId != null) {
      // Use legacy performance prediction if available
      return _getLegacyPerformancePrediction(legacyTemplateId, business, context);
    }
    
    return {
      'expectedConversion': 25.0,
      'confidenceLevel': 0.5,
      'estimatedReach': 100,
      'recommendationStrength': 'Consider Alternatives',
    };
  }
  
  Map<String, dynamic> _getLegacyPerformancePrediction(
    String legacyTemplateId,
    Business business,
    TemplateContext context,
  ) {
    // Map legacy template IDs to performance metrics
    final legacyMetrics = {
      'happy_hour': {'conversion': 28.4, 'reach': 120},
      'bogo': {'conversion': 35.2, 'reach': 150},
      'flash_sale': {'conversion': 45.8, 'reach': 200},
      'first_time_customer': {'conversion': 38.7, 'reach': 80},
      'weekend_special': {'conversion': 24.3, 'reach': 110},
    };
    
    final metrics = legacyMetrics[legacyTemplateId] ?? {'conversion': 25.0, 'reach': 100};
    
    return {
      'expectedConversion': metrics['conversion'],
      'confidenceLevel': 0.7, // Legacy templates have good historical data
      'estimatedReach': metrics['reach'],
      'recommendationStrength': 'Proven Template',
    };
  }
  
  /// Migration helper: Suggest structure template alternatives for legacy templates
  List<Map<String, dynamic>> getSuggestedMigrations(Business business) {
    final suggestions = <Map<String, dynamic>>[];
    final context = _contextAnalyzer.analyzeContext(business);
    
    // Suggest percentage off for various legacy templates
    if (context.confidence > 0.5) {
      suggestions.add({
        'legacyTemplate': 'happy_hour',
        'structureTemplate': 'percentage_off',
        'reason': 'More flexible pricing control with same happy hour timing',
        'benefits': ['Custom discount percentages', 'Smart timing suggestions', 'Better analytics'],
      });
      
      suggestions.add({
        'legacyTemplate': 'lunch_special',
        'structureTemplate': 'percentage_off',
        'reason': 'Optimized for lunch crowd with dynamic pricing',
        'benefits': ['Adjust discount based on demand', 'Lunch-specific suggestions', 'Performance tracking'],
      });
    }
    
    return suggestions;
  }
  
  /// Analytics: Compare performance between template systems
  Future<Map<String, dynamic>> getTemplateSystemAnalytics(Business business) async {
    try {
      // This would integrate with your existing analytics
      // For now, return mock data structure
      return {
        'structureTemplates': {
          'totalUsage': 0,
          'averageConversion': 0.0,
          'topPerforming': [],
        },
        'legacyTemplates': {
          'totalUsage': 0,
          'averageConversion': 0.0,
          'topPerforming': [],
        },
        'migrationRecommendations': getSuggestedMigrations(
          business
        ),
      };
    } catch (e) {
      _setError('Failed to get analytics: $e');
      return {};
    }
  }
  
  /// Feature flag: Control rollout of new template system
  bool shouldShowStructureTemplates(Business business) {
    // You can implement feature flags here
    // For now, always show for testing
    return true;
    
    // Future implementation might check:
    // - Business tier/subscription
    // - A/B testing group
    // - Business category eligibility
    // - Geographic rollout
  }
  
  /// Utility: Check if business should see migration suggestions
  bool shouldSuggestMigration(Business business) {
    // Only suggest if they've used legacy templates recently
    // This would check actual usage data
    return false; // Implement based on your usage tracking
  }
  
  /// Hybrid recommendation strategy for simplified UI
  Future<List<Map<String, dynamic>>> getHybridRecommendations(Business business) async {
    final recommendations = <Map<String, dynamic>>[];
    
    // Always include structure templates if enabled
    if (shouldShowStructureTemplates(business)) {
      final context = _contextAnalyzer.analyzeContext(business);
      
      if (context.confidence > 0.6) {
        recommendations.add({
          'type': 'structure',
          'templateId': 'percentage_off',
          'title': '${context.detectedContext!.replaceAll('_', ' ').toUpperCase()} Special',
          'description': context.suggestions['description'] ?? 'Smart optimization for your business',
          'confidence': context.confidence,
          'priority': 'high',
          'benefits': context.suggestions['benefits'] ?? [],
        });
      }
    }
    
    // Add legacy templates as alternatives
    final legacyTemplates = _legacyTemplateManager.getTemplatesForBusiness(business);
    for (final template in legacyTemplates.take(3)) {
      recommendations.add({
        'type': 'legacy',
        'templateId': template.id,
        'title': template.name,
        'description': template.description,
        'confidence': 0.7,
        'priority': 'medium',
        'benefits': ['Proven template', 'Quick setup', 'Reliable performance'],
      });
    }
    
    return recommendations;
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  void clearError() {
    _clearError();
    notifyListeners();
  }
}