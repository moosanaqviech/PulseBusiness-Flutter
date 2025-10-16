// lib/services/simple_database_setup.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleDatabaseSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isInitialized = false;
  
  /// Initialize template system for fresh app (no migration needed)
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔧 Initializing fresh template system...');
      
      // Check if already set up
      final existing = await _firestore
          .collection('global_template_performance')
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        print('✅ Template system already initialized');
        _isInitialized = true;
        return;
      }
      
      // Set up global template performance data
      await _setupGlobalTemplateData();
      
      // Create required collections (they'll be created on first write)
      await _createCollectionStructure();
      
      print('✅ Fresh template system initialized successfully');
      _isInitialized = true;
      
    } catch (e) {
      print('❌ Error initializing template system: $e');
      // Don't throw - app should still work
    }
  }
  
  /// Set up global template performance data
  static Future<void> _setupGlobalTemplateData() async {
    final templateData = [
      {
        'templateId': 'happy_hour',
        'name': 'Happy Hour Special',
        'category': 'timeBased',
        'businessCategories': ['restaurant', 'cafe', 'bar'],
        'globalStats': {
          'avgConversionRate': 28.4,
          'avgRevenue': 450.0,
          'usageCount': 0, // Will grow as businesses use it
          'successRate': 85.2,
        },
        'optimalSettings': {
          'discountRange': [20, 30],
          'bestDays': [2, 3, 4, 5], // Tue-Fri
          'bestHours': [16, 17, 18, 19], // 4-7 PM
          'avgQuantity': 25,
          'avgDurationHours': 3,
        },
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'templateId': 'bogo',
        'name': 'Buy One Get One',
        'category': 'discount',
        'businessCategories': ['cafe', 'shop', 'restaurant'],
        'globalStats': {
          'avgConversionRate': 35.2,
          'avgRevenue': 320.0,
          'usageCount': 0,
          'successRate': 78.9,
        },
        'optimalSettings': {
          'discountRange': [45, 55],
          'bestDays': [6, 7], // Weekends
          'bestHours': [10, 11, 14, 15],
          'avgQuantity': 15,
          'avgDurationDays': 7,
        },
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'templateId': 'flash_sale',
        'name': 'Flash Sale',
        'category': 'inventory',
        'businessCategories': ['shop', 'restaurant', 'cafe'],
        'globalStats': {
          'avgConversionRate': 45.8,
          'avgRevenue': 380.0,
          'usageCount': 0,
          'successRate': 92.1,
        },
        'optimalSettings': {
          'discountRange': [35, 50],
          'bestDays': [2, 3], // Slow days
          'bestHours': [14, 15, 16],
          'avgQuantity': 10,
          'avgDurationHours': 4,
        },
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'templateId': 'first_time_customer',
        'name': 'New Customer Welcome',
        'category': 'customer',
        'businessCategories': [], // All categories
        'globalStats': {
          'avgConversionRate': 31.7,
          'avgRevenue': 290.0,
          'usageCount': 0,
          'successRate': 76.4,
        },
        'optimalSettings': {
          'discountRange': [25, 35],
          'bestDays': [1, 2, 3, 4, 5], // Weekdays
          'bestHours': [11, 12, 17, 18],
          'avgQuantity': 25,
          'avgDurationDays': 30,
        },
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'templateId': 'weekend_special',
        'name': 'Weekend Special',
        'category': 'timeBased',
        'businessCategories': ['restaurant', 'activity', 'cafe'],
        'globalStats': {
          'avgConversionRate': 26.3,
          'avgRevenue': 420.0,
          'usageCount': 0,
          'successRate': 81.7,
        },
        'optimalSettings': {
          'discountRange': [15, 25],
          'bestDays': [6, 7], // Weekends
          'bestHours': [11, 12, 13, 18, 19],
          'avgQuantity': 20,
          'avgDurationDays': 2,
        },
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];
    
    // Batch write all template data
    final batch = _firestore.batch();
    
    for (final template in templateData) {
      final docRef = _firestore
          .collection('global_template_performance')
          .doc(template['templateId'] as String);
      batch.set(docRef, template);
    }
    
    await batch.commit();
    print('✅ Global template data created');
  }
  
  /// Create basic collection structure
  static Future<void> _createCollectionStructure() async {
    // Create collections by adding a single document that can be deleted later
    final collections = {
      'template_usage': {
        'type': 'structure',
        'description': 'Tracks when businesses use templates',
        'createdAt': FieldValue.serverTimestamp(),
      },
      'template_performance': {
        'type': 'structure', 
        'description': 'Business-specific template performance',
        'createdAt': FieldValue.serverTimestamp(),
      },
      'custom_templates': {
        'type': 'structure',
        'description': 'Business-created custom templates', 
        'createdAt': FieldValue.serverTimestamp(),
      },
      'business_template_preferences': {
        'type': 'structure',
        'description': 'Business template preferences and settings',
        'createdAt': FieldValue.serverTimestamp(),
      },
    };
    
    for (final entry in collections.entries) {
      await _firestore
          .collection(entry.key)
          .doc('_structure')
          .set(entry.value);
    }
    
    print('✅ Collection structure created');
  }
  
  /// Clean up structure documents (call after first real data is added)
  static Future<void> cleanupStructureDocuments() async {
    final collections = [
      'template_usage',
      'template_performance', 
      'custom_templates',
      'business_template_preferences',
    ];
    
    final batch = _firestore.batch();
    
    for (final collection in collections) {
      final docRef = _firestore.collection(collection).doc('_structure');
      batch.delete(docRef);
    }
    
    await batch.commit();
    print('✅ Structure documents cleaned up');
  }
  
  /// Initialize template preferences for a new business
  static Future<void> initializeBusinessTemplates(String businessId) async {
    try {
      await _firestore
          .collection('business_template_preferences')
          .doc(businessId)
          .set({
        'businessId': businessId,
        'notifications': {
          'templateRecommendations': true,
          'performanceAlerts': true,
          'newTemplates': false,
        },
        'preferences': {
          'favoriteCategories': [],
          'autoApplyOptimalSettings': true,
          'showAdvancedCustomizations': false,
        },
        'defaults': {
          'defaultQuantity': 20,
          'defaultDurationDays': 7,
          'preferredDiscountRange': [20, 30],
        },
        'stats': {
          'templatesUsed': 0,
          'customDealsCreated': 0,
          'avgTemplatePerformance': 0.0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
      });
      
      print('✅ Business template preferences initialized for: $businessId');
    } catch (e) {
      print('❌ Error initializing business templates: $e');
    }
  }
  
  /// Get setup status
  static Future<Map<String, dynamic>> getSetupStatus() async {
    try {
      final globalTemplates = await _firestore
          .collection('global_template_performance')
          .get();
      
      return {
        'isInitialized': globalTemplates.docs.isNotEmpty,
        'templateCount': globalTemplates.docs.length,
        'collections': [
          'global_template_performance',
          'template_usage',
          'template_performance', 
          'custom_templates',
          'business_template_preferences',
        ],
        'status': 'ready',
      };
    } catch (e) {
      return {
        'isInitialized': false,
        'error': e.toString(),
        'status': 'error',
      };
    }
  }
}