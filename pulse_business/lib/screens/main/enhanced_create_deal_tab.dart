// lib/screens/main/enhanced_create_deal_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_provider.dart';
import '../../services/template_manager.dart';
import '../../models/deal_template.dart';
import '../deal_creation/template_deal_creator.dart';
import '../../utils/theme.dart';
import 'create_deal_tab.dart';

class EnhancedCreateDealTab extends StatefulWidget {
  const EnhancedCreateDealTab({super.key});

  @override
  State<EnhancedCreateDealTab> createState() => _EnhancedCreateDealTabState();
}

class _EnhancedCreateDealTabState extends State<EnhancedCreateDealTab> {
  final TemplateManager _templateManager = TemplateManager();
  bool _showTemplateSelection = true;
  List<DealTemplate> _recentTemplates = [];
  List<DealTemplate> _recommendedTemplates = [];
  List<DealTemplate> _allTemplates = [];
  TemplateCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadTemplateData();
  }

  Future<void> _loadTemplateData() async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business != null) {
      try {
        // Get all templates for this business
        final templates = _templateManager.getTemplatesForBusiness(business);
        
        // Get recommendations
        final recommendations = await _templateManager.getRecommendations(
          business.id!,
          business,
        );
        
        setState(() {
          _allTemplates = templates;
          _recommendedTemplates = recommendations.map((r) => r.template).toList();
          // For now, use recommended as recent - later can track actual recent usage
          _recentTemplates = recommendations.take(3).map((r) => r.template).toList();
        });
      } catch (e) {
        debugPrint('Error loading template data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showTemplateSelection 
          ? _buildTemplateSelection()
          : _buildCreationMethodChoice(),
    );
  }

  Widget _buildTemplateSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildQuickTemplates(),
          const SizedBox(height: 24),
          _buildRecommendedSection(),
          const SizedBox(height: 24),
          _buildAllTemplatesSection(),
          const SizedBox(height: 80), // Space for bottom button
        ],
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
                    'Choose a template for faster, better-performing deals',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _showTemplateSelection = false),
              child: const Text('Create Custom'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickTemplates() {
    if (_recentTemplates.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Start',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Based on your recent activity',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _recentTemplates.map((template) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: _buildQuickTemplateCard(template),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTemplateCard(DealTemplate template) {
    return GestureDetector(
      onTap: () => _useTemplate(template),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              template.primaryColor,
              template.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: template.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  template.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              template.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            if (template.averageConversionRate != null)
              Text(
                '${template.averageConversionRate!.toStringAsFixed(1)}% avg conversion',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    if (_recommendedTemplates.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Recommended for You',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'AI-powered suggestions based on your business',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        ..._recommendedTemplates.take(3).map((template) => 
          _buildRecommendedTemplateCard(template)
        ),
      ],
    );
  }

  Widget _buildRecommendedTemplateCard(DealTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          onTap: () => _useTemplate(template),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: template.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    template.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        template.shortDescription,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (template.averageConversionRate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${template.averageConversionRate!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Templates',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Category filter chips
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
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildTemplateGrid() {
    final filteredTemplates = _selectedCategory == null
        ? _allTemplates
        : _allTemplates.where((template) => template.category == _selectedCategory).toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = filteredTemplates[index];
        return _buildTemplateGridCard(template);
      },
    );
  }

  Widget _buildTemplateGridCard(DealTemplate template) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _useTemplate(template),
        borderRadius: BorderRadius.circular(8),
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
              if (template.averageConversionRate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: template.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '\${template.averageConversionRate!.toStringAsFixed(1)}% avg',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: template.primaryColor,
                    ),
                  ),
                ),
            ],
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

  Widget _buildCreationMethodChoice() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'How would you like to create your deal?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Template option
          _buildCreationMethodCard(
            icon: Icons.auto_awesome,
            title: 'Use Smart Template',
            subtitle: 'Faster creation with proven performance',
            benefits: [
              'AI-powered suggestions',
              'Optimized for conversion',
              'Professional quality',
              'Save time',
            ],
            color: AppTheme.primaryColor,
            isRecommended: true,
            onTap: () => setState(() => _showTemplateSelection = true),
          ),
          
          const SizedBox(height: 16),
          
          // Custom option
          _buildCreationMethodCard(
            icon: Icons.edit,
            title: 'Create Custom Deal',
            subtitle: 'Full control over every detail',
            benefits: [
              'Complete customization',
              'Unique messaging',
              'Custom pricing strategy',
              'Full flexibility',
            ],
            color: Colors.grey.shade700,
            isRecommended: false,
            onTap: _createCustomDeal,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Tip: Templates perform 31% better on average',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCreationMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> benefits,
    required Color color,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isRecommended ? Border.all(color: color, width: 2) : null,
          ),
          child: Column(
            children: [
              if (isRecommended)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(
                      benefit,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Choose ${title.split(' ').first}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _useTemplate(DealTemplate template) {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplateDealCreator(
            template: template,
            business: business,
          ),
        ),
      );
    }
  }

  void _createCustomDeal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateDealTab(), // Your existing create deal screen
      ),
    );
  }
}