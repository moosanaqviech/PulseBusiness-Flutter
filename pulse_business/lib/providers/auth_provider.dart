import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'business_provider.dart';
import 'deals_provider.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
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

  // ============================================
  // EMAIL & PASSWORD AUTHENTICATION
  // ============================================

  /// Sign in with email and password
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
    } catch (e) {
      print('❌ AuthProvider: Unexpected error: $e');
      _errorMessage = 'An unexpected error occurred';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Alternative method name for compatibility with AuthService pattern
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return signInWithEmailAndPassword(email, password);
  }

  /// Create new user with email and password
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
    } catch (e) {
      print('❌ AuthProvider: Unexpected error: $e');
      _errorMessage = 'An unexpected error occurred';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Alternative method name for compatibility with AuthService pattern
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
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
        
        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          await credential.user!.updateDisplayName(displayName);
          print('🔧 AuthProvider: Display name updated to: $displayName');
        }
        
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
    } catch (e) {
      print('❌ AuthProvider: Unexpected error: $e');
      _errorMessage = 'An unexpected error occurred';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================
  // GOOGLE SIGN IN
  // ============================================

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      print('🔧 AuthProvider: Starting Google sign in');
      _setLoading(true);
      _clearError();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('🔧 AuthProvider: Google sign in cancelled by user');
        _setLoading(false);
        return false; // User cancelled
      }

      print('🔧 AuthProvider: Google user selected: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        print('🔧 AuthProvider: Google sign in successful');
        await _loadUserProfile(result.user!);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      print('❌ AuthProvider: Firebase auth error: ${e.code} - ${e.message}');
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('❌ AuthProvider: Google sign in error: $e');
      _errorMessage = 'Google sign in failed';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================
  // PASSWORD RESET
  // ============================================

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    try {
      print('🔧 AuthProvider: Sending password reset email to: $email');
      _setLoading(true);
      _clearError();

      await _auth.sendPasswordResetEmail(email: email);
      print('🔧 AuthProvider: Password reset email sent');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ AuthProvider: Error sending reset email: ${e.code} - ${e.message}');
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('❌ AuthProvider: Unexpected error: $e');
      _errorMessage = 'Failed to send password reset email';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================
  // SIGN OUT
  // ============================================

  /// Sign out user
 Future<void> signOut(BuildContext context) async {
  try {
    print('🔧 AuthProvider: Starting sign out process');
    _setLoading(true);
    
    // STEP 1: Clean up BusinessProvider data BEFORE signing out
    try {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      businessProvider.clearBusinessData();
      print('🔧 AuthProvider: BusinessProvider cleaned up');
    } catch (e) {
      print('⚠️ AuthProvider: Error cleaning BusinessProvider: $e');
      // Continue with logout even if cleanup fails
    }
    
    // STEP 2: Clean up DealsProvider if it exists
    try {
      final dealsProvider = Provider.of<DealsProvider>(context, listen: false);
      if (dealsProvider != null) {
        // If your DealsProvider has a cleanup method, call it here
        // dealsProvider.clearDealsData();
        print('🔧 AuthProvider: DealsProvider cleaned up');
      }
    } catch (e) {
      print('⚠️ AuthProvider: Error cleaning DealsProvider: $e');
      // Continue with logout even if cleanup fails
    }
    
    // STEP 3: Sign out from Google if signed in with Google
    await _googleSignIn.signOut();
    
    // STEP 4: Clear Firebase auth
    await _auth.signOut();
    print('🔧 AuthProvider: Firebase auth cleared');
    
    // STEP 5: Clear all local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('🔧 AuthProvider: Local storage cleared');
    
    // STEP 6: Clear user state
    _currentUser = null;
    _isInitialized = false;
    
    print('🔧 AuthProvider: Sign out successful');
    notifyListeners();
  } catch (e) {
    print('❌ AuthProvider: Error during sign out: $e');
    _errorMessage = 'Sign out failed: $e';
    notifyListeners();
    rethrow;
  } finally {
    _setLoading(false);
  }
}
  // ============================================
  // BUSINESS PROFILE MANAGEMENT
  // ============================================

  /// Update business profile status
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

  // ============================================
  // HELPER METHODS
  // ============================================

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
      case 'user-disabled':
        _errorMessage = 'This user account has been disabled';
        break;
      case 'too-many-requests':
        _errorMessage = 'Too many requests. Try again later';
        break;
      case 'operation-not-allowed':
        _errorMessage = 'This sign-in method is not enabled';
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