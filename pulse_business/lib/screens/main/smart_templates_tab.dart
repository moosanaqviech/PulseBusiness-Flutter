// lib/screens/main/smart_templates_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_business/screens/main/main_screen.dart';
import '../../providers/business_provider.dart';
import '../../services/template_manager.dart';
import '../../models/deal_template.dart';
import '../../models/business.dart';
import '../../utils/theme.dart';
//import '../deal_creation/template_deal_creator.dart';

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
                _buildRecommendationsSection(),
                const SizedBox(height: 24),
                _buildQuickActionsSection(),
                const SizedBox(height: 24),
                _buildCategoriesSection(),
                const SizedBox(height: 24),
                _buildPerformanceInsightsSection(),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
                ),
                maxLines: 1, // ✅ FIXED: Added maxLines
                overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
              ),
              const SizedBox(height: 4),
              Text(
                'AI-powered templates to boost your deal performance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                maxLines: 2, // ✅ FIXED: Added maxLines
                overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            context.push('/template-analytics');
          },
          icon: const Icon(Icons.analytics, color: Colors.white),
          tooltip: 'View Analytics',
        ),
      ],
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
              maxLines: 1, // ✅ FIXED: Added maxLines
              overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
              maxLines: 3, // ✅ FIXED: Added maxLines
              overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
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

  Widget _buildRecommendationsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Expanded( // ✅ FIXED: Added Expanded
                  child: Text(
                    'Recommended for You Today',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    maxLines: 1, // ✅ FIXED: Added maxLines
                    overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                  ),
                ),
                if (_isLoadingRecommendations)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by AI and your business performance data',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isLoadingRecommendations)
              _buildLoadingState('Loading recommendations...')
            else if (_recommendations.isEmpty)
              _buildEmptyRecommendations()
            else
              _buildRecommendationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendations() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Getting Ready...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a few deals first to get personalized AI recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateDeal(),
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Deal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return Column(
      children: _recommendations.map((recommendation) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                recommendation.template.primaryColor.withOpacity(0.1),
                recommendation.template.primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: recommendation.template.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recommendation.template.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.template.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            recommendation.reason,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildConfidenceScore(recommendation.confidenceScore),
                  ],
                ),
                
                if (recommendation.predictions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (recommendation.predictions['expectedConversion'] != null)
                        _buildPredictionChip(
                          '${recommendation.predictions['expectedConversion'].toStringAsFixed(1)}% conversion',
                          Colors.green,
                        ),
                      if (recommendation.predictions['expectedRevenue'] != null)
                        _buildPredictionChip(
                          '\$${recommendation.predictions['expectedRevenue'].toStringAsFixed(0)} revenue',
                          Colors.blue,
                        ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _useTemplate(recommendation.template),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: recommendation.template.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                    child: Text('Use ${recommendation.template.name}'),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfidenceScore(double score) {
    final percentage = (score * 100).round();
    final color = score >= 0.8 ? Colors.green : 
                  score >= 0.6 ? Colors.orange : Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$percentage% confidence',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPredictionChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.add_circle,
            title: 'Create Deal Now',
            subtitle: 'Start with a template',
            color: AppTheme.primaryColor,
            onTap: () => _showTemplateSelection(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.analytics,
            title: 'View Performance',
            subtitle: 'Template analytics',
            color: Colors.blue,
            onTap: () {
              context.push('/template-analytics');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.help_outline,
            title: 'Need Help?',
            subtitle: 'Template guides',
            color: Colors.orange,
            onTap: () => _showHelpDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Category chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
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
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _filterTemplatesByCategory(selected ? category : null),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
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
        childAspectRatio: 1.1,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      template.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const Spacer(),
                    if (template.isNew) _buildBadge('NEW', Colors.green),
                    if (template.isPopular && !template.isNew) 
                      _buildBadge('POPULAR', Colors.orange),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  template.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  template.shortDescription,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
               
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
          fontSize: 8,
          fontWeight: FontWeight.bold,
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
                Icon(Icons.insights, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Performance Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    title: 'Template Success',
                    value: '+31%',
                    subtitle: 'vs custom deals',
                    color: Colors.green,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    title: 'Best Time',
                    value: 'Fri 4-6 PM',
                    subtitle: 'highest conversion',
                    color: Colors.blue,
                    icon: Icons.access_time,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Detailed Analytics'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _useTemplate(DealTemplate template) {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business != null) {
      context.push('/template-deal-creator', extra: {
        'template': template,
        'business': business,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business information not available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToCreateDeal() {
    _showTemplateSelection();
  }

  void _showTemplateSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Choose a Template',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _allTemplates.length,
                    itemBuilder: (context, index) {
                      final template = _allTemplates[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Text(
                            template.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            template.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(template.shortDescription),
                          trailing: template.averageConversionRate != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: template.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${template.averageConversionRate!.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: template.primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () {
                            context.pop();
                            _useTemplate(template);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smart Templates Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Smart Templates help you create high-performing deals quickly:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('🎯 AI Recommendations - Get personalized suggestions'),
              SizedBox(height: 8),
              Text('⚡ Quick Creation - Professional deals in 60 seconds'),
              SizedBox(height: 8),
              Text('📊 Performance Data - See what works best'),
              SizedBox(height: 8),
              Text('🔧 Easy Customization - Adjust to your needs'),
              SizedBox(height: 12),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Start with recommended templates for best results'),
              SizedBox(height: 4),
              Text('• Customize prices and quantities for your business'),
              SizedBox(height: 4),
              Text('• Check analytics to see which templates work best'),
              SizedBox(height: 4),
              Text('• Use seasonal templates during relevant periods'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }
}

// Template Analytics Screen placeholder - Remove this since we're using go_router
// The analytics screen should be defined in your router configuration