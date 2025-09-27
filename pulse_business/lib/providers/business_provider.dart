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

  Business? get currentBusiness => _currentBusiness;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> createBusiness(Business business, {File? imageFile}) async {
    try {
      _setLoading(true);
      _clearError();

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile, business.ownerId);
      }

      final businessWithImage = business.copyWith(imageUrl: imageUrl);
      
      await _firestore
          .collection('businesses')
          .doc(business.ownerId)
          .set(businessWithImage.toMap());

      _currentBusiness = businessWithImage.copyWith(id: business.ownerId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create business profile: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateBusiness(Business business, {File? imageFile}) async {
    try {
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
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update business profile: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadBusiness(String ownerId) async {
    try {
      _setLoading(true);
      _clearError();

      final doc = await _firestore.collection('businesses').doc(ownerId).get();
      
      if (doc.exists) {
        _currentBusiness = Business.fromMap(doc.data()!, id: doc.id);
      } else {
        _currentBusiness = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to load business profile: $e';
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
    if (_currentBusiness == null) return;

    try {
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
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update business stats: $e';
      notifyListeners();
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

  void clearBusiness() {
    _currentBusiness = null;
    notifyListeners();
  }
}