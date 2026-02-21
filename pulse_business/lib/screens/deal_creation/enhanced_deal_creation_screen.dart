// lib/screens/deal_creation/enhanced_deal_creation_screen.dart - FIXED OVERFLOW ISSUES

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pulse_business/models/deal_template.dart' hide FlashSaleTemplate;
import 'dart:io';

import '../../constants/deal_tags.dart';
import '../../models/business.dart';
import '../../models/deal_structure_templates.dart';
import '../../providers/business_provider.dart';
import '../../providers/deals_provider.dart';
import '../../services/context_analyzer.dart';
import '../../services/template_transformation_service.dart';
import '../../utils/theme.dart';
import '../../widgets/tag_picker.dart';
import '../stripe/stripe_onboarding_screen.dart';

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
    FlashSaleTemplate(),
    RecurringHappyHourTemplate(),
  ];
  List<DealStructureTemplate> _filteredTemplates = [];
   String? _selectedCategory;
  // State
  DealStructureTemplate? _selectedTemplate;
  TemplateContext? _detectedContext;
  Map<String, dynamic> _templateData = {};
  Map<String, TextEditingController> _controllers = {};
  bool _showContextSuggestion = false;
  bool _acceptedContextSuggestion = true;
  File? _selectedImage;
  int _currentPage = 0;
  bool _isCreating = false;
  DateTime? _startTime;
  DateTime? _endTime;
  List<File> _selectedImages = []; // ✅ Changed from File? _selectedImage
  List<String> _selectedTags = [];
  int _currentPreviewImageIndex = 0; // ✅ For live preview
  int _currentFullPreviewImageIndex = 0; // ✅ For preview tab

  // Add these with your other state variables
List<String> _selectedWeekdays = [];
List<String> _selectedWeekends = [];
TimeOfDay _weekdayStartTime = const TimeOfDay(hour: 16, minute: 0); // 4 PM
TimeOfDay _weekdayEndTime = const TimeOfDay(hour: 19, minute: 0); // 7 PM
TimeOfDay _weekendStartTime = const TimeOfDay(hour: 12, minute: 0); // 12 PM
TimeOfDay _weekendEndTime = const TimeOfDay(hour: 15, minute: 0); // 3 PM

  @override
  void initState() {
    super.initState();
    _filteredTemplates = _availableTemplates;
    _analyzeCurrentContext();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
  
   void _filterTemplatesByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      
      if (category == null || category == 'All') {
        // Show all templates
        _filteredTemplates = _availableTemplates;
      } else {
        // Simple name-based filtering (works with your current templates!)
        _filteredTemplates = _availableTemplates.where((template) {
          final templateName = template.name.toLowerCase();
          final templateId = template.id.toLowerCase();
          
          switch (category) {
            case 'Time-Based':
              return templateId.contains('flash') || 
                     templateName.contains('flash') ||
                     templateName.contains('time');
                     
            case 'Discount':
              return templateId.contains('percentage') || 
                     templateName.contains('percentage') ||
                     templateName.contains('off');
                     
            case 'Bundle':
              return templateId.contains('combo') || 
                     templateName.contains('bundle') ||
                     templateName.contains('member');
                     
            default:
              return true;
          }
        }).toList();
      }
    });
  }

  // ✅ UPDATE YOUR CATEGORY CHIP METHOD:
  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    
    return FilterChip(
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      selected: isSelected,
      onSelected: (selected) => _filterTemplatesByCategory(selected ? category : null),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
    );
  }

  // ✅ UPDATE YOUR TEMPLATE GRID TO USE FILTERED LIST:
  Widget _buildTemplateSelectionPage() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Browse Templates',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ✅ UPDATE CATEGORY FILTERS:
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip('All', null),
              const SizedBox(width: 8),
              _buildCategoryChip('🕐 Time-Based', 'Time-Based'),
              const SizedBox(width: 8),
              _buildCategoryChip('💰 Discount', 'Discount'),
              const SizedBox(width: 8),
              _buildCategoryChip('✨ Bundle', 'Bundle'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ✅ UPDATE TEMPLATE GRID:
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;
              final childAspectRatio = constraints.maxWidth < 600 ? 0.85 : 0.9;
              
              // ✅ SHOW MESSAGE WHEN NO TEMPLATES FOUND:
              if (_filteredTemplates.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredTemplates.length, // ✅ USE FILTERED LIST
                itemBuilder: (context, index) {
                  final template = _filteredTemplates[index]; // ✅ USE FILTERED LIST
                  return _buildTemplateCard(template, index);
                },
              );
            },
          ),
        ),
      ],
    );
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
                if (_selectedTemplate != null) _buildDealPreviewCard(),
              ],
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildPaymentSetupBanner(Business business) {
  if (business.needsPaymentSetup) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Payments to Get Paid',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Complete payment setup to receive payouts',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StripeOnboardingScreen(canSkip: false),
                ),
              );
            },
            child: const Text('Setup'),
          ),
        ],
      ),
    );
  }
  return const SizedBox.shrink();
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
  
  Widget _buildTemplateCard(DealStructureTemplate template, int index) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
                  color: template.primaryColor.withOpacity(.5),
                  width: 2.0,
                  style: BorderStyle.solid,
                ),
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
                      color: template.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildTemplateIcon(template)
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
    
    if (_selectedTemplate!.id == 'recurring_happy_hour') {
    _selectedWeekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    _selectedWeekends = [];
    _weekdayStartTime = const TimeOfDay(hour: 16, minute: 0);
    _weekdayEndTime = const TimeOfDay(hour: 19, minute: 0);
    _updateRecurringData();
  }

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
            
            TagPicker(
              selectedTags: _selectedTags,
              onChanged: (tags) => setState(() => _selectedTags = tags),
            ),

            // Timing section
            if (_selectedTemplate!.id != 'recurring_happy_hour') ...[
            _buildTimingSection(),
            const SizedBox(height: 24),
            ],
            
          // ✅ ADD THIS: Recurring schedule section for Happy Hour
          if (_selectedTemplate!.id == 'recurring_happy_hour')
            _buildRecurringScheduleSection(),
          
          if (_selectedTemplate!.id == 'recurring_happy_hour')
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

// Change from single image to list
//List<File> _selectedImages = []; // ✅ Changed from File? to List<File>

Future<void> _selectImages() async {
  // ✅ Check limit before opening picker
  if (_selectedImages.length >= 5) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Maximum 5 images allowed'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  try {
    final picker = ImagePicker();
    
    // ✅ Calculate how many more images we can add
    final remainingSlots = 5 - _selectedImages.length;
    
    final images = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
      // Note: pickMultiImage doesn't have a limit parameter
      // We'll enforce it after selection
    );
    
    if (images != null && images.isNotEmpty) {
      // ✅ Only add up to the remaining slots
      final imagesToAdd = images.take(remainingSlots).map((img) => File(img.path)).toList();
      
      setState(() {
        _selectedImages.addAll(imagesToAdd);
      });
      
      // ✅ Show message if user tried to add too many
      if (images.length > remainingSlots) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${imagesToAdd.length} images. Maximum 5 images allowed.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  } catch (e) {
    _showError('Failed to select images: $e');
  }
}
// ✅ Show all selected images
Widget _buildImageUploadSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'Deal Images',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _selectedImages.length >= 5 
                ? Colors.red.shade50 
                : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_selectedImages.length}/5',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _selectedImages.length >= 5 
                  ? Colors.red.shade700 
                  : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      
      if (_selectedImages.isEmpty) ...[
        // Empty state - Show upload button
        OutlinedButton.icon(
          onPressed: _selectImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Images (up to 5)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        
        // Guidelines
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tips_and_updates, 
                    size: 16, 
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Photo Tips',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTip('✅ First image will be the main image'),
              _buildTip('✅ Keep your product/dish centered'),
              _buildTip('✅ Use good lighting'),
              _buildTip('✅ Portrait photos work best'),
            ],
          ),
        ),
      ] else ...[
        // Show selected images
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
            itemBuilder: (context, index) {
              // Add more button at the end
              if (index == _selectedImages.length) {
                return GestureDetector(
                  onTap: _selectImages,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey.shade600, size: 32),
                        const SizedBox(height: 4),
                        Text(
                          'Add More',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Image thumbnail
              return Stack(
                children: [
                  Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: index == 0 ? Colors.blue : Colors.grey.shade300,
                        width: index == 0 ? 3 : 1,
                      ),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  // Primary badge
                  if (index == 0)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MAIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Image number
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Remove button
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image removed'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ],
  );
}

Widget _buildTip(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.blue.shade900,
      ),
    ),
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
    final defaultValue = field.defaultValue ?? 20.0;
    final currentValue = _templateData[field.id]?.toDouble() ?? defaultValue;    
    if (_templateData[field.id] == null) {
    _templateData[field.id] = defaultValue;
  }
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
  
  // Generate the ACTUAL deal
  try {
    Map<String, dynamic> finalTemplateData = Map.from(_templateData);
    finalTemplateData['user_start_time'] = _startTime;
    finalTemplateData['user_end_time'] = _endTime;
    finalTemplateData['start_immediately'] = _startTime == null;
    
    final previewDeal = _transformationService.transformToDeal(
      template: _selectedTemplate!,
      templateData: finalTemplateData,
      business: business,
      customStartTime: _startTime,
    ).copyWith(tags: _selectedTags);
    
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
              Expanded(
                child: Text(
                  'Live Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // ✅ NEW: Show image carousel if multiple images
          if (_selectedImages.isNotEmpty) ...[
            _buildImageCarouselPreview(),
            const SizedBox(height: 12),
          ],
          
          // Title
          Text(
            previewDeal.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            previewDeal.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Pricing
          Row(
            children: [
              if (previewDeal.originalPrice != previewDeal.dealPrice) ...[
                Text(
                  '\$${previewDeal.originalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '\$${previewDeal.dealPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (previewDeal.discountPercentage > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${previewDeal.discountPercentage}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  } catch (e) {
    print('⚠️ Preview generation failed: $e');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: const Text('Preview unavailable'),
    );
  }
}

// ✅ NEW: Image carousel for live preview
Widget _buildImageCarouselPreview() {
  if (_selectedImages.isEmpty) return const SizedBox.shrink();
  
  return Container(
    height: 150,
    child: Stack(
      children: [
        PageView.builder(
          itemCount: _selectedImages.length,
          onPageChanged: (index) {
            setState(() => _currentPreviewImageIndex = index);
          },
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedImages[index],
                fit: BoxFit.cover,
              ),
            );
          },
        ),
        
        // Image counter
        if (_selectedImages.length > 1)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPreviewImageIndex + 1}/${_selectedImages.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        // Dot indicators
        if (_selectedImages.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _selectedImages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPreviewImageIndex == index
                      ? Colors.white
                      : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildDealPreviewCard() {
  final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
  final business = businessProvider.currentBusiness;
  
  if (business == null) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Business information not available'),
      ),
    );
  }
  
  try {
    Map<String, dynamic> finalTemplateData = Map.from(_templateData);
    finalTemplateData['user_start_time'] = _startTime;
    finalTemplateData['user_end_time'] = _endTime;
    finalTemplateData['start_immediately'] = _startTime == null;
    
    final previewDeal = _transformationService.transformToDeal(
      template: _selectedTemplate!,
      templateData: finalTemplateData,
      business: business,
      customStartTime: _startTime,
    ).copyWith(
      tags: _selectedTags, // ✅ Show selected tags in preview
    );
    
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
          ),
          const SizedBox(height: 24),
          
          // Deal Preview Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ NEW: Image carousel section
                _buildPreviewImageCarousel(),
                
                // Content section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Business name
                      Text(
                        business.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Tag chips
                      if (previewDeal.tags.isNotEmpty) ...[
                        SizedBox(
                          height: 28,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: previewDeal.tags.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                            itemBuilder: (context, index) {
                              final tag = DealTags.getById(previewDeal.tags[index]);
                              if (tag == null) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: tag.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: tag.color.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(tag.emoji, style: const TextStyle(fontSize: 11)),
                                    const SizedBox(width: 4),
                                    Text(
                                      tag.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: tag.color,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // Deal title
                      Text(
                        previewDeal.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Deal description
                      Text(
                        previewDeal.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      
                      // Price section
                      Row(
                        children: [
                          if (previewDeal.originalPrice != previewDeal.dealPrice) ...[
                            Text(
                              '\$${previewDeal.originalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '\$${previewDeal.dealPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (previewDeal.discountPercentage > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${previewDeal.discountPercentage}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Additional details
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Quantity:',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${previewDeal.totalQuantity} available',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Expires:',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(previewDeal.expirationTime),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is exactly how customers will see your deal',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
  } catch (e) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Error generating preview'),
          ],
        ),
      ),
    );
  }
}

// ✅ NEW: Full preview image carousel
Widget _buildPreviewImageCarousel() {
  if (_selectedImages.isEmpty) {
    // Placeholder when no images
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Add images to see preview',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
  
  return Stack(
    children: [
      AspectRatio(
        aspectRatio: 2 / 3, // ✅ Your chosen ratio
        child: PageView.builder(
          itemCount: _selectedImages.length,
          onPageChanged: (index) {
            setState(() => _currentFullPreviewImageIndex = index);
          },
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.file(
                _selectedImages[index],
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      ),
      
      // Discount badge (top-left)
      Positioned(
        top: 12,
        left: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_templateData['discount_percentage']?.round() ?? 20}% OFF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      
      // Image counter (top-right)
      if (_selectedImages.length > 1)
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentFullPreviewImageIndex + 1}/${_selectedImages.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      
      // Dot indicators (bottom-center)
      if (_selectedImages.length > 1)
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _selectedImages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentFullPreviewImageIndex == index
                    ? Colors.white
                    : Colors.white54,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

// ✅ Add helper method for date formatting
String _formatDateTime(DateTime dateTime) {
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
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

  Widget _buildRecurringScheduleSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Schedule',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Select the days and times your happy hour runs',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 16),
      
      // Weekday selection
      _buildDaySelectionGroup(
        title: 'Weekdays',
        days: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
        selectedDays: _selectedWeekdays,
        onDayToggle: (day) {
          setState(() {
            if (_selectedWeekdays.contains(day)) {
              _selectedWeekdays.remove(day);
            } else {
              _selectedWeekdays.add(day);
            }
            _updateRecurringData();
          });
        },
        startTime: _weekdayStartTime,
        endTime: _weekdayEndTime,
        onStartTimeChanged: (time) {
          setState(() {
            _weekdayStartTime = time;
            _updateRecurringData();
          });
        },
        onEndTimeChanged: (time) {
          setState(() {
            _weekdayEndTime = time;
            _updateRecurringData();
          });
        },
      ),
      
      const SizedBox(height: 24),
      
      // Weekend selection
      _buildDaySelectionGroup(
        title: 'Weekends',
        days: ['saturday', 'sunday'],
        selectedDays: _selectedWeekends,
        onDayToggle: (day) {
          setState(() {
            if (_selectedWeekends.contains(day)) {
              _selectedWeekends.remove(day);
            } else {
              _selectedWeekends.add(day);
            }
            _updateRecurringData();
          });
        },
        startTime: _weekendStartTime,
        endTime: _weekendEndTime,
        onStartTimeChanged: (time) {
          setState(() {
            _weekendStartTime = time;
            _updateRecurringData();
          });
        },
        onEndTimeChanged: (time) {
          setState(() {
            _weekendEndTime = time;
            _updateRecurringData();
          });
        },
      ),
      
      // Validation message
      if (_selectedWeekdays.isEmpty && _selectedWeekends.isEmpty)
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please select at least one day',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

Widget _buildDaySelectionGroup({
  required String title,
  required List<String> days,
  required List<String> selectedDays,
  required Function(String) onDayToggle,
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  required Function(TimeOfDay) onStartTimeChanged,
  required Function(TimeOfDay) onEndTimeChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                if (selectedDays.length == days.length) {
                  selectedDays.clear();
                } else {
                  selectedDays.clear();
                  selectedDays.addAll(days);
                }
                _updateRecurringData();
              });
            },
            child: Text(
              selectedDays.length == days.length ? 'Clear All' : 'Select All',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      
      // Day checkboxes
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: days.map((day) {
          final isSelected = selectedDays.contains(day);
          return FilterChip(
            label: Text(
              _formatDayName(day),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) => onDayToggle(day),
            selectedColor: AppTheme.primaryColor,
            checkmarkColor: Colors.white,
            backgroundColor: Colors.grey.shade100,
          );
        }).toList(),
      ),
      
      // Time pickers (only show if at least one day is selected)
      if (selectedDays.isNotEmpty) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (picked != null) {
                    onStartTimeChanged(picked);
                  }
                },
                icon: const Icon(Icons.access_time, size: 18),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      startTime.format(context),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (picked != null) {
                    onEndTimeChanged(picked);
                  }
                },
                icon: const Icon(Icons.access_time, size: 18),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      endTime.format(context),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

String _formatDayName(String day) {
  return day[0].toUpperCase() + day.substring(1, 3);
}

void _updateRecurringData() {
  // Store recurring schedule in template data
  _templateData['recurring_weekdays'] = List<String>.from(_selectedWeekdays);
  _templateData['recurring_weekends'] = List<String>.from(_selectedWeekends);
  _templateData['weekday_start_time'] = '${_weekdayStartTime.hour.toString().padLeft(2, '0')}:${_weekdayStartTime.minute.toString().padLeft(2, '0')}';
  _templateData['weekday_end_time'] = '${_weekdayEndTime.hour.toString().padLeft(2, '0')}:${_weekdayEndTime.minute.toString().padLeft(2, '0')}';
  _templateData['weekend_start_time'] = '${_weekendStartTime.hour.toString().padLeft(2, '0')}:${_weekendStartTime.minute.toString().padLeft(2, '0')}';
  _templateData['weekend_end_time'] = '${_weekendEndTime.hour.toString().padLeft(2, '0')}:${_weekendEndTime.minute.toString().padLeft(2, '0')}';
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
      ).copyWith(tags: _selectedTags);
      
      // Create the deal using existing provider
      final dealsProvider = Provider.of<DealsProvider>(context, listen: false);
      final success = await dealsProvider.createDeal(deal, imageFiles: _selectedImages,);
      
      if (success && mounted) {
        _showSuccess('Deal created successfully!');
        //Navigator.of(context).pop();
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

  Widget _buildTemplateIcon(DealStructureTemplate template) {
  return Text(
    template.icon, // Shows: %, 📦, ⚡
    style: const TextStyle(fontSize: 20),
  );
}
}