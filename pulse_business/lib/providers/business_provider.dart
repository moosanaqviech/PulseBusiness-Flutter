import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/business.dart';

class BusinessProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  Business? _currentBusiness;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Add this: Track Firestore listener
  StreamSubscription<DocumentSnapshot>? _businessSubscription;

  Business? get currentBusiness => _currentBusiness;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Your existing createBusiness method stays the same...
  Future<bool> createBusiness(Business business, {File? imageFile}) async {
    try {
      print('🔧 BusinessProvider: Creating business for owner: ${business.ownerId}');
      _setLoading(true);
      _clearError();

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile, business.ownerId);
      }

      final businessWithImage = business.copyWith(
        id: business.ownerId,
        imageUrl: imageUrl,
      );
      
      await _firestore
          .collection('businesses')
          .doc(business.ownerId)
          .set(businessWithImage.toMap());

      _currentBusiness = businessWithImage;
      print('🔧 BusinessProvider: Business created with ID: ${_currentBusiness?.id}');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ BusinessProvider: Error creating business: $e');
      _errorMessage = 'Failed to create business profile: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Your existing updateBusiness method stays the same...
  Future<bool> updateBusiness(Business business, {File? imageFile}) async {
    try {
      print('🔧 BusinessProvider: Updating business: ${business.id}');
      _setLoading(true);
      _clearError();

      String? imageUrl = business.imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile, business.ownerId);
      }

      final updatedBusiness = business.copyWith(
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );
      
      await _firestore
          .collection('businesses')
          .doc(business.id ?? business.ownerId)
          .update(updatedBusiness.toMap());

      _currentBusiness = updatedBusiness;
      print('🔧 BusinessProvider: Business updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ BusinessProvider: Error updating business: $e');
      _errorMessage = 'Failed to update business profile: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // UPDATED: Load business with proper listener tracking
  Future<void> loadBusiness(String ownerId) async {
    try {
      print('🔧 BusinessProvider: Loading business for owner: $ownerId');
      _setLoading(true);
      _clearError();

      // Cancel any existing subscription first
      await _businessSubscription?.cancel();

      final doc = await _firestore.collection('businesses').doc(ownerId).get();
      
      if (doc.exists) {
        _currentBusiness = Business.fromMap(doc.data()!, id: doc.id);
        print('🔧 BusinessProvider: Business loaded with ID: ${_currentBusiness?.id}');
      } else {
        _currentBusiness = null;
        print('🔧 BusinessProvider: No business found for owner: $ownerId');
      }
      notifyListeners();
    } catch (e) {
      print('❌ BusinessProvider: Error loading business: $e');
      _errorMessage = 'Failed to load business profile: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Your existing _uploadImage method stays the same...
  Future<String> _uploadImage(File imageFile, String ownerId) async {
    try {
      print('🔧 BusinessProvider: Starting image upload for owner: $ownerId');
      
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }
      
      final fileName = 'business_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage
          .ref()
          .child('business_images')
          .child(ownerId)
          .child(fileName);
      
      print('🔧 BusinessProvider: Uploading to path: business_images/$ownerId/$fileName');
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_by': 'pulse_business',
          'upload_time': DateTime.now().toIso8601String(),
          'user_id': ownerId,
        },
      );
      
      final uploadTask = await ref.putFile(imageFile, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      print('🔧 BusinessProvider: Upload successful: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ BusinessProvider: Upload failed: $e');
      throw Exception('Failed to upload business image: $e');
    }
  }

  // Your existing updateBusinessStats method stays the same...
  Future<void> updateBusinessStats(int dealCountChange) async {
    if (_currentBusiness == null) {
      print('❌ BusinessProvider: Cannot update stats - no business loaded');
      return;
    }

    if (_currentBusiness!.id == null) {
      print('❌ BusinessProvider: Cannot update stats - business has no ID');
      return;
    }

    try {
      print('🔧 BusinessProvider: Updating business stats by: $dealCountChange');
      
      final newTotalDeals = (_currentBusiness!.totalDeals + dealCountChange).clamp(0, double.infinity).toInt();
      final newActiveDeals = (_currentBusiness!.activeDeals + dealCountChange).clamp(0, double.infinity).toInt();

      await _firestore.collection('businesses').doc(_currentBusiness!.id).update({
        'totalDeals': newTotalDeals,
        'activeDeals': newActiveDeals,
      });

      _currentBusiness = _currentBusiness!.copyWith(
        totalDeals: newTotalDeals,
        activeDeals: newActiveDeals,
      );
      
      print('🔧 BusinessProvider: Stats updated - Total: $newTotalDeals, Active: $newActiveDeals');
      notifyListeners();
    } catch (e) {
      print('❌ BusinessProvider: Error updating business stats: $e');
      _errorMessage = 'Failed to update business stats: $e';
      notifyListeners();
    }
  }

  // NEW: Clear all business data and stop listeners
  void clearBusinessData() {
    print('🔧 BusinessProvider: Clearing business data and stopping listeners');
    
    // Cancel any active Firestore subscriptions
    _businessSubscription?.cancel();
    _businessSubscription = null;
    
    // Clear business data
    _currentBusiness = null;
    _isLoading = false;
    _errorMessage = null;
    
    print('🔧 BusinessProvider: Business data cleared');
    notifyListeners();
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

  @override
  void dispose() {
    print('🔧 BusinessProvider: Disposing and cleaning up');
    _businessSubscription?.cancel();
    super.dispose();
  }
}