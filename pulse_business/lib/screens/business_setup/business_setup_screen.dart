import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../services/google_places_service.dart';
import '../../utils/theme.dart';

import '../../widgets/business_autocomplete_field.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/privacy_policy_screen.dart';


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
  final _streetNumberController = TextEditingController();
  final _streetNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'Canada');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _businessHoursController = TextEditingController();
  final GooglePlacesService _placesService = GooglePlacesService();
  double? _userLat;
  double? _userLng;
  bool _autoFilled = false; // Track if we auto-filled from Google
  
  String _selectedCategory = 'Restaurant';
  File? _selectedImage;
  LatLng _selectedLocation = const LatLng(43.6532, -79.3832); // Toronto default
  GoogleMapController? _mapController;
  int _currentPage = 0;
  bool _isGeocodingAddress = false;
  bool _acceptedTerms = false;
  bool _acceptedProhibitedItems = false;
  bool _isCreatingBusiness = false;

  final List<String> _categories = [
    'Restaurant', 'Cafe', 'Shop', 'Activity', 'Salon', 
    'Fitness', 'Entertainment', 'Services', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _emailController.text = authProvider.currentUser?.email ?? '';
    _initUserLocation();
  }

Future<void> _initUserLocation() async {
  final pos = await _placesService.getCurrentPosition();
  if (pos != null && mounted) {
    setState(() {
      _userLat = pos.latitude;
      _userLng = pos.longitude;
    });
  }
}

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _streetNumberController.dispose();
    _streetNameController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _businessHoursController.dispose();
    _pageController.dispose();
    _placesService.dispose();
    super.dispose();
  }

  String _getFullAddress() {
    final parts = [
      _streetNumberController.text.trim(),
      _streetNameController.text.trim(),
      _cityController.text.trim(),
      _zipCodeController.text.trim(),
      _countryController.text.trim(),
    ].where((part) => part.isNotEmpty);
    
    return parts.join(', ');
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
                _buildTermsPage(),
                
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
          for (int i = 0; i < 4; i++)
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
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
            
           BusinessAutocompleteField(
  controller: _businessNameController,
  placesService: _placesService,
  userLat: _userLat,
  userLng: _userLng,
  onPlaceSelected: _applyPlaceDetails,
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
          _buildAutoFilledBanner(),
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
            maxLines: 8,
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
        Expanded(
          child: SingleChildScrollView(
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
                _buildAutoFilledBanner(),
                const SizedBox(height: 8),
                Text(
                  'Enter your business address',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _streetNumberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Number *',
                          prefixIcon: Icon(Icons.tag),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _streetNameController,
                        decoration: const InputDecoration(
                          labelText: 'Street Name *',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'City is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _zipCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Postal/Zip Code *',
                          prefixIcon: Icon(Icons.mail),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country *',
                          prefixIcon: Icon(Icons.flag),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGeocodingAddress ? null : _geocodeAddress,
                    icon: _isGeocodingAddress
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.pin_drop),
                    label: Text(_isGeocodingAddress ? 'Finding location...' : 'Pin Location on Map'),
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
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
                const SizedBox(height: 8),
                Text(
                  'Tap on the map to adjust the pin location',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  
Widget _buildTermsPage() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Conditions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Please review and accept the following to continue:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Prohibited Items Checkbox
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _acceptedProhibitedItems ? Colors.green : Colors.red.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _acceptedProhibitedItems ? Colors.green.shade50 : Colors.red.shade50,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptedProhibitedItems,
                    onChanged: (value) {
                      setState(() {
                        _acceptedProhibitedItems = value ?? false;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _acceptedProhibitedItems = !_acceptedProhibitedItems;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(text: 'I confirm that I will '),
                              TextSpan(
                                text: 'NOT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const TextSpan(text: ' offer deals for:\n\n'),
                              TextSpan(
                                text: '• Alcoholic beverages, drinks, or bar specials\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              TextSpan(
                                text: '• Gambling, betting, or lottery services\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              TextSpan(
                                text: '• Cannabis or cannabis-related products\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              TextSpan(
                                text: '• Tobacco or vaping products\n\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              TextSpan(
                                text: '(Note: Restaurants/bars are welcome to offer food deals, but alcohol cannot be part of the promotion)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!_acceptedProhibitedItems)
                Padding(
                  padding: const EdgeInsets.only(left: 48, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '⚠️ You must confirm this to continue',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // General Terms Checkbox
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _acceptedTerms ? Colors.green : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _acceptedTerms ? Colors.green.shade50 : Colors.grey.shade50,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptedTerms = value ?? false;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            children: [
                              const Text(
                                'I agree to the ',
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TermsOfServiceScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Terms of Service',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Text(
                                ' and ',
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PrivacyPolicyScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to read the full documents',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!_acceptedTerms)
                Padding(
                  padding: const EdgeInsets.only(left: 48, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '⚠️ You must accept the terms to continue',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Info Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Businesses found violating these terms will be permanently removed from the platform.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                    height: 1.3,
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
  
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Logo *',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Square format recommended (min. 200x200px)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_selectedImage != null) ...[
          // Preview section when image is selected
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular preview (map marker)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.borderColor, width: 2),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Deal Card',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Rectangular preview (deal card)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor, width: 2),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Map Marker',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Change Logo'),
            ),
          ),
        ] else ...[
          // Upload placeholder when no image selected
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
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: AppTheme.textHint,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to upload logo',
                    style: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Square format works best',
                    style: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                      : Text(_currentPage == 3 ? 'Complete Setup' : 'Next'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildAutoFilledBanner() {
  if (!_autoFilled) return const SizedBox.shrink();
  
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.deepPurple.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.deepPurple.shade100),
    ),
    child: Row(
      children: [
        Icon(Icons.auto_awesome, color: Colors.deepPurple.shade400, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Auto-filled from Google. Review and adjust if needed.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ),
      ],
    ),
  );
}

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // Compress slightly for better performance
    );
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      
      // Validate image dimensions
      final isValid = await _validateImageDimensions(file);
      
      if (isValid) {
        setState(() {
          _selectedImage = file;
        });
      }
    }
  }

  Future<bool> _validateImageDimensions(File imageFile) async {
    try {
      // Decode image to get dimensions
      final bytes = await imageFile.readAsBytes();
      final image = await decodeImageFromList(bytes);
      
      final width = image.width;
      final height = image.height;
      
      // Check minimum dimensions
      if (width < 200 || height < 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Logo must be at least 200x200px\nYour image: ${width}x${height}px',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return false;
      }
      
      // Warn if not square (but don't reject)
      if ((width - height).abs() > width * 0.1) { // More than 10% difference
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tip: Square logos (${width}x${width}px) look best on maps and deal cards',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      
      return true;
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error validating image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _geocodeAddress() async {
    if (!_validateAddressFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all address fields first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGeocodingAddress = true);

    try {
      final fullAddress = _getFullAddress();
      final locations = await locationFromAddress(fullAddress);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final newLocation = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _selectedLocation = newLocation;
          _isGeocodingAddress = false;
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 17),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location pinned on map! Adjust if needed.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _isGeocodingAddress = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find this address. Please check and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isGeocodingAddress = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding address: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        
        setState(() {
          _streetNumberController.text = placemark.subThoroughfare ?? '';
          _streetNameController.text = placemark.thoroughfare ?? '';
          _cityController.text = placemark.locality ?? '';
          _zipCodeController.text = placemark.postalCode ?? '';
          _countryController.text = placemark.country ?? 'Canada';
        });
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
  if (_currentPage == 3) {  // Changed from 2 to 3
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
      return _validateAddressFields();
    }
  }

  bool _validateAddressFields() {
    return _streetNumberController.text.isNotEmpty &&
           _streetNameController.text.isNotEmpty &&
           _cityController.text.isNotEmpty &&
           _zipCodeController.text.isNotEmpty &&
           _countryController.text.isNotEmpty;
  }

  Future<void> _finishSetup() async {
    if (!_validateCurrentPage()) return;

    if (!_acceptedTerms || !_acceptedProhibitedItems) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please accept all terms and conditions to continue'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    
    final business = Business(
      name: _businessNameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory.toLowerCase(),
      address: _getFullAddress(),
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
    if (!mounted) return;

    if (success && mounted) {
      await authProvider.updateBusinessProfileStatus(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/stripe-onboarding', extra: true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(businessProvider.errorMessage ?? 'Failed to create business profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

void _applyPlaceDetails(PlaceDetails details) {
  setState(() {
    // ── Page 0: Basic Info ──
    _businessNameController.text = details.name;
    if (details.category != null && _categories.contains(details.category)) {
      _selectedCategory = details.category!;
    }
    if (details.description != null && details.description!.isNotEmpty) {
      _descriptionController.text = details.description!;
    }

    // ── Page 1: Contact ──
    if (details.phone != null && details.phone!.isNotEmpty) {
      _phoneController.text = details.phone!;
    }
    if (details.website != null && details.website!.isNotEmpty) {
      _websiteController.text = details.website!;
    }
    if (details.weekdayHours != null && details.weekdayHours!.isNotEmpty) {
      _businessHoursController.text = details.formattedHours;
    }

    // ── Page 2: Location ──
    if (details.streetNumber != null) {
      _streetNumberController.text = details.streetNumber!;
    }
    if (details.streetName != null) {
      _streetNameController.text = details.streetName!;
    }
    if (details.city != null) {
      _cityController.text = details.city!;
    }
    if (details.postalCode != null) {
      _zipCodeController.text = details.postalCode!;
    }
    if (details.country != null) {
      _countryController.text = details.country!;
    }
    if (details.lat != null && details.lng != null) {
      _selectedLocation = LatLng(details.lat!, details.lng!);
    }

    _autoFilled = true;
  });

  // Animate map to new location if available
  if (details.lat != null && details.lng != null) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(details.lat!, details.lng!),
        17,
      ),
    );
  }

  // Download Google photo as business logo (async, non-blocking)
  if (details.photoReference != null) {
    _downloadAndSetPhoto(details.photoReference!);
  }

  // Show success feedback - THIS is the wow moment
  _showAutoFillSuccess(details);
}

/// Downloads the Google Places photo and sets it as the business logo.
/// Runs async so it doesn't block the rest of the auto-fill.
Future<void> _downloadAndSetPhoto(String photoReference) async {
  try {
    final file = await _placesService.downloadPlacePhoto(photoReference);
    if (file != null && mounted) {
      setState(() {
        _selectedImage = file;
      });
      debugPrint('✅ Business photo auto-filled from Google');
    }
  } catch (e) {
    debugPrint('⚠️ Photo auto-fill failed (non-critical): $e');
    // Non-critical - user can still pick their own photo
  }
}

void _showAutoFillSuccess(PlaceDetails details) {
  // Count how many fields were auto-filled
  int fieldCount = 1; // name always filled
  if (details.phone != null) fieldCount++;
  if (details.website != null) fieldCount++;
  if (details.weekdayHours != null) fieldCount++;
  if (details.streetNumber != null) fieldCount++;
  if (details.streetName != null) fieldCount++;
  if (details.city != null) fieldCount++;
  if (details.postalCode != null) fieldCount++;
  if (details.category != null) fieldCount++;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text('$fieldCount fields auto-filled from Google!'),
        ],
      ),
      backgroundColor: Colors.deepPurple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ),
  );
}
}