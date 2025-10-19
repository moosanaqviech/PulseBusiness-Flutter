// lib/screens/deal_creation/enhanced_deal_creation_screen.dart - FIXED OVERFLOW ISSUES

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pulse_business/models/deal_template.dart' hide FlashSaleTemplate;
import 'dart:io';

import '../../models/business.dart';
import '../../models/deal_structure_templates.dart';
import '../../providers/business_provider.dart';
import '../../providers/deals_provider.dart';
import '../../services/context_analyzer.dart';
import '../../services/template_transformation_service.dart';
import '../../utils/theme.dart';

class EnhancedDealCreationScreen extends StatefulWidget {
  const EnhancedDealCreationScreen({super.key});

  @override
  State<EnhancedDealCreationScreen> createState() => _EnhancedDealCreationScreenState();
}

class _EnhancedDealCreationScreenState extends State<EnhancedDealCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Services
  final ContextAnalyzer _contextAnalyzer = ContextAnalyzer();
  final TemplateTransformationService _transformationService = TemplateTransformationService();
  
  // Available templates
  final List<DealStructureTemplate> _availableTemplates = [
    PercentageOffTemplate(),
    ComboDealTemplate(),
    FlashSaleTemplate()
  ];
  
  // State
  DealStructureTemplate? _selectedTemplate;
  TemplateContext? _detectedContext;
  Map<String, dynamic> _templateData = {};
  Map<String, TextEditingController> _controllers = {};
  bool _showContextSuggestion = false;
  bool _acceptedContextSuggestion = false;
  File? _selectedImage;
  int _currentPage = 0;
  bool _isCreating = false;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _analyzeCurrentContext();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
  
  void _analyzeCurrentContext() {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business != null) {
      _detectedContext = _contextAnalyzer.analyzeContext(business);
      
      if (_detectedContext!.confidence > 0.6) {
        setState(() {
          _showContextSuggestion = true;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Deal',
          maxLines: 1, // ✅ FIXED: Added maxLines
          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Context suggestion banner
          //if (_showContextSuggestion && !_acceptedContextSuggestion)
          //  _buildContextSuggestionBanner(),
          
          // Main content
          Expanded(
            child: IndexedStack(
              index: _currentPage,
              children: [
                _buildTemplateSelectionPage(),
                if (_selectedTemplate != null) _buildTemplateConfigurationPage(),
                if (_selectedTemplate != null) _buildPreviewAndConfirmPage(),
              ],
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildProgressStep(0, 'Template', Icons.category),
          _buildProgressLine(0),
          _buildProgressStep(1, 'Configure', Icons.tune),
          _buildProgressLine(1),
          _buildProgressStep(2, 'Preview', Icons.preview),
        ],
      ),
    );
  }
  
  Widget _buildProgressStep(int step, String label, IconData icon) {
    final isActive = _currentPage == step;
    final isCompleted = _currentPage > step;
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted 
                ? Colors.green 
                : isActive 
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
          ),
          child: Icon(
            icon,
            color: isCompleted || isActive ? Colors.white : Colors.grey.shade600,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1, // ✅ FIXED: Added maxLines
          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
        ),
      ],
    );
  }
  
  Widget _buildProgressLine(int step) {
    final isCompleted = _currentPage > step;
    
    return Expanded( // ✅ FIXED: Added Expanded for flexible line
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        color: isCompleted ? Colors.green : Colors.grey.shade300,
      ),
    );
  }
  
  Widget _buildContextSuggestionBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Expanded( // ✅ FIXED: Added Expanded
                child: Text(
                  _getContextTitle(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                    fontSize: 16,
                  ),
                  maxLines: 1, // ✅ FIXED: Added maxLines
                  overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getContextDescription(),
            style: TextStyle(color: Colors.blue.shade700),
            maxLines: 3, // ✅ FIXED: Added maxLines
            overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded( // ✅ FIXED: Added Expanded for button
                child: ElevatedButton(
                  onPressed: _acceptContextSuggestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Use Smart Suggestion',
                    maxLines: 1, // ✅ FIXED: Added maxLines
                    overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded( // ✅ FIXED: Added Expanded for button
                child: OutlinedButton(
                  onPressed: () => setState(() => _showContextSuggestion = false),
                  child: const Text(
                    'Choose Manually',
                    maxLines: 1, // ✅ FIXED: Added maxLines
                    overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getContextTitle() {
    switch (_detectedContext?.detectedContext) {
      case 'happy_hour':
        return 'Perfect for Happy Hour!';
      case 'lunch_special':
        return 'Great for Lunch Special!';
      case 'morning_rush':
        return 'Morning Rush Optimization!';
      case 'weekend_special':
        return 'Perfect Weekend Special!';
      default:
        return 'Smart Suggestion Available!';
    }
  }
  
  String _getContextDescription() {
    switch (_detectedContext?.detectedContext) {
      case 'happy_hour':
        return 'Based on your restaurant and current time, this works great as a Happy Hour special.';
      case 'lunch_special':
        return 'Perfect timing for a lunch special that targets busy professionals.';
      case 'morning_rush':
        return 'Catch the morning commuters with optimized coffee and breakfast deals.';
      case 'weekend_special':
        return 'Weekend customers are perfect for this type of deal.';
      default:
        return 'We\'ve detected optimal settings for your business type and current context.';
    }
  }
  
  void _acceptContextSuggestion() {
    setState(() {
      _acceptedContextSuggestion = true;
      _showContextSuggestion = false;
      _selectedTemplate = _availableTemplates.first;
    });
    
    _initializeTemplateControllers();
    _goToNextPage();
  }
  
  Widget _buildTemplateSelectionPage() {
    return Column(
      children: [
        // Browse Templates Section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded( // ✅ FIXED: Added Expanded
                child: Text(
                  'Browse Templates',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  maxLines: 1, // ✅ FIXED: Added maxLines
                  overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Category Filters
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip('All', true),
              const SizedBox(width: 8),
              _buildCategoryChip('🕐 Time-Based', false),
              const SizedBox(width: 8),
              _buildCategoryChip('💰 Discount', false),
              const SizedBox(width: 8),
              _buildCategoryChip('✨ Loyalty', false),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Template Grid
        Expanded(
          child: LayoutBuilder( // ✅ FIXED: Added LayoutBuilder for responsive design
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;
              final childAspectRatio = constraints.maxWidth < 600 ? 0.85 : 0.9;
              
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _availableTemplates.length,
                itemBuilder: (context, index) {
                  final template = _availableTemplates[index];
                  return _buildTemplateCard(template, index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(
        label,
        maxLines: 1, // ✅ FIXED: Added maxLines
        overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
      ),
      selected: isSelected,
      onSelected: (selected) {
        // Category filter logic would go here
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildTemplateCard(DealStructureTemplate template, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectTemplate(template), // ✅ UPDATED: Now automatically navigates
        borderRadius: BorderRadius.circular(12),
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
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      index == 0 ? Icons.percent : Icons.local_offer,
                      color: const Color.fromARGB(255, 230, 81, 7),
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2, // ✅ FIXED: Added maxLines
                overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
              ),
              const SizedBox(height: 4),
              Expanded( // ✅ FIXED: Added Expanded for flexible content
                child: Text(
                  template.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  maxLines: 3, // ✅ FIXED: Added maxLines
                  overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Popular',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1, // ✅ FIXED: Added maxLines
                      overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to use',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _selectTemplate(DealStructureTemplate template) {
    setState(() {
      _selectedTemplate = template;
    });
    
    _initializeTemplateControllers();
    _goToNextPage(); // ✅ UPDATED: Automatically navigate to next page
  }
  
  void _initializeTemplateControllers() {
    if (_selectedTemplate == null) return;
    
    // Clear existing controllers
    _controllers.values.forEach((controller) => controller.dispose());
    _controllers.clear();
    _templateData.clear();
    
    // Create controllers for all fields
    final allFields = [..._selectedTemplate!.requiredFields, ..._selectedTemplate!.optionalFields];
    
    for (final field in allFields) {
      _controllers[field.id] = TextEditingController();
      
      // Set default values
      if (field.defaultValue != null) {
        _controllers[field.id]!.text = field.defaultValue.toString();
        _templateData[field.id] = field.defaultValue;
      }
    }
  }

  Widget _buildTemplateConfigurationPage() {
    if (_selectedTemplate == null) return const Center(child: Text('No template selected'));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure ${_selectedTemplate!.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2, // ✅ FIXED: Added maxLines
              overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
            ),
            if (_acceptedContextSuggestion && _detectedContext?.detectedContext != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded( // ✅ FIXED: Added Expanded
                      child: Text(
                        'Optimized for ${_detectedContext!.detectedContext!.replaceAll('_', ' ')}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2, // ✅ FIXED: Added maxLines
                        overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            
            // Image upload section
            _buildImageUploadSection(),
            
            const SizedBox(height: 24),
            
            // Timing section
            _buildTimingSection(),
            
            const SizedBox(height: 24),
            
            // Required fields
            _buildFieldSection('Required Information', _selectedTemplate!.requiredFields),
            
            const SizedBox(height: 24),
            
            // Optional fields
            if (_selectedTemplate!.optionalFields.isNotEmpty) ...[
              _buildFieldSection('Optional Settings', _selectedTemplate!.optionalFields),
              const SizedBox(height: 24),
            ],
            
            // Live preview
            _buildLivePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deal Image (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1, // ✅ FIXED: Added maxLines
          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
        ),
        const SizedBox(height: 8),
        Text(
          'Add an eye-catching image to make your deal stand out',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
          maxLines: 2, // ✅ FIXED: Added maxLines
          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _selectImage,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add image',
                        style: TextStyle(color: Colors.grey.shade600),
                        maxLines: 1, // ✅ FIXED: Added maxLines
                        overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimingSection() {
  // ✅ NEW: Check if this is a Flash Sale template
  final isFlashSale = _selectedTemplate?.name.toLowerCase().contains('flash') == true;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        isFlashSale ? 'Flash Sale Duration' : 'Deal Timing',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 16),
      
      // ✅ NEW: Flash Sale shows different timing UI
      if (isFlashSale) ...[
        // Flash Sale always starts now - show immutable info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.flash_on, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starts Immediately - NOW',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Flash sales create urgency by starting right away',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.lock,
                color: Colors.orange.shade400,
                size: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Only show end time for Flash Sale
        InkWell(
          onTap: () => _selectEndTime(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Time',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _endTime != null 
                            ? DateFormat('MMM dd, HH:mm').format(_endTime!)
                            : 'Select when flash sale ends',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ] else ...[
        // Regular templates show both start and end time
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectStartTime(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _startTime != null 
                            ? DateFormat('MMM dd, HH:mm').format(_startTime!)
                            : 'Start now',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectEndTime(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Time',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _endTime != null 
                            ? DateFormat('MMM dd, HH:mm').format(_endTime!)
                            : 'Select end time',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ],
  );
}
  
  Widget _buildFieldSection(String title, List<TemplateField> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1, // ✅ FIXED: Added maxLines
          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
        ),
        const SizedBox(height: 16),
        ...fields.map((field) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFormField(field),
        )),
      ],
    );
  }
  
  Widget _buildFormField(TemplateField field) {
    switch (field.type) {
      case FieldType.currency:
        return _buildCurrencyField(field);
      case FieldType.percentage:
        return _buildPercentageField(field);
      case FieldType.number:
        return _buildNumberField(field);
      default:
        return _buildTextField(field);
    }
  }
  
  Widget _buildCurrencyField(TemplateField field) {
    return TextFormField(
      controller: _controllers[field.id],
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.description,
        helperMaxLines: 2, // ✅ FIXED: Added helperMaxLines
        prefixText: '\$',
        border: const OutlineInputBorder(),
        suffixIcon: _acceptedContextSuggestion 
            ? Icon(Icons.auto_awesome, color: Colors.green.shade600, size: 16)
            : null,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: field.required ? (value) {
        if (value?.isEmpty == true) return '${field.label} is required';
        final number = double.tryParse(value!);
        if (number == null) return 'Please enter a valid amount';
        return null;
      } : null,
      onChanged: (value) {
        final number = double.tryParse(value);
        if (number != null) {
          _templateData[field.id] = number;
          setState(() {}); // Refresh live preview
        }
      },
    );
  }
  
  Widget _buildPercentageField(TemplateField field) {
    final currentValue = _templateData[field.id]?.toDouble() ?? field.defaultValue ?? 20.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded( // ✅ FIXED: Added Expanded
              child: Text(
                field.label,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1, // ✅ FIXED: Added maxLines
                overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
              ),
            ),
            if (_acceptedContextSuggestion)
              Icon(Icons.auto_awesome, color: Colors.green.shade600, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: currentValue,
          min: (field.constraints?['min'] ?? 5).toDouble(),
          max: (field.constraints?['max'] ?? 70).toDouble(),
          divisions: ((field.constraints?['max'] ?? 70) - (field.constraints?['min'] ?? 5)) ~/ 
                   (field.constraints?['step'] ?? 5),
          label: '${currentValue.round()}%',
          onChanged: (value) {
            setState(() {
              _templateData[field.id] = value;
              _controllers[field.id]!.text = value.round().toString();
            });
          },
        ),
        Text(
          '${currentValue.round()}% - ${field.description}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
          maxLines: 2, // ✅ FIXED: Added maxLines
          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
        ),
      ],
    );
  }
  
  Widget _buildNumberField(TemplateField field) {
    return TextFormField(
      controller: _controllers[field.id],
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.description,
        helperMaxLines: 2, // ✅ FIXED: Added helperMaxLines
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: field.required ? (value) {
        if (value?.isEmpty == true) return '${field.label} is required';
        if (int.tryParse(value!) == null) return 'Please enter a valid number';
        return null;
      } : null,
      onChanged: (value) {
        final number = int.tryParse(value);
        if (number != null) {
          _templateData[field.id] = number;
          setState(() {});
        }
      },
    );
  }
  
  Widget _buildTextField(TemplateField field) {
    return TextFormField(
      controller: _controllers[field.id],
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.description,
        helperMaxLines: 2, // ✅ FIXED: Added helperMaxLines
        border: const OutlineInputBorder(),
      ),
      maxLines: field.label.toLowerCase().contains('description') ? 3 : 1,
      validator: field.required ? (value) {
        if (value?.isEmpty == true) return '${field.label} is required';
        return null;
      } : null,
      onChanged: (value) {
        _templateData[field.id] = value;
        setState(() {});
      },
    );
  }

  Widget _buildLivePreview() {
    if (_selectedTemplate == null) return const SizedBox.shrink();
    
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business == null) return const SizedBox.shrink();
    
    final preview = _selectedTemplate!.generatePreview(_templateData, business);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded( // ✅ FIXED: Added Expanded
                child: Text(
                  'Live Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1, // ✅ FIXED: Added maxLines
                  overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            preview,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 5, // ✅ FIXED: Added maxLines
            overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewAndConfirmPage() {
    if (_selectedTemplate == null) return const SizedBox.shrink();
    
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business == null) return const SizedBox.shrink();
    
    final preview = _selectedTemplate!.generatePreview(_templateData, business);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview Your Deal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1, // ✅ FIXED: Added maxLines
            overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
          ),
          const SizedBox(height: 24),
          
          // Deal Preview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
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
                    const Icon(Icons.local_offer, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded( // ✅ FIXED: Added Expanded
                      child: Text(
                        'Your ${_selectedTemplate!.name} Deal',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2, // ✅ FIXED: Added maxLines
                        overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  preview,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 8, // ✅ FIXED: Added maxLines
                  overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Context insights (if applicable)
          if (_acceptedContextSuggestion && _detectedContext != null)
            _buildContextInsights(),
        ],
      ),
    );
  }
  
  Widget _buildContextInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                Expanded( // ✅ FIXED: Added Expanded
                  child: Text(
                    'Smart Optimization Applied',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1, // ✅ FIXED: Added maxLines
                    overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This deal has been optimized for ${_detectedContext!.detectedContext!.replaceAll('_', ' ')} based on your business type and current timing.',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3, // ✅ FIXED: Added maxLines
              overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavigationButtons() {
    // ✅ UPDATED: Hide navigation buttons on template selection page (page 0)
    if (_currentPage == 0) {
      return const SizedBox.shrink(); // No buttons on template selection page
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousPage,
                child: const Text(
                  'Back',
                  maxLines: 1, // ✅ FIXED: Added maxLines
                  overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isCreating ? null : _getNextButtonAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isCreating 
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _getNextButtonText(),
                      maxLines: 1, // ✅ FIXED: Added maxLines
                      overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage = _currentPage - 1);
    }
  }
  
  VoidCallback? _getNextButtonAction() {
    if (_isCreating) return null;
    
    switch (_currentPage) {
      case 0: // Template selection - No button needed anymore
        return null;
      case 1: // Configuration
        return _validateAndGoNext;
      case 2: // Preview
        return _createDeal;
      default:
        return null;
    }
  }
  
  String _getNextButtonText() {
    switch (_currentPage) {
      case 0:
        return 'Select Template'; // This won't be shown anymore
      case 1:
        return 'Preview Deal';
      case 2:
        return 'Create Deal';
      default:
        return 'Next';
    }
  }
  
  void _goToNextPage() {
    if (_currentPage < 2) {
      setState(() => _currentPage = _currentPage + 1);
    }
  }
  
  void _validateAndGoNext() {
    if (_formKey.currentState?.validate() == true) {
      _goToNextPage();
    }
  }

  Future<void> _selectStartTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime ?? now),
      );
      
      if (pickedTime != null && mounted) {
        setState(() {
          _startTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    final now = _startTime ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endTime ?? now.add(const Duration(hours: 24)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime ?? now.add(const Duration(hours: 24))),
      );
      
      if (pickedTime != null && mounted) {
        setState(() {
          _endTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _selectImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createDeal() async {
    if (_selectedTemplate == null) {
      _showError('No template selected');
      return;
    }
    
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business == null) {
      _showError('Business information not available');
      return;
    }
    
    setState(() => _isCreating = true);
    
    try {
      // Add timing data to template data
      Map<String, dynamic> finalTemplateData = Map.from(_templateData);
      
      // Add our timing selections to the template data
      finalTemplateData['user_start_time'] = _startTime;
      finalTemplateData['user_end_time'] = _endTime;
      finalTemplateData['start_immediately'] = _startTime == null;
      
      // Transform template data to Deal object
      final deal = _transformationService.transformToDeal(
        template: _selectedTemplate!,
        templateData: finalTemplateData,
        business: business,
        customStartTime: _startTime,
      );
      
      // Create the deal using existing provider
      final dealsProvider = Provider.of<DealsProvider>(context, listen: false);
      final success = await dealsProvider.createDeal(deal, imageFile: _selectedImage);
      
      if (success && mounted) {
        _showSuccess('Deal created successfully!');
        Navigator.of(context).pop();
      } else if (mounted) {
        _showError('Failed to create deal. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error creating deal: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          maxLines: 2, // ✅ FIXED: Added maxLines
          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          maxLines: 2, // ✅ FIXED: Added maxLines
          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}