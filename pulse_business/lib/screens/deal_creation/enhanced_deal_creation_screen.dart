// lib/screens/deal_creation/enhanced_deal_creation_screen.dart
// Fixed version that properly displays the template selection

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
        title: const Text('Create Deal'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Context suggestion banner
          if (_showContextSuggestion && !_acceptedContextSuggestion)
            _buildContextSuggestionBanner(),
          
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
            isCompleted ? Icons.check : icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressLine(int step) {
    final isCompleted = _currentPage > step;
    
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isCompleted ? Colors.green : Colors.grey.shade300,
      ),
    );
  }
  
  Widget _buildContextSuggestionBanner() {
    if (_detectedContext == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getContextTitle(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showContextSuggestion = false),
                icon: Icon(Icons.close, color: Colors.blue.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getContextDescription(),
            style: TextStyle(color: Colors.blue.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 180,
                child:  ElevatedButton(
                onPressed: _acceptContextSuggestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply Optimization'),
              ),
              ),             
              SizedBox(
                width: 100,
              child : TextButton(
                onPressed: () => setState(() => _showContextSuggestion = false),
                child: const Text('Use Basic Settings'),
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
    _applySmartDefaults();
    _goToNextPage();
  }
  
  Widget _buildTemplateSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Deal Type',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the type of deal you want to create. We\'ll help optimize it for your business.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Show available templates
          ..._availableTemplates.map((template) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: _selectedTemplate?.id == template.id ? 4 : 2,
              color: _selectedTemplate?.id == template.id 
                  ? template.primaryColor.withOpacity(0.1) 
                  : null,
              child: InkWell(
                onTap: () => _selectTemplate(template),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: template.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: template.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.percent,
                          color: template.primaryColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _selectedTemplate?.id == template.id 
                                    ? template.primaryColor 
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              template.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedTemplate?.id == template.id)
                        Icon(
                          Icons.check_circle,
                          color: template.primaryColor,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          )),
          
          const SizedBox(height: 24),
          
          // Add some helpful text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Why Percentage Off?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Percentage off deals are the most popular and effective type of promotion. They\'re easy to understand and can be applied to any business type.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Simple for customers to understand\n• Flexible pricing control\n• Works for any business type\n• Average 32% conversion rate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _selectTemplate(DealStructureTemplate template) {
    setState(() {
      _selectedTemplate = template;
    });
    
    _initializeTemplateControllers();
    
    if (_acceptedContextSuggestion) {
      _applySmartDefaults();
    }
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
  
  void _applySmartDefaults() {
    if (_selectedTemplate == null || _detectedContext == null) return;
    
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    if (business == null) return;
    
    final smartDefaults = _selectedTemplate!.getSmartDefaults(business, _detectedContext!);
    
    smartDefaults.forEach((key, value) {
      if (_controllers.containsKey(key)) {
        _controllers[key]!.text = value.toString();
        _templateData[key] = value;
      }
    });
    
    setState(() {});
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
                    Expanded(
                      child: Text(
                        'Optimized for ${_detectedContext!.detectedContext!.replaceAll('_', ' ')}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            
            // Required fields
            _buildFieldSection('Required Information', _selectedTemplate!.requiredFields),
            
            const SizedBox(height: 24),
            
            // Optional fields
            if (_selectedTemplate!.optionalFields.isNotEmpty) ...[
              _buildFieldSection('Optional Settings', _selectedTemplate!.optionalFields),
              const SizedBox(height: 24),
            ],
            
            // Image upload
            _buildImageUploadSection(),
            
            const SizedBox(height: 24),
            
            // Live preview
            _buildLivePreview(),
          ],
        ),
      ),
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
            Expanded(
              child: Text(
                field.label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (_acceptedContextSuggestion)
              Icon(Icons.auto_awesome, color: Colors.green.shade600, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: currentValue,
          min: (field.constraints['min'] ?? 5).toDouble(),
          max: (field.constraints['max'] ?? 70).toDouble(),
          divisions: ((field.constraints['max'] ?? 70) - (field.constraints['min'] ?? 5)) ~/ 
                   (field.constraints['step'] ?? 5),
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
        border: const OutlineInputBorder(),
      ),
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
  
  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deal Image (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
                      Icon(Icons.camera_alt, size: 32, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add image',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _selectImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
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
              Text(
                'Live Preview',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            preview,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreviewAndConfirmPage() {
    if (_selectedTemplate == null) return const Center(child: Text('No template selected'));
    
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final business = businessProvider.currentBusiness;
    
    if (business == null) return const Center(child: Text('Business information not available'));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Confirm',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Deal preview card
          _buildDealPreviewCard(business),
          
          const SizedBox(height: 24),
          
          // Context insights
          if (_acceptedContextSuggestion && _detectedContext?.detectedContext != null)
            _buildContextInsights(),
        ],
      ),
    );
  }
  
  Widget _buildDealPreviewCard(Business business) {
    final preview = _selectedTemplate!.generatePreview(_templateData, business);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.percent,
                  size: 24,
                  color: _selectedTemplate!.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your ${_selectedTemplate!.name} Deal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
            ),
          ],
        ),
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
                Text(
                  'Smart Optimization Applied',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This deal has been optimized for ${_detectedContext!.detectedContext!.replaceAll('_', ' ')} based on your business type and current timing.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavigationButtons() {
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
                child: const Text('Back'),
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
                  : Text(_getNextButtonText()),
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
      case 0: // Template selection
        return _selectedTemplate != null ? _goToNextPage : null;
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
        return 'Continue';
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
      // Transform template data to Deal object
      final deal = _transformationService.transformToDeal(
        template: _selectedTemplate!,
        templateData: _templateData,
        business: business,
      );
      
      // Create the deal using existing provider
      final dealsProvider = Provider.of<DealsProvider>(context, listen: false);
      final success = await dealsProvider.createDeal(deal, imageFile: _selectedImage);
      
      if (success && mounted) {
        _showSuccess('Deal created successfully!');
        //Navigator.of(context).pop();
      } else if (mounted) {
        _showError('Failed to create deal: ${dealsProvider.errorMessage ?? 'Unknown error'}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error creating deal: $e');
      }
      debugPrint('Error creating deal: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}