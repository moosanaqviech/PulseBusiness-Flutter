// lib/screens/deal_creation/template_deal_creator.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../models/deal_template.dart';
import '../../models/business.dart';
import '../../models/deal.dart';
import '../../providers/deals_provider.dart';
import '../../providers/business_provider.dart';
import '../../services/template_manager.dart';
import '../../utils/theme.dart';

class TemplateDealCreator extends StatefulWidget {
  final DealTemplate template;
  final Business business;

  const TemplateDealCreator({
    super.key,
    required this.template,
    required this.business,
  });

  @override
  State<TemplateDealCreator> createState() => _TemplateDealCreatorState();
}

class _TemplateDealCreatorState extends State<TemplateDealCreator> {
  final _formKey = GlobalKey<FormState>();
  final _templateManager = TemplateManager();
  
  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _dealPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _termsController;
  
  late DateTime _expirationTime;
  late DateTime? _startTime;
  bool isScheduled = false;
  File? _selectedImage;
  bool _isCustomizing = false;
  
  @override
  void initState() {
    super.initState();
    _initializeFromTemplate();
  }
  
  void _initializeFromTemplate() {
    // Generate deal from template
    final templateDeal = widget.template.generateDeal(widget.business);
    
    // Initialize controllers with template values
    _titleController = TextEditingController(text: templateDeal.title);
    _descriptionController = TextEditingController(text: templateDeal.description);
    _originalPriceController = TextEditingController(
      text: templateDeal.originalPrice.toStringAsFixed(2),
    );
    _dealPriceController = TextEditingController(
      text: templateDeal.dealPrice.toStringAsFixed(2),
    );
    _quantityController = TextEditingController(
      text: templateDeal.totalQuantity.toString(),
    );
    _termsController = TextEditingController(
      text: templateDeal.termsAndConditions ?? '',
    );
    _expirationTime = templateDeal.expirationTime;
    _startTime = templateDeal.startTime;
    isScheduled = templateDeal.isScheduled;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _dealPriceController.dispose();
    _quantityController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create ${widget.template.name}'),
        elevation: 0,
        backgroundColor: widget.template.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => setState(() => _isCustomizing = !_isCustomizing),
            child: Text(
              _isCustomizing ? 'Preview' : 'Customize',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTemplateHeader(),
          Expanded(
            child: _isCustomizing ? _buildCustomizationForm() : _buildPreview(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildTemplateHeader() {
    return Container(
      color: widget.template.primaryColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Text(
            widget.template.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.template.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.template.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (widget.template.averageConversionRate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.template.averageConversionRate!.toStringAsFixed(1)}% avg',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDealPreviewCard(),
          const SizedBox(height: 20),
          _buildSmartSuggestions(),
          const SizedBox(height: 20),
          _buildOptimizationTips(),
        ],
      ),
    );
  }

  Widget _buildDealPreviewCard() {
    final discount = _calculateDiscountPercentage();
    
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add image',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and discount badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _titleController.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (discount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${discount.round()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Text(
                  _descriptionController.text,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Pricing
                Row(
                  children: [
                    if (discount > 0) ...[
                      Text(
                        '\$${_originalPriceController.text}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '\$${_dealPriceController.text}',
                      style: TextStyle(
                        color: widget.template.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Quantity and expiration
                Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_quantityController.text} available',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires ${DateFormat('MMM dd, h:mm a').format(_expirationTime)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Business info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: widget.template.primaryColor,
                      child: Text(
                        widget.business.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.business.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                // Terms and conditions
                if (_termsController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Terms: ${_termsController.text}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartSuggestions() {
    final suggestions = widget.template.smartSuggestions;
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Smart Suggestions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_right,
                      color: Colors.orange.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationTips() {
    final tips = widget.template.getOptimizationTips(widget.business);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Optimization Tips',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Deal Information'),
            const SizedBox(height: 12),
            _buildImageSelector(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _titleController,
              label: 'Deal Title',
              icon: Icons.title,
              validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Pricing'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _originalPriceController,
                    label: 'Original Price',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: _validatePrice,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _dealPriceController,
                    label: 'Deal Price',
                    icon: Icons.local_offer,
                    keyboardType: TextInputType.number,
                    validator: _validatePrice,
                    suffix: _buildDiscountIndicator(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Availability'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _quantityController,
              label: 'Quantity Available',
              icon: Icons.inventory,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'Quantity is required';
                final quantity = int.tryParse(value!);
                if (quantity == null || quantity <= 0) return 'Must be a positive number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildExpirationSelector(),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Terms & Conditions'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _termsController,
              label: 'Terms & Conditions (Optional)',
              icon: Icons.description,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffix: suffix,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDiscountIndicator() {
    final discount = _calculateDiscountPercentage();
    if (discount <= 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${discount.round()}% OFF',
        style: TextStyle(
          color: Colors.green.shade800,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return GestureDetector(
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
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Deal Image (Optional)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildExpirationSelector() {
    return GestureDetector(
      onTap: _selectExpirationTime,
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
                  const Text(
                    'Expiration Time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy at h:mm a').format(_expirationTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
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
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Consumer<DealsProvider>(
              builder: (context, dealsProvider, child) {
                return ElevatedButton.icon(
                  onPressed: dealsProvider.isLoading ? null : _createDeal,
                  icon: dealsProvider.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(dealsProvider.isLoading ? 'Creating...' : 'Create Deal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.template.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _calculateDiscountPercentage() {
    final originalPrice = double.tryParse(_originalPriceController.text) ?? 0;
    final dealPrice = double.tryParse(_dealPriceController.text) ?? 0;
    
    if (originalPrice > 0 && dealPrice > 0 && originalPrice > dealPrice) {
      return ((originalPrice - dealPrice) / originalPrice) * 100;
    }
    return 0;
  }

  String? _validatePrice(String? value) {
    if (value?.isEmpty == true) return 'Price is required';
    final price = double.tryParse(value!);
    if (price == null || price <= 0) return 'Must be a valid price';
    return null;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectExpirationTime() async {
    final now = DateTime.now();
    final initialDate = _expirationTime.isAfter(now) ? _expirationTime : now.add(Duration(hours: 4));
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(Duration(days: 365)),
    );
    
    if (selectedDate != null && mounted) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      
      if (selectedTime != null) {
        setState(() {
          _expirationTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }

  Widget _buildStartTimeSection() {
  bool _scheduleForLater = false;
  DateTime? _customStartTime;
  
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deal Start Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Schedule for later'),
            subtitle: Text(_scheduleForLater 
                ? 'Deal will start at scheduled time'
                : 'Deal starts immediately when created'),
            value: _scheduleForLater,
            onChanged: (value) {
              setState(() {
                _scheduleForLater = value;
                if (!value) {
                  _customStartTime = null;
                } else {
                  _customStartTime = DateTime.now().add(const Duration(hours: 1));
                }
              });
            },
          ),
          
          if (_scheduleForLater) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _customStartTime ?? DateTime.now().add(const Duration(hours: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        setState(() {
                          _customStartTime = DateTime(
                            date.year, date.month, date.day,
                            _customStartTime?.hour ?? DateTime.now().hour + 1,
                            _customStartTime?.minute ?? DateTime.now().minute,
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_customStartTime != null
                        ? DateFormat('MMM dd').format(_customStartTime!)
                        : 'Pick Date'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _customStartTime != null
                            ? TimeOfDay.fromDateTime(_customStartTime!)
                            : TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          final now = DateTime.now();
                          _customStartTime = DateTime(
                            _customStartTime?.year ?? now.year,
                            _customStartTime?.month ?? now.month,
                            _customStartTime?.day ?? now.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(_customStartTime != null
                        ? DateFormat('h:mm a').format(_customStartTime!)
                        : 'Pick Time'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
  Future<void> _createDeal() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _isCustomizing = true);
      return;
    }
    
    final dealsProvider = Provider.of<DealsProvider>(context, listen: false);
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    
    try {
      // Create deal object
      final deal = Deal(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: widget.business.category,
        latitude: widget.business.latitude,
        longitude: widget.business.longitude,
        originalPrice: double.parse(_originalPriceController.text),
        dealPrice: double.parse(_dealPriceController.text),
        totalQuantity: int.parse(_quantityController.text),
        businessId: widget.business.id!,
        businessName: widget.business.name,
        expirationTime: _expirationTime,
        termsAndConditions: _termsController.text.trim().isEmpty 
            ? null 
            : _termsController.text.trim(),

        
      );
      
      // Track customizations for analytics
      final customizations = {
        'templateId': widget.template.id,
        'titleChanged': deal.title != widget.template.generateDeal(widget.business).title,
        'descriptionChanged': deal.description != widget.template.generateDeal(widget.business).description,
        'priceChanged': deal.originalPrice != widget.template.generateDeal(widget.business).originalPrice ||
                      deal.dealPrice != widget.template.generateDeal(widget.business).dealPrice,
        'quantityChanged': deal.totalQuantity != widget.template.generateDeal(widget.business).totalQuantity,
        'expirationChanged': _expirationTime != widget.template.generateDeal(widget.business).expirationTime,
        'imageAdded': _selectedImage != null,
      };
      
      // Create the deal
      final success = await dealsProvider.createDeal(deal, imageFile: _selectedImage);
      
      if (success && mounted) {
        // Track template usage
        await _templateManager.trackTemplateUsage(
          widget.business.id!,
          widget.template.id,
          deal.id ?? '',
          customizations,
        );
        
        // Update business stats
        await businessProvider.updateBusinessStats(1);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.template.name} deal created successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                Navigator.pop(context); // Go back to templates
                // Could navigate to deal details here
              },
            ),
          ),
        );
        
        // Return to previous screen
        Navigator.pop(context);
      } else if (mounted && dealsProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dealsProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create deal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}