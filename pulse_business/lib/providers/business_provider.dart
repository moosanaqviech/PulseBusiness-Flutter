import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/business.dart';
import '../models/business_profile.dart';



class BusinessProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  Business? _currentBusiness;
  bool _isLoading = false;
  String? _errorMessage;

  Business? get currentBusiness => _currentBusiness;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BusinessProfile? _businessProfile;
  BusinessProfile? get businessProfile => _businessProfile;

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
        id: business.ownerId, // Set the ID immediately
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

  Future<void> loadBusiness(String ownerId) async {
    try {
      print('🔧 BusinessProvider: Loading business for owner: $ownerId');
      _setLoading(true);
      _clearError();

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

  Future<String> _uploadImage(File imageFile, String ownerId) async {
    try {
      final ref = _storage.ref().child('businesses/$ownerId.jpg');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

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

 /// Load business profile (converted from Business)
Future<void> loadBusinessProfile(String ownerId) async {
  try {
    _setLoading(true);
    _clearError();

    final doc = await _firestore.collection('businesses').doc(ownerId).get();
    
    if (doc.exists) {
      // ✅ FIXED: Use fromMap method that exists in your Business model
      final business = Business.fromMap(doc.data()!, id: doc.id);
      _currentBusiness = business;
      _businessProfile = BusinessProfile.fromBusiness(business);
      print('✅ BusinessProvider: Profile loaded for: ${_businessProfile?.businessName}');
    } else {
      _businessProfile = null;
      _currentBusiness = null;
      print('⚠️ BusinessProvider: No business profile found for: $ownerId');
    }
    
    notifyListeners();
  } catch (e) {
    print('❌ BusinessProvider: Error loading business profile: $e');
    _errorMessage = 'Failed to load business profile: $e';
    notifyListeners();
  } finally {
    _setLoading(false);
  }
}

/// Update business profile
Future<bool> updateBusinessProfile(BusinessProfile profile) async {
  try {
    _setLoading(true);
    _clearError();

    // Convert BusinessProfile back to Business model for storage
    final business = profile.toBusiness();
    
    await _firestore
        .collection('businesses')
        .doc(profile.id)
        .set(business.toMap(), SetOptions(merge: true));

    _businessProfile = profile;
    _currentBusiness = business;
    
    print('✅ BusinessProvider: Profile updated for: ${profile.businessName}');
    notifyListeners();
    return true;
  } catch (e) {
    print('❌ BusinessProvider: Error updating business profile: $e');
    _errorMessage = 'Failed to update business profile: $e';
    notifyListeners();
    return false;
  } finally {
    _setLoading(false);
  }
}

/// Create initial business profile from Business
Future<bool> createBusinessProfile(BusinessProfile profile) async {
  try {
    _setLoading(true);
    _clearError();

    final business = profile.toBusiness();
    
    await _firestore
        .collection('businesses')
        .doc(profile.ownerId)
        .set(business.toMap());

    _businessProfile = profile;
    _currentBusiness = business;
    
    print('✅ BusinessProvider: Profile created for: ${profile.businessName}');
    notifyListeners();
    return true;
  } catch (e) {
    print('❌ BusinessProvider: Error creating business profile: $e');
    _errorMessage = 'Failed to create business profile: $e';
    notifyListeners();
    return false;
  } finally {
    _setLoading(false);
  }
}



/// Check if user has a complete business profile
bool get hasCompleteProfile {
  return _businessProfile?.isComplete ?? false;
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

  void clearBusiness() {
    _currentBusiness = null;
    notifyListeners();
  }
}