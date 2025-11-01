import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/business.dart';
import '../../utils/theme.dart';
import '../stripe/stripe_onboarding_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Form controllers
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _businessHoursController = TextEditingController();
  
  String _selectedCategory = 'Restaurant';
  File? _selectedImage;
  LatLng _selectedLocation = const LatLng(43.6532, -79.3832); // Toronto default
  GoogleMapController? _mapController;
  int _currentPage = 0;

  final List<String> _categories = [
    'Restaurant', 'Cafe', 'Shop', 'Activity', 'Salon', 
    'Fitness', 'Entertainment', 'Services', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _emailController.text = authProvider.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _businessHoursController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Business'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildBasicInfoPage(),
                _buildContactPage(),
                _buildLocationPage(),
              ],
            ),
          ),
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
          for (int i = 0; i < 3; i++)
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                decoration: BoxDecoration(
                  color: i <= _currentPage ? AppTheme.primaryColor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about your business',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildImagePicker(),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name *',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Business name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'How can customers reach you?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: Icon(Icons.phone),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Website (Optional)',
              prefixIcon: Icon(Icons.language),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _businessHoursController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Business Hours (Optional)',
              prefixIcon: Icon(Icons.access_time),
              hintText: 'e.g., Mon-Fri: 9AM-6PM, Sat: 10AM-4PM',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Location',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap on the map to select your exact location',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 12,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('business_location'),
                position: _selectedLocation,
                infoWindow: const InfoWindow(title: 'Business Location'),
              ),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Photo',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.placeholderBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: AppTheme.textHint,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to select image',
                        style: TextStyle(color: AppTheme.textHint),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                child: const Text('Previous'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: Consumer<BusinessProvider>(
              builder: (context, businessProvider, child) {
                return ElevatedButton(
                  onPressed: businessProvider.isLoading ? null : _nextPageOrFinish,
                  child: businessProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_currentPage == 2 ? 'Complete Setup' : 'Next'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    final permission = await Permission.location.request();
    if (permission != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final newLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = newLocation;
      });
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLocation, 15),
      );
      
      await _updateAddressFromLocation(newLocation);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _updateAddressFromLocation(location);
  }

  Future<void> _updateAddressFromLocation(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
        _addressController.text = address;
      }
    } catch (e) {
      // Handle geocoding error silently
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPageOrFinish() {
    if (_currentPage == 2) {
      _finishSetup();
    } else {
      if (_validateCurrentPage()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  bool _validateCurrentPage() {
    if (_currentPage == 0) {
      return _businessNameController.text.isNotEmpty && 
             _descriptionController.text.isNotEmpty;
    } else if (_currentPage == 1) {
      return _phoneController.text.isNotEmpty;
    } else {
      return _addressController.text.isNotEmpty;
    }
  }

  Future<void> _finishSetup() async {
    if (!_validateCurrentPage()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    
    final business = Business(
      name: _businessNameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory.toLowerCase(),
      address: _addressController.text.trim(),
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      businessHours: _businessHoursController.text.trim().isEmpty ? null : _businessHoursController.text.trim(),
      ownerId: authProvider.currentUser!.uid,
    );

    final success = await businessProvider.createBusiness(
      business,
      imageFile: _selectedImage,
    );

    if (success && mounted) {
      await authProvider.updateBusinessProfileStatus(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to Stripe onboarding (with skip option)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const StripeOnboardingScreen(canSkip: true),
      ),
    );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(businessProvider.errorMessage ?? 'Failed to create business profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}