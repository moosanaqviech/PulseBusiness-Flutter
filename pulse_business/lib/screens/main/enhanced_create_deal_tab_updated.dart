// lib/screens/main/enhanced_create_deal_tab_updated.dart
// Final working version that properly integrates with the deal creation flow

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_provider.dart';
import '../../services/hybrid_template_manager.dart';
import '../deal_creation/enhanced_deal_creation_screen.dart';
import '../deal_creation/template_deal_creator.dart';
import '../../utils/theme.dart';
import 'create_deal_tab.dart';

class EnhancedCreateDealTabUpdated extends StatefulWidget {
  const EnhancedCreateDealTabUpdated({super.key});

  @override
  State<EnhancedCreateDealTabUpdated> createState() => _EnhancedCreateDealTabUpdatedState();
}

class _EnhancedCreateDealTabUpdatedState extends State<EnhancedCreateDealTabUpdated> {
  final HybridTemplateManager _hybridManager = HybridTemplateManager();
  bool _showTemplateSelection = true;
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Business information not available';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final recommendations = await _hybridManager.getHybridRecommendations(business);
      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load recommendations: $e';
        });
      }
      debugPrint('Error loading recommendations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showTemplateSelection 
          ? _buildTemplateSelection()
          : _buildCustomCreation(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToStructureTemplate('percentage_off'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Quick Deal'),
      ),
    );
  }
  
  Widget _buildTemplateSelection() {
    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            
            if (_isLoading)
              _buildLoadingState()
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_recommendations.isEmpty)
              _buildEmptyState()
            else
              _buildRecommendationsList(),
            
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a Deal',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose from smart suggestions or create a custom deal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _showTemplateSelection = false),
              icon: const Icon(Icons.tune),
              tooltip: 'Custom Deal',
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading smart suggestions...'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load suggestions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadRecommendations,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => setState(() => _showTemplateSelection = false),
                  child: const Text('Create Custom'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Ready to Create Deals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the Quick Deal button or create a custom deal',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToStructureTemplate('percentage_off'),
              icon: const Icon(Icons.percent),
              label: const Text('Create Percentage Off Deal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendationsList() {
    // Safely filter recommendations
    final smartRecommendations = _recommendations.where((r) {
      final confidence = r['confidence'];
      return confidence is double && confidence > 0.6;
    }).toList();
    
    final regularRecommendations = _recommendations.where((r) {
      final confidence = r['confidence'];
      return confidence == null || (confidence is double && confidence <= 0.6);
    }).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Smart recommendations section
        if (smartRecommendations.isNotEmpty) ...[
          _buildSectionHeader(
            'Smart Suggestions',
            Icons.auto_awesome,
            Colors.amber.shade600,
            'Based on your business and current time',
          ),
          const SizedBox(height: 12),
          ...smartRecommendations.map((recommendation) => 
            _buildRecommendationCard(recommendation, isHighlighted: true)),
          const SizedBox(height: 24),
        ],
        
        // Quick access section
        _buildQuickAccessSection(),
        const SizedBox(height: 24),
        
        // Regular recommendations section
        if (regularRecommendations.isNotEmpty) ...[
          _buildSectionHeader(
            'All Templates',
            Icons.category,
            Colors.grey.shade600,
            'Proven templates for any occasion',
          ),
          const SizedBox(height: 12),
          ...regularRecommendations.map((recommendation) => 
            _buildRecommendationCard(recommendation)),
        ],
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon, Color color, [String? subtitle]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Quick Create',
          Icons.flash_on,
          Colors.blue.shade600,
          'Popular deal types for fast creation',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                'Percentage Off',
                'Most popular deal type',
                Icons.percent,
                Colors.green,
                () => _navigateToStructureTemplate('percentage_off'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAccessCard(
                'Custom Deal',
                'Full customization',
                Icons.tune,
                Colors.blue,
                () => setState(() => _showTemplateSelection = false),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildQuickAccessCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecommendationCard(Map<String, dynamic> recommendation, {bool isHighlighted = false}) {
    final title = recommendation['title']?.toString() ?? 'Untitled Template';
    final description = recommendation['description']?.toString() ?? 'No description available';
    final type = recommendation['type']?.toString() ?? 'unknown';
    final benefits = recommendation['benefits'] as List<dynamic>? ?? [];
    final confidence = recommendation['confidence'] as double?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isHighlighted ? 4 : 2,
        color: isHighlighted ? Colors.blue.shade50 : null,
        child: InkWell(
          onTap: () => _selectTemplate(recommendation),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isHighlighted) ...[
                      Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isHighlighted ? Colors.blue.shade800 : null,
                        ),
                      ),
                    ),
                    if (type == 'structure')
                      _buildSmartBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                if (benefits.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildBenefitsChips(benefits.take(3).toList()),
                ],
                if (confidence != null && confidence > 0.8) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Highly Recommended',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSmartBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Text(
        'Smart',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        ),
      ),
    );
  }
  
  Widget _buildBenefitsChips(List<dynamic> benefits) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: benefits.map((benefit) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          benefit.toString(),
          style: const TextStyle(fontSize: 10),
        ),
      )).toList(),
    );
  }
  
  void _selectTemplate(Map<String, dynamic> recommendation) {
    final type = recommendation['type']?.toString();
    final templateId = recommendation['templateId']?.toString();
    
    if (templateId == null) {
      _showError('Template ID not available');
      return;
    }
    
    try {
      if (type == 'structure') {
        _navigateToStructureTemplate(templateId);
      } else if (type == 'legacy') {
        _navigateToLegacyTemplate(templateId);
      } else {
        _showError('Unknown template type: $type');
      }
    } catch (e) {
      _showError('Error opening template: $e');
    }
  }
  
  void _navigateToStructureTemplate(String templateId) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const EnhancedDealCreationScreen(),
        ),
      );
    } catch (e) {
      _showError('Error opening template: $e');
    }
  }
  
  void _navigateToLegacyTemplate(String templateId) {
    try {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      final business = businessProvider.currentBusiness;
      
      if (business == null) {
        _showError('Business information not available');
        return;
      }
      
      final legacyTemplates = _hybridManager.getLegacyTemplates(business);
      final legacyTemplate = IterableExtension(legacyTemplates.where((template) => template.id == templateId)).firstOrNull;
      
      if (legacyTemplate == null) {
        _showError('Legacy template not found: $templateId');
        return;
      }
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TemplateDealCreator(
            template: legacyTemplate,
            business: business,
          ),
        ),
      );
    } catch (e) {
      _showError('Error opening legacy template: $e');
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Create Custom',
            textColor: Colors.white,
            onPressed: () => setState(() => _showTemplateSelection = false),
          ),
        ),
      );
    }
  }
  
  Widget _buildCustomCreation() {
    return const CreateDealTab();
  }
}

// Extension to safely get first element or null
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}