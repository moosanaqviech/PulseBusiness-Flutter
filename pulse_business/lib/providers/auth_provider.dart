import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserProfile(user);
      } else {
        _currentUser = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        _currentUser = AppUser.fromMap(doc.data()!, user.uid);
      } else {
        // Create user profile if it doesn't exist
        _currentUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
        );
        await _firestore.collection('users').doc(user.uid).set(_currentUser!.toMap());
      }
    } catch (e) {
      _errorMessage = 'Error loading user profile: $e';
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _loadUserProfile(credential.user!);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Sign in failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createUserWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Send email verification
        await credential.user!.sendEmailVerification();
        
        // Create user profile
        _currentUser = AppUser(
          uid: credential.user!.uid,
          email: email,
        );
        
        await _firestore.collection('users').doc(credential.user!.uid).set(_currentUser!.toMap());
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Account creation failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Sign out failed: $e';
      notifyListeners();
    }
  }

  Future<void> updateBusinessProfileStatus(bool hasProfile) async {
    if (_currentUser != null) {
      try {
        _currentUser = _currentUser!.copyWith(hasBusinessProfile: hasProfile);
        await _firestore.collection('users').doc(_currentUser!.uid).update({
          'hasBusinessProfile': hasProfile,
        });
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Error updating profile status: $e';
        notifyListeners();
      }
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        _errorMessage = 'No account found with this email';
        break;
      case 'wrong-password':
        _errorMessage = 'Invalid email or password';
        break;
      case 'email-already-in-use':
        _errorMessage = 'An account with this email already exists';
        break;
      case 'weak-password':
        _errorMessage = 'Password is too weak. Use at least 6 characters';
        break;
      case 'invalid-email':
        _errorMessage = 'Please enter a valid email address';
        break;
      default:
        _errorMessage = e.message ?? 'Authentication failed';
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
}