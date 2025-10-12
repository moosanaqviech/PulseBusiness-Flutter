import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/deal.dart';

enum DealFilter { all, active, expired, soldOut }

class DealsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  List<Deal> _allDeals = [];
  List<Deal> _filteredDeals = [];
  DealFilter _currentFilter = DealFilter.all;
  bool _isLoading = false;
  String? _errorMessage;

  List<Deal> get allDeals => _allDeals;
  List<Deal> get filteredDeals => _filteredDeals;
  List<Deal> get recentDeals => _allDeals.take(5).toList();
  DealFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Dashboard statistics
  int get totalActiveDeals => _allDeals.where((deal) => 
    deal.isActive && !deal.isExpired && !deal.isSoldOut).length;
  
  int get totalViews => _allDeals.fold(0, (sum, deal) => sum + deal.viewCount);
  
  int get totalClaims => _allDeals.fold(0, (sum, deal) => sum + deal.claimCount);
  
  double get totalRevenue => _allDeals.fold(0.0, 
    (sum, deal) => sum + (deal.claimCount * deal.dealPrice));
  
  double get conversionRate => totalViews > 0 ? (totalClaims / totalViews) * 100 : 0.0;
  
  double get averageDiscount {
    final dealsWithDiscount = _allDeals.where((deal) => 
      deal.originalPrice > deal.dealPrice).toList();
    if (dealsWithDiscount.isEmpty) return 0.0;
    
    final totalDiscount = dealsWithDiscount.fold(0.0, 
      (sum, deal) => sum + deal.discountPercentage);
    return totalDiscount / dealsWithDiscount.length;
  }

  // Replace your existing createDeal method in DealsProvider with this fail-proof version

Future<bool> createDeal(Deal deal, {File? imageFile}) async {
  String? uploadedImageUrl;
  String? documentId;
  bool imageUploadCompleted = false;
  bool firestoreWriteCompleted = false;
  
  try {
    print('🔧 DealsProvider: Starting deal creation process: ${deal.title}');
    _setLoading(true);
    _clearError();

    // Validate inputs first
    if (!_validateDealInputs(deal)) {
      _errorMessage = 'Invalid deal data provided';
      return false;
    }

    // Step 1: Handle image upload with comprehensive error handling
    if (imageFile != null) {
      uploadedImageUrl = await _uploadImageWithRetry(imageFile);
      imageUploadCompleted = true;
      print('✅ DealsProvider: Image upload completed: $uploadedImageUrl');
    }

    // Step 2: Create deal in Firestore with retry logic
    final dealWithImage = deal.copyWith(imageUrl: uploadedImageUrl);
    documentId = await _createDealDocumentWithRetry(dealWithImage);
    firestoreWriteCompleted = true;
    print('✅ DealsProvider: Firestore document created: $documentId');
    
    // Step 3: Update local state only after successful remote operations
    final createdDeal = dealWithImage.copyWith(id: documentId);
    _allDeals.insert(0, createdDeal);
    _applyFilter();
    
    print('✅ DealsProvider: Deal creation completed successfully');
    return true;

  } catch (e, stackTrace) {
    print('❌ DealsProvider: Critical error in deal creation: $e');
    print('❌ DealsProvider: Stack trace: $stackTrace');
    
    // Attempt cleanup of partial operations
    await _cleanupFailedDealCreation(
      uploadedImageUrl: uploadedImageUrl,
      documentId: documentId,
      imageUploadCompleted: imageUploadCompleted,
      firestoreWriteCompleted: firestoreWriteCompleted,
    );
    
    // Set user-friendly error message
    _errorMessage = _getUserFriendlyErrorMessage(e);
    return false;
    
  } finally {
    // CRITICAL: Always reset loading state, no matter what happens
    _setLoading(false);
    notifyListeners();
    print('🔧 DealsProvider: Loading state reset and listeners notified');
  }
}

// Validate deal inputs before processing
bool _validateDealInputs(Deal deal) {
  try {
    if (deal.title.trim().isEmpty) {
      print('❌ Validation failed: Empty title');
      return false;
    }
    if (deal.description.trim().isEmpty) {
      print('❌ Validation failed: Empty description');
      return false;
    }
    if (deal.originalPrice <= 0 || deal.dealPrice <= 0) {
      print('❌ Validation failed: Invalid prices');
      return false;
    }
    if (deal.dealPrice >= deal.originalPrice) {
      print('❌ Validation failed: Deal price not less than original');
      return false;
    }
    if (deal.totalQuantity <= 0) {
      print('❌ Validation failed: Invalid quantity');
      return false;
    }
    if (deal.businessId.isEmpty) {
      print('❌ Validation failed: Missing business ID');
      return false;
    }
    if (deal.expirationTime.isBefore(DateTime.now())) {
      print('❌ Validation failed: Expiration time in past');
      return false;
    }
    return true;
  } catch (e) {
    print('❌ Validation error: $e');
    return false;
  }
}

// Upload image with retry logic and comprehensive error handling
Future<String> _uploadImageWithRetry(File imageFile, {int maxRetries = 3}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      print('🔧 DealsProvider: Image upload attempt $attempt/$maxRetries');
      
      // Validate file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }
      
      // Check file size (limit to 10MB)
      final fileSizeInBytes = await imageFile.length();
      const maxFileSizeInBytes = 10 * 1024 * 1024; // 10MB
      if (fileSizeInBytes > maxFileSizeInBytes) {
        throw Exception('Image file too large (max 10MB). Current size: ${(fileSizeInBytes / 1024 / 1024).toStringAsFixed(1)}MB');
      }
      
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'deals/${timestamp}_${attempt}.jpg';
      final ref = _storage.ref().child(fileName);
      
      print('🔧 DealsProvider: Starting upload to: $fileName');
      
      // CRITICAL FIX: Use putData() instead of putFile() to avoid metadata bug
      final bytes = await imageFile.readAsBytes();
      
      // Upload with proper metadata that won't trigger the bug
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': 'business_app',
            'timestamp': timestamp.toString(),
          },
        ),
      );
      
      // Monitor upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('🔧 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      // Wait for upload completion with timeout
      final taskSnapshot = await uploadTask.timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw Exception('Image upload timeout after 3 minutes'),
      );
      
      // Get download URL with timeout
      final downloadUrl = await taskSnapshot.ref.getDownloadURL().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Failed to get download URL'),
      );
      
      print('✅ DealsProvider: Image uploaded successfully: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ DealsProvider: Image upload attempt $attempt failed: $e');
      
      if (attempt == maxRetries) {
        // Final attempt failed
        throw Exception('Image upload failed after $maxRetries attempts: $e');
      }
      
      // Wait before retry (exponential backoff)
      final waitTime = Duration(seconds: attempt * 2);
      print('🔧 DealsProvider: Waiting ${waitTime.inSeconds}s before retry...');
      await Future.delayed(waitTime);
    }
  }
  
  throw Exception('Image upload failed: Maximum retries exceeded');
}

// Also update your existing _uploadImage method in BusinessProvider with the same fix
Future<String> _uploadImage(File imageFile, String ownerId) async {
  try {
    final ref = _storage.ref().child('businesses/$ownerId.jpg');
    
    // CRITICAL FIX: Use putData() instead of putFile()
    final bytes = await imageFile.readAsBytes();
    
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': 'business_app',
          'businessId': ownerId,
        },
      ),
    );
    
    final taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  } catch (e) {
    throw Exception('Failed to upload image: $e');
  }
}

// Create Firestore document with retry logic
Future<String> _createDealDocumentWithRetry(Deal deal, {int maxRetries = 3}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      print('🔧 DealsProvider: Firestore write attempt $attempt/$maxRetries');
      
      // Convert deal to map and validate
      final dealMap = deal.toMap();
      if (dealMap.isEmpty) {
        throw Exception('Deal conversion to map failed');
      }
      
      // Write to Firestore with timeout
      final docRef = await _firestore
          .collection('deals')
          .add(dealMap)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Firestore write timeout'),
          );
      
      if (docRef.id.isEmpty) {
        throw Exception('Firestore returned empty document ID');
      }
      
      print('✅ DealsProvider: Firestore document created: ${docRef.id}');
      return docRef.id;
      
    } catch (e) {
      print('❌ DealsProvider: Firestore write attempt $attempt failed: $e');
      
      if (attempt == maxRetries) {
        throw Exception('Firestore write failed after $maxRetries attempts: $e');
      }
      
      // Wait before retry (exponential backoff)
      final waitTime = Duration(seconds: attempt * 2);
      print('🔧 DealsProvider: Waiting ${waitTime.inSeconds}s before retry...');
      await Future.delayed(waitTime);
    }
  }
  
  throw Exception('Firestore write failed: Maximum retries exceeded');
}

// Cleanup partial operations in case of failure
Future<void> _cleanupFailedDealCreation({
  String? uploadedImageUrl,
  String? documentId,
  required bool imageUploadCompleted,
  required bool firestoreWriteCompleted,
}) async {
  print('🧹 DealsProvider: Starting cleanup of failed deal creation...');
  
  try {
    // If Firestore document was created but something failed after, delete it
    if (firestoreWriteCompleted && documentId != null && documentId.isNotEmpty) {
      print('🧹 DealsProvider: Attempting to delete Firestore document: $documentId');
      await _firestore
          .collection('deals')
          .doc(documentId)
          .delete()
          .timeout(const Duration(seconds: 10))
          .catchError((e) {
        print('⚠️ DealsProvider: Failed to cleanup Firestore document: $e');
      });
    }
    
    // If image was uploaded but something failed after, attempt to delete it
    if (imageUploadCompleted && uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
      print('🧹 DealsProvider: Attempting to delete uploaded image: $uploadedImageUrl');
      try {
        final ref = _storage.refFromURL(uploadedImageUrl);
        await ref.delete().timeout(const Duration(seconds: 10));
        print('✅ DealsProvider: Uploaded image deleted successfully');
      } catch (e) {
        print('⚠️ DealsProvider: Failed to cleanup uploaded image: $e');
      }
    }
    
  } catch (e) {
    print('⚠️ DealsProvider: Error during cleanup: $e');
  }
  
  print('🧹 DealsProvider: Cleanup completed');
}

// Convert technical errors to user-friendly messages
String _getUserFriendlyErrorMessage(dynamic error) {
  final errorString = error.toString().toLowerCase();
  
  if (errorString.contains('network') || errorString.contains('connection')) {
    return 'Network connection error. Please check your internet and try again.';
  }
  
  if (errorString.contains('timeout')) {
    return 'The operation took too long. Please try again with a smaller image.';
  }
  
  if (errorString.contains('permission') || errorString.contains('unauthorized')) {
    return 'Permission error. Please sign out and sign back in.';
  }
  
  if (errorString.contains('file too large') || errorString.contains('10mb')) {
    return 'Image file is too large. Please use an image smaller than 10MB.';
  }
  
  if (errorString.contains('file does not exist')) {
    return 'Image file not found. Please select the image again.';
  }
  
  if (errorString.contains('storage') || errorString.contains('upload')) {
    return 'Image upload failed. Please try again or use a different image.';
  }
  
  if (errorString.contains('firestore') || errorString.contains('database')) {
    return 'Database error. Please try again in a moment.';
  }
  
  if (errorString.contains('validation')) {
    return 'Please check all fields and try again.';
  }
  
  // Generic fallback
  return 'Failed to create deal. Please try again or contact support if the problem persists.';
}


  Future<void> loadDeals(String businessId) async {
    try {
      _setLoading(true);
      _clearError();

      final querySnapshot = await _firestore
          .collection('deals')
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      _allDeals = querySnapshot.docs
          .map((doc) => Deal.fromMap(doc.data(), id: doc.id))
          .toList();
      
      _applyFilter();
    } catch (e) {
      _errorMessage = 'Failed to load deals: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDealStatus(String dealId, bool isActive) async {
    try {
      await _firestore.collection('deals').doc(dealId).update({
        'isActive': isActive,
        'status': isActive ? 'active' : 'paused',
      });

      final dealIndex = _allDeals.indexWhere((deal) => deal.id == dealId);
      if (dealIndex != -1) {
        _allDeals[dealIndex] = _allDeals[dealIndex].copyWith(
          isActive: isActive,
          status: isActive ? 'active' : 'paused',
        );
        _applyFilter();
      }
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update deal status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDeal(String dealId) async {
    try {
      await _firestore.collection('deals').doc(dealId).delete();
      
      _allDeals.removeWhere((deal) => deal.id == dealId);
      _applyFilter();
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete deal: $e';
      notifyListeners();
      return false;
    }
  }

  void setFilter(DealFilter filter) {
    _currentFilter = filter;
    _applyFilter();
  }

  void _applyFilter() {
    switch (_currentFilter) {
      case DealFilter.all:
        _filteredDeals = List.from(_allDeals);
        break;
      case DealFilter.active:
        _filteredDeals = _allDeals.where((deal) => 
          deal.isActive && !deal.isExpired && !deal.isSoldOut).toList();
        break;
      case DealFilter.expired:
        _filteredDeals = _allDeals.where((deal) => deal.isExpired).toList();
        break;
      case DealFilter.soldOut:
        _filteredDeals = _allDeals.where((deal) => deal.isSoldOut).toList();
        break;
    }
    notifyListeners();
  }

  String getEmptyStateMessage() {
    switch (_currentFilter) {
      case DealFilter.active:
        return 'No active deals found.\nCreate a new deal to get started!';
      case DealFilter.expired:
        return 'No expired deals found.';
      case DealFilter.soldOut:
        return 'No sold out deals found.';
      case DealFilter.all:
      default:
        return 'No deals found.\nCreate your first deal to get started!';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void clearDeals() {
    _allDeals.clear();
    _filteredDeals.clear();
    notifyListeners();
  }
}