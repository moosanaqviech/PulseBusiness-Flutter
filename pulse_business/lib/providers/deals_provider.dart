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

  Future<bool> createDeal(Deal deal, {File? imageFile}) async {
    try {
      _setLoading(true);
      _clearError();

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
      }

      final dealWithImage = deal.copyWith(imageUrl: imageUrl);
      
      final docRef = await _firestore.collection('deals').add(dealWithImage.toMap());
      
      final createdDeal = dealWithImage.copyWith(id: docRef.id);
      _allDeals.insert(0, createdDeal);
      _applyFilter();
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create deal: $e';
      return false;
    } finally {
      _setLoading(false);
    }
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

  Future<String> _uploadImage(File imageFile) async {
    try {
      final fileName = 'deals/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
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