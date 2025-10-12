// lib/screens/business_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/business_provider.dart';
import '../models/business_profile.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  
  String _selectedCategory = 'restaurant';
  bool _isLoading = false;
  
  final List<String> _categories = [
    'restaurant',
    'retail',
    'service',
    'health',
    'entertainment',
    'automotive',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  void _loadBusinessProfile() {
    final businessProvider = context.read<BusinessProvider>();
    final profile = businessProvider.businessProfile;
    
    if (profile != null) {
      _businessNameController.text = profile.businessName;
      _descriptionController.text = profile.description ?? '';
      _phoneController.text = profile.phoneNumber ?? '';
      _emailController.text = profile.email ?? '';
      _addressController.text = profile.address ?? '';
      _websiteController.text = profile.website ?? '';
      _selectedCategory = profile.category ?? 'restaurant';
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImageSection(),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Basic Information'),
              _buildTextField(
                controller: _businessNameController,
                label: 'Business Name',
                required: true,
                icon: Icons.business,
              ),
              const SizedBox(height: 16),
              
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
                icon: Icons.description,
                hint: 'Tell customers about your business...',
              ),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Contact Information'),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                icon: Icons.phone,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                maxLines: 2,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _websiteController,
                label: 'Website',
                keyboardType: TextInputType.url,
                icon: Icons.web,
                hint: 'https://yourwebsite.com',
              ),
              
              const SizedBox(height: 24),
              _buildBusinessHoursSection(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: businessProvider.businessProfile?.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(
                              businessProvider.businessProfile!.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                            ),
                          )
                        : _buildImagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to change business logo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
        SizedBox(height: 8),
        Text('Add Logo', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? icon,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) {
              if (value?.isEmpty ?? true) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Business Category',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
    );
  }

  Widget _buildBusinessHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Business Hours'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHourRow('Monday', '9:00 AM', '6:00 PM'),
                _buildHourRow('Tuesday', '9:00 AM', '6:00 PM'),
                _buildHourRow('Wednesday', '9:00 AM', '6:00 PM'),
                _buildHourRow('Thursday', '9:00 AM', '6:00 PM'),
                _buildHourRow('Friday', '9:00 AM', '6:00 PM'),
                _buildHourRow('Saturday', '10:00 AM', '4:00 PM'),
                _buildHourRow('Sunday', 'Closed', 'Closed'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHourRow(String day, String openTime, String closeTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showTimePicker(day, 'open'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(openTime),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('to'),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showTimePicker(day, 'close'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(closeTime),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(String day, String type) {
    // TODO: Implement time picker for business hours
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Time picker for $day $type coming soon')),
    );
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isLoading = true);
      
      try {
        // TODO: Upload image to Firebase Storage
        // For now, just show success message
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image upload feature coming soon'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final businessProvider = context.read<BusinessProvider>();
      
      // Create updated profile
      final updatedProfile = BusinessProfile(
        id: businessProvider.businessProfile?.id ?? '',
        ownerId: businessProvider.businessProfile?.ownerId ?? '',
        businessName: _businessNameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        website: _websiteController.text.trim(),
        logoUrl: businessProvider.businessProfile?.logoUrl,
        isVerified: businessProvider.businessProfile?.isVerified ?? false,
        createdAt: businessProvider.businessProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await businessProvider.updateBusinessProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}