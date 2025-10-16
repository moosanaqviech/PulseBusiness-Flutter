// lib/services/template_manager.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deal_template.dart';
import '../models/business.dart';
import '../models/deal.dart';

class TemplateManager extends ChangeNotifier {
  static final TemplateManager _instance = TemplateManager._internal();
  factory TemplateManager() => _instance;
  TemplateManager._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Template registry
  static final Map<String, DealTemplate> _templates = {
    'happy_hour': HappyHourTemplate(),
    'bogo': BOGOTemplate(),
    'flash_sale': FlashSaleTemplate(),
    'first_time_customer': FirstTimeCustomerTemplate(),
    'weekend_special': WeekendSpecialTemplate(),
  };
  
  // Cache for performance data
  Map<String, TemplatePerformanceData> _performanceCache = {};
  Map<String, List<TemplateRecommendation>> _recommendationCache = {};
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Get all available templates
  List<DealTemplate> getAllTemplates() {
    return _templates.values.toList();
  }
  
  // Get templates for specific business
  List<DealTemplate> getTemplatesForBusiness(Business business) {
    return _templates.values
        .where((template) => template.isApplicableFor(business))
        .where((template) => template.isAvailable)
        .toList();
  }
  
  // Get templates by category
  List<DealTemplate> getTemplatesByCategory(TemplateCategory category) {
    return _templates.values
        .where((template) => template.category == category)
        .where((template) => template.isAvailable)
        .toList();
  }
  
  // Get single template
  DealTemplate? getTemplate(String templateId) {
    return _templates[templateId];
  }
  
  // Get personalized recommendations
  Future<List<TemplateRecommendation>> getRecommendations(
    String businessId,
    Business business,
  ) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Check cache first
      if (_recommendationCache.containsKey(businessId)) {
        final cached = _recommendationCache[businessId]!;
        if (cached.isNotEmpty) {
          return cached;
        }
      }
      
      // Generate AI recommendations
      final recommendations = await _generateAIRecommendations(businessId, business);
      
      // Cache results
      _recommendationCache[businessId] = recommendations;
      
      return recommendations;
    } catch (e) {
      _setError('Failed to get recommendations: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  Future<List<TemplateRecommendation>> _generateAIRecommendations(
    String businessId,
    Business business,
  ) async {
    final recommendations = <TemplateRecommendation>[];
    
    // 1. Time-based recommendations
    final timeBasedRec = await _getTimeBasedRecommendations(business);
    recommendations.addAll(timeBasedRec);
    
    // 2. Performance-based recommendations
    final performanceRec = await _getPerformanceBasedRecommendations(businessId, business);
    recommendations.addAll(performanceRec);
    
    // 3. Seasonal recommendations
    final seasonalRec = await _getSeasonalRecommendations(business);
    recommendations.addAll(seasonalRec);
    
    // 4. Market trend recommendations
    final trendRec = await _getTrendRecommendations(business);
    recommendations.addAll(trendRec);
    
    // Sort by confidence score and return top 3
    recommendations.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return recommendations.take(3).toList();
  }
  
  Future<List<TemplateRecommendation>> _getTimeBasedRecommendations(Business business) async {
    final now = DateTime.now();
    final recommendations = <TemplateRecommendation>[];
    
    // Happy Hour recommendation for restaurants during weekdays 3-5 PM
    if (business.category.toLowerCase() == 'restaurant' && 
        now.weekday <= 5 && 
        now.hour >= 15 && 
        now.hour <= 17) {
      recommendations.add(TemplateRecommendation(
        template: _templates['happy_hour']!,
        confidenceScore: 0.85,
        reason: 'Perfect timing for happy hour - weekday afternoon attracts after-work crowd',
        predictions: {'expectedConversion': 32.0, 'expectedRevenue': 450.0},
        priority: TemplatePriority.high,
      ));
    }
    
    // Weekend Special for Friday/Saturday
    if (now.weekday == 5 || now.weekday == 6) {
      recommendations.add(TemplateRecommendation(
        template: _templates['weekend_special']!,
        confidenceScore: 0.75,
        reason: 'Weekend approaching - capitalize on leisure spending',
        predictions: {'expectedConversion': 28.0, 'expectedRevenue': 380.0},
      ));
    }
    
    // Flash Sale for slow periods (Tuesday/Wednesday 2-4 PM)
    if ((now.weekday == 2 || now.weekday == 3) && 
        now.hour >= 14 && 
        now.hour <= 16) {
      recommendations.add(TemplateRecommendation(
        template: _templates['flash_sale']!,
        confidenceScore: 0.70,
        reason: 'Slow period detected - flash sale can boost midweek traffic',
        predictions: {'expectedConversion': 45.0, 'expectedRevenue': 320.0},
      ));
    }
    
    return recommendations;
  }
  
  Future<List<TemplateRecommendation>> _getPerformanceBasedRecommendations(
    String businessId, 
    Business business
  ) async {
    final recommendations = <TemplateRecommendation>[];
    
    try {
      // Get historical performance for this business
      final performanceData = await _getBusinessPerformanceData(businessId);
      
      // Find best performing template types
      final bestTemplate = _findBestPerformingTemplate(performanceData);
      
      if (bestTemplate != null) {
        recommendations.add(TemplateRecommendation(
          template: bestTemplate,
          confidenceScore: 0.90,
          reason: 'Your ${bestTemplate.name} deals have highest conversion rate (${_getTemplateConversion(bestTemplate.id, performanceData).toStringAsFixed(1)}%)',
          predictions: {
            'expectedConversion': _getTemplateConversion(bestTemplate.id, performanceData),
            'expectedRevenue': _getTemplateRevenue(bestTemplate.id, performanceData),
          },
        ));
      }
      
      // Recommend templates user hasn't tried yet
      final unusedTemplates = _getUnusedTemplates(performanceData, business);
      for (final template in unusedTemplates.take(1)) {
        recommendations.add(TemplateRecommendation(
          template: template,
          confidenceScore: 0.65,
          reason: 'Haven\'t tried ${template.name} yet - similar businesses see ${template.averageConversionRate?.toStringAsFixed(1) ?? '25'}% conversion',
          predictions: {
            'expectedConversion': template.averageConversionRate ?? 25.0,
            'expectedRevenue': 300.0,
          },
        ));
      }
    } catch (e) {
      debugPrint('Error getting performance recommendations: $e');
    }
    
    return recommendations;
  }
  
  Future<List<TemplateRecommendation>> _getSeasonalRecommendations(Business business) async {
    final now = DateTime.now();
    final recommendations = <TemplateRecommendation>[];
    
    // Holiday season recommendations (November-December)
    if (now.month >= 11) {
      // Could add HolidaySpecialTemplate here
      recommendations.add(TemplateRecommendation(
        template: _templates['first_time_customer']!,
        confidenceScore: 0.80,
        reason: 'Holiday shopping season - attract gift buyers with new customer deals',
        predictions: {'expectedConversion': 35.0, 'expectedRevenue': 420.0},
      ));
    }
    
    // Summer cooling (June-August) for restaurants/cafes
    if (now.month >= 6 && now.month <= 8 && 
        (business.category.toLowerCase() == 'restaurant' || 
         business.category.toLowerCase() == 'cafe')) {
      // Could add SummerSpecialTemplate here
      recommendations.add(TemplateRecommendation(
        template: _templates['happy_hour']!,
        confidenceScore: 0.70,
        reason: 'Summer heat drives demand for cold drinks - perfect for happy hour',
        predictions: {'expectedConversion': 30.0, 'expectedRevenue': 380.0},
      ));
    }
    
    // Back to school (August 15-September 15)
    if ((now.month == 8 && now.day >= 15) || 
        (now.month == 9 && now.day <= 15)) {
      recommendations.add(TemplateRecommendation(
        template: _templates['first_time_customer']!,
        confidenceScore: 0.75,
        reason: 'Back-to-school period - students and families looking for deals',
        predictions: {'expectedConversion': 32.0, 'expectedRevenue': 350.0},
      ));
    }
    
    return recommendations;
  }
  
  Future<List<TemplateRecommendation>> _getTrendRecommendations(Business business) async {
    final recommendations = <TemplateRecommendation>[];
    
    // BOGO trending for retail and cafes
    if (business.category.toLowerCase() == 'shop' || 
        business.category.toLowerCase() == 'cafe') {
      recommendations.add(TemplateRecommendation(
        template: _templates['bogo']!,
        confidenceScore: 0.68,
        reason: 'BOGO deals trending 25% higher engagement this month',
        predictions: {'expectedConversion': 35.0, 'expectedRevenue': 290.0},
      ));
    }
    
    // Flash sales performing well across all categories
    recommendations.add(TemplateRecommendation(
      template: _templates['flash_sale']!,
      confidenceScore: 0.72,
      reason: 'Flash sales seeing 40% higher conversion rates market-wide',
      predictions: {'expectedConversion': 45.0, 'expectedRevenue': 380.0},
    ));
    
    return recommendations;
  }
  
  // Get template performance for business
  Future<TemplatePerformanceData?> getTemplatePerformance(
    String businessId, 
    String templateId
  ) async {
    try {
      final key = '${businessId}_$templateId';
      
      // Check cache first
      if (_performanceCache.containsKey(key)) {
        return _performanceCache[key];
      }
      
      // Query Firestore
      final doc = await _firestore
          .collection('template_performance')
          .doc(key)
          .get();
      
      if (doc.exists) {
        final performance = TemplatePerformanceData.fromMap(doc.data()!);
        _performanceCache[key] = performance;
        return performance;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting template performance: $e');
      return null;
    }
  }
  
  // Track template usage
  Future<void> trackTemplateUsage(
    String businessId,
    String templateId,
    String dealId,
    Map<String, dynamic> customizations,
  ) async {
    try {
      await _firestore.collection('template_usage').add({
        'businessId': businessId,
        'templateId': templateId,
        'dealId': dealId,
        'customizations': customizations,
        'usedAt': FieldValue.serverTimestamp(),
      });
      
      // Update performance cache
      await _updateTemplatePerformanceCache(businessId, templateId);
    } catch (e) {
      debugPrint('Error tracking template usage: $e');
    }
  }
  
  // Update template performance when deal completes
  Future<void> updateTemplatePerformance(
    String businessId,
    String templateId,
    double conversionRate,
    double revenue,
  ) async {
    try {
      final key = '${businessId}_$templateId';
      final docRef = _firestore.collection('template_performance').doc(key);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final data = doc.data()!;
          final currentUsage = data['usageCount'] ?? 0;
          final currentRevenue = data['totalRevenue'] ?? 0.0;
          final currentConversion = data['averageConversion'] ?? 0.0;
          
          // Calculate new averages
          final newUsageCount = currentUsage + 1;
          final newTotalRevenue = currentRevenue + revenue;
          final newAverageConversion = ((currentConversion * currentUsage) + conversionRate) / newUsageCount;
          
          transaction.update(docRef, {
            'usageCount': newUsageCount,
            'totalRevenue': newTotalRevenue,
            'averageConversion': newAverageConversion,
            'lastUsed': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(docRef, {
            'templateId': templateId,
            'businessId': businessId,
            'usageCount': 1,
            'totalRevenue': revenue,
            'averageConversion': conversionRate,
            'lastUsed': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
      // Clear cache to force refresh
      _performanceCache.remove(key);
    } catch (e) {
      debugPrint('Error updating template performance: $e');
    }
  }
  
  // Helper methods
  Future<Map<String, TemplatePerformanceData>> _getBusinessPerformanceData(String businessId) async {
    try {
      final querySnapshot = await _firestore
          .collection('template_performance')
          .where('businessId', isEqualTo: businessId)
          .get();
      
      final performanceMap = <String, TemplatePerformanceData>{};
      for (final doc in querySnapshot.docs) {
        final data = TemplatePerformanceData.fromMap(doc.data());
        performanceMap[data.templateId] = data;
      }
      
      return performanceMap;
    } catch (e) {
      debugPrint('Error getting business performance data: $e');
      return {};
    }
  }
  
  DealTemplate? _findBestPerformingTemplate(Map<String, TemplatePerformanceData> performanceData) {
    if (performanceData.isEmpty) return null;
    
    String? bestTemplateId;
    double bestConversion = 0.0;
    
    for (final entry in performanceData.entries) {
      if (entry.value.conversionRate > bestConversion && entry.value.usageCount >= 2) {
        bestConversion = entry.value.conversionRate;
        bestTemplateId = entry.key;
      }
    }
    
    return bestTemplateId != null ? _templates[bestTemplateId] : null;
  }
  
  double _getTemplateConversion(String templateId, Map<String, TemplatePerformanceData> performanceData) {
    return performanceData[templateId]?.conversionRate ?? 0.0;
  }
  
  double _getTemplateRevenue(String templateId, Map<String, TemplatePerformanceData> performanceData) {
    return performanceData[templateId]?.averageRevenue ?? 0.0;
  }
  
  List<DealTemplate> _getUnusedTemplates(Map<String, TemplatePerformanceData> performanceData, Business business) {
    final usedTemplateIds = performanceData.keys.toSet();
    return _templates.values
        .where((template) => !usedTemplateIds.contains(template.id))
        .where((template) => template.isApplicableFor(business))
        .toList();
  }
  
  Future<void> _updateTemplatePerformanceCache(String businessId, String templateId) async {
    final key = '${businessId}_$templateId';
    _performanceCache.remove(key); // Force refresh on next access
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
  
  // Clear caches (useful for testing or manual refresh)
  void clearCaches() {
    _performanceCache.clear();
    _recommendationCache.clear();
    notifyListeners();
  }
}

// Template Repository for Firestore operations
class TemplateRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Save custom template
  static Future<String> saveCustomTemplate(
    String businessId,
    String templateName,
    Deal baseDeal,
    Map<String, dynamic> templateConfig,
  ) async {
    try {
      final docRef = await _firestore.collection('custom_templates').add({
        'businessId': businessId,
        'templateName': templateName,
        'baseDeal': baseDeal.toMap(),
        'templateConfig': templateConfig,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'usageCount': 0,
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save custom template: $e');
    }
  }
  
  // Get custom templates for business
  static Future<List<Map<String, dynamic>>> getCustomTemplates(String businessId) async {
    try {
      final querySnapshot = await _firestore
          .collection('custom_templates')
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get custom templates: $e');
    }
  }
  
  // Get template analytics for business
  static Future<Map<String, dynamic>> getTemplateAnalytics(
    String businessId, {
    int days = 30,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      // Get template usage data
      final usageQuery = await _firestore
          .collection('template_usage')
          .where('businessId', isEqualTo: businessId)
          .where('usedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('usedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      // Get performance data
      final performanceQuery = await _firestore
          .collection('template_performance')
          .where('businessId', isEqualTo: businessId)
          .get();
      
      // Process data
      final templateUsage = <String, int>{};
      final templateRevenue = <String, double>{};
      final templateConversions = <String, List<double>>{};
      
      for (final doc in usageQuery.docs) {
        final templateId = doc.data()['templateId'] as String;
        templateUsage[templateId] = (templateUsage[templateId] ?? 0) + 1;
      }
      
      for (final doc in performanceQuery.docs) {
        final data = doc.data();
        final templateId = data['templateId'] as String;
        templateRevenue[templateId] = data['totalRevenue']?.toDouble() ?? 0.0;
        templateConversions[templateId] = [data['averageConversion']?.toDouble() ?? 0.0];
      }
      
      return {
        'templateUsage': templateUsage,
        'templateRevenue': templateRevenue,
        'templateConversions': templateConversions,
        'totalTemplatesUsed': templateUsage.length,
        'totalUsage': templateUsage.values.fold(0, (sum, count) => sum + count),
        'averageConversion': templateConversions.values
            .expand((list) => list)
            .fold(0.0, (sum, conv) => sum + conv) / 
            (templateConversions.values.length == 0 ? 1 : templateConversions.values.length),
      };
    } catch (e) {
      throw Exception('Failed to get template analytics: $e');
    }
  }
}