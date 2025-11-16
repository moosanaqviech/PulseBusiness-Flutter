import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'business_provider.dart';

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
    print('🔧 AuthProvider: Initializing...');
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    print('🔧 AuthProvider: Starting auth initialization');
    
    try {
      // Check current user immediately
      final currentFirebaseUser = _auth.currentUser;
      print('🔧 AuthProvider: Current Firebase user: ${currentFirebaseUser?.uid}');
      
      if (currentFirebaseUser != null) {
        print('🔧 AuthProvider: Loading user profile for existing user');
        await _loadUserProfile(currentFirebaseUser);
      } else {
        print('🔧 AuthProvider: No current user found');
        _currentUser = null;
      }
      
      _isInitialized = true;
      print('🔧 AuthProvider: Initialization complete. User: ${_currentUser?.uid}');
      notifyListeners();
      
      // Listen for auth state changes
      _auth.authStateChanges().listen((User? user) async {
        print('🔧 AuthProvider: Auth state changed. User: ${user?.uid}');
        
        if (user != null) {
          await _loadUserProfile(user);
        } else {
          _currentUser = null;
        }
        
        if (!_isInitialized) {
          _isInitialized = true;
        }
        
        print('🔧 AuthProvider: Auth state updated. Current user: ${_currentUser?.uid}');
        notifyListeners();
      });
      
    } catch (e) {
      print('❌ AuthProvider: Error during initialization: $e');
      _errorMessage = 'Initialization error: $e';
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile(User user) async {
    try {
      print('🔧 AuthProvider: Loading profile for user: ${user.uid}');
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        print('🔧 AuthProvider: User document found');
        _currentUser = AppUser.fromMap(doc.data()!, user.uid);
        print('🔧 AuthProvider: User loaded - hasBusinessProfile: ${_currentUser?.hasBusinessProfile}');
      } else {
        print('🔧 AuthProvider: No user document found, creating new one');
        // Create user profile if it doesn't exist
        _currentUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
        );
        await _firestore.collection('users').doc(user.uid).set(_currentUser!.toMap());
        print('🔧 AuthProvider: New user document created');
      }
    } catch (e) {
      print('❌ AuthProvider: Error loading user profile: $e');
      _errorMessage = 'Error loading user profile: $e';
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('🔧 AuthProvider: Attempting sign in for: $email');
      _setLoading(true);
      _clearError();
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        print('🔧 AuthProvider: Sign in successful');
        await _loadUserProfile(credential.user!);
        return true;
      }
      print('❌ AuthProvider: Sign in failed - no user returned');
      return false;
    } on FirebaseAuthException catch (e) {
      print('❌ AuthProvider: Firebase auth error: ${e.code} - ${e.message}');
      _handleAuthError(e);
      return false;
    }  finally {
      _setLoading(false);
    }
  }

  Future<bool> createUserWithEmailAndPassword(String email, String password) async {
    try {
      print('🔧 AuthProvider: Creating account for: $email');
      _setLoading(true);
      _clearError();
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        print('🔧 AuthProvider: Account creation successful');
        
        // Send email verification
        await credential.user!.sendEmailVerification();
        print('🔧 AuthProvider: Verification email sent');
        
        // Create user profile
        _currentUser = AppUser(
          uid: credential.user!.uid,
          email: email,
        );
        
        await _firestore.collection('users').doc(credential.user!.uid).set(_currentUser!.toMap());
        print('🔧 AuthProvider: User profile created in Firestore');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      print('❌ AuthProvider: Firebase auth error during creation: ${e.code} - ${e.message}');
      _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
    print('🔧 AuthProvider: Starting sign out process');
    _setLoading(true);
    
    // Clear Firebase auth
    await _auth.signOut();
    print('🔧 AuthProvider: Firebase auth cleared');
    
    // Clear all local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('🔧 AuthProvider: Local storage cleared');
    
    // Clear user state
    _currentUser = null;
    _isInitialized = false; // Reset initialization
    
    print('🔧 AuthProvider: Sign out successful');
    notifyListeners();
  } catch (e) {
    print('❌ AuthProvider: Error during sign out: $e');
    _errorMessage = 'Sign out failed: $e';
    notifyListeners();
    rethrow; // Let the calling code handle the error
  } finally {
    _setLoading(false);
  }
  }

  Future<void> updateBusinessProfileStatus(bool hasProfile) async {
    if (_currentUser != null) {
      try {
        print('🔧 AuthProvider: Updating business profile status to: $hasProfile');
        _currentUser = _currentUser!.copyWith(hasBusinessProfile: hasProfile);
        await _firestore.collection('users').doc(_currentUser!.uid).update({
          'hasBusinessProfile': hasProfile,
        });
        print('🔧 AuthProvider: Business profile status updated successfully');
        notifyListeners();
      } catch (e) {
        print('❌ AuthProvider: Error updating profile status: $e');
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