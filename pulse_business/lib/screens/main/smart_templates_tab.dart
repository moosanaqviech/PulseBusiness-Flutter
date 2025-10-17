// lib/screens/main/smart_templates_tab.dart - FIXED VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_business/screens/main/main_screen.dart';
import '../../providers/business_provider.dart';
import '../../services/template_manager.dart';
import '../../models/deal_template.dart';
import '../../models/business.dart';
import '../../utils/theme.dart';
import '../deal_creation/template_deal_creator.dart';

class SmartTemplatesTab extends StatefulWidget {
  const SmartTemplatesTab({super.key});

  @override
  State<SmartTemplatesTab> createState() => _SmartTemplatesTabState();
}

class _SmartTemplatesTabState extends State<SmartTemplatesTab> with AutomaticKeepAliveClientMixin {
  final TemplateManager _templateManager = TemplateManager();
  List<TemplateRecommendation> _recommendations = [];
  List<DealTemplate> _allTemplates = [];
  List<DealTemplate> _filteredTemplates = [];
  TemplateCategory? _selectedCategory;
  bool _isLoadingRecommendations = false;
  bool _isLoadingTemplates = false;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTemplateData();
  }

  Future<void> _loadTemplateData() async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business == null) {
      setState(() {
        _errorMessage = 'Business information not available';
      });
      return;
    }

    setState(() {
      _isLoadingRecommendations = true;
      _isLoadingTemplates = true;
      _errorMessage = null;
    });
    
    try {
      // Load templates first (synchronous)
      final templates = _templateManager.getTemplatesForBusiness(business);
      setState(() {
        _allTemplates = templates;
        _filteredTemplates = templates;
        _isLoadingTemplates = false;
      });

      // Load recommendations (asynchronous)
      final recommendations = await _templateManager.getRecommendations(
        business.id!,
        business,
      );
      
      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load template data: $e';
        _isLoadingRecommendations = false;
        _isLoadingTemplates = false;
      });
    }
  }

  void _filterTemplatesByCategory(TemplateCategory? category) {
    setState(() {
      _selectedCategory = category;
      if (category == null) {
        _filteredTemplates = _allTemplates;
      } else {
        _filteredTemplates = _allTemplates
            .where((template) => template.category == category)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTemplateData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (_errorMessage != null) 
                _buildErrorCard()
              else ...[
                _buildCategoriesSection(),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Templates',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-powered templates to boost your deal performance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                context.push('/template-analytics');
              },
              icon: const Icon(Icons.analytics, color: Colors.white),
              tooltip: 'View Analytics',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
            const SizedBox(height: 12),
            Text(
              'Unable to Load Templates',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTemplateData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse Templates',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        
        // Category chips - FIX: Better scrolling and spacing
        SizedBox(
          height: 40, // FIX: Fixed height
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryChip('All', null),
              const SizedBox(width: 8),
              _buildCategoryChip('⏰ Time-Based', TemplateCategory.timeBased),
              const SizedBox(width: 8),
              _buildCategoryChip('💰 Discount', TemplateCategory.discount),
              const SizedBox(width: 8),
              _buildCategoryChip('🌟 Seasonal', TemplateCategory.seasonal),
              const SizedBox(width: 8),
              _buildCategoryChip('📦 Inventory', TemplateCategory.inventory),
              const SizedBox(width: 8),
              _buildCategoryChip('👥 Customer', TemplateCategory.customer),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Template grid
        _buildTemplateGrid(),
      ],
    );
  }

  Widget _buildCategoryChip(String label, TemplateCategory? category) {
    final isSelected = _selectedCategory == category;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(fontSize: 12), // FIX: Smaller font for chips
      ),
      selected: isSelected,
      onSelected: (selected) => _filterTemplatesByCategory(selected ? category : null),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // FIX: Compact size
    );
  }

  Widget _buildTemplateGrid() {
    if (_isLoadingTemplates) {
      return _buildLoadingState('Loading templates...');
    }
    
    if (_filteredTemplates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No templates found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            if (_selectedCategory != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _filterTemplatesByCategory(null),
                child: const Text('Show All Templates'),
              ),
            ],
          ],
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0, // FIX: Better aspect ratio
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(DealTemplate template) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () => _useTemplate(template),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: template.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10), // FIX: Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      template.icon,
                      style: const TextStyle(fontSize: 24), // FIX: Smaller icon
                    ),
                    const Spacer(),
                    if (template.isNew) _buildBadge('NEW', Colors.green),
                    if (template.isPopular && !template.isNew) 
                      _buildBadge('POPULAR', Colors.orange),
                  ],
                ),
                const SizedBox(height: 6), // FIX: Reduced spacing
                Expanded( // FIX: Use Expanded to manage space
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13, // FIX: Smaller font
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded( // FIX: Use remaining space
                        child: Text(
                          template.shortDescription,
                          style: TextStyle(
                            fontSize: 10, // FIX: Smaller font
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 3, // FIX: Allow more lines
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (template.averageConversionRate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: template.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${template.averageConversionRate!.toStringAsFixed(1)}% avg',
                      style: TextStyle(
                        fontSize: 9, // FIX: Smaller font
                        fontWeight: FontWeight.bold,
                        color: template.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8, // FIX: Smaller badge text
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildLoadingState(String message) {
    return Container(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceInsightsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Expanded( // FIX: Prevent overflow
                  child: Text(
                    'Performance Insights',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Template Success',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        '+31%',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'vs. custom deals',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: AppTheme.primaryColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Best Time',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Fri 4-6 PM',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'highest conversions',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View Full Analytics'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add missing method implementations
  void _useTemplate(DealTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateDealCreator(
          template: template,
          business: Provider.of<BusinessProvider>(context, listen: false).currentBusiness!,
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template Help'),
        content: const Text(
          'Smart templates use AI to create optimized deals based on your business type and past performance. Choose a template that matches your goal and we\'ll guide you through the setup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}