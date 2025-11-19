import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Authentication Service - Flutter Implementation
/// 
/// This service mirrors your Angular AuthService but adapted for Flutter.
/// Key differences from Angular:
/// 1. Flutter uses ChangeNotifier for reactive state (similar to RxJS BehaviorSubject)
/// 2. Firebase SDK methods return Futures instead of Observables
/// 3. Google Sign-In requires a separate package integration
///
/// Architecture Pattern:
/// - This service acts as a facade over Firebase Auth
/// - It provides a simple, consistent API for your UI layer
/// - State changes automatically notify listeners (similar to Angular's observables)
class AuthService with ChangeNotifier {
  // Firebase Auth instance - this is our connection to Firebase Authentication
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  // Google Sign-In instance - handles the OAuth flow with Google
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Current user state - null means not logged in
  // This is reactive: when it changes, all listeners are notified
  User? _currentUser;
  
  // Loading state - useful for showing progress indicators during auth operations
  bool _isLoading = false;
  
  // Error message - stores the last error for display in UI
  String? _errorMessage;

  // Constructor - sets up the auth state listener
  // This is similar to your Angular service's initialiseAuth() method
  AuthService() {
    _initializeAuthStateListener();
  }

  // GETTERS - Provide read-only access to private state
  // These are similar to your Angular service's public observables
  
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Get user ID - useful for API calls that need authentication
  String? get uid => _currentUser?.uid;
  
  // Get ID token - this is what you send to your Node.js API for authentication
  // Your API.js file expects this in the Authorization header
  Future<String?> get idToken async {
    if (_currentUser == null) return null;
    return await _currentUser!.getIdToken();
  }

  /// Initialize Auth State Listener
  /// 
  /// This method sets up a listener that watches for authentication state changes.
  /// It's like subscribing to onAuthStateChanged in your Angular service.
  /// 
  /// Why we need this:
  /// - Detects when user logs in/out
  /// - Detects when token expires and refreshes
  /// - Keeps UI in sync with auth state automatically
  void _initializeAuthStateListener() {
    _firebaseAuth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _errorMessage = null; // Clear any previous errors
      notifyListeners(); // Tell all widgets listening to this service to rebuild
      
      if (kDebugMode) {
        if (user != null) {
          print('AuthService: User logged in - ${user.email}');
        } else {
          print('AuthService: User logged out');
        }
      }
    });
  }

  /// Register with Email and Password
  /// 
  /// Creates a new user account in Firebase Authentication.
  /// Similar to your Angular registerWithEmail() method.
  /// 
  /// Process:
  /// 1. Set loading state
  /// 2. Call Firebase to create account
  /// 3. Optionally update display name
  /// 4. Send verification email
  /// 5. Handle success/errors
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);
      
      // Create the user account
      final UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload(); // Refresh user data
        _currentUser = _firebaseAuth.currentUser; // Get updated user
      }
      
      // Send email verification
      await credential.user?.sendEmailVerification();
      
      _setLoading(false);
      return true;
      
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Login with Email and Password
  /// 
  /// Authenticates an existing user with their credentials.
  /// Your Angular service has a similar loginWithEmail() method.
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _setLoading(false);
      return true;
      
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Sign In with Google
  /// 
  /// Implements Google OAuth sign-in flow.
  /// This is more complex than email/password because it involves:
  /// 1. Opening Google's sign-in UI
  /// 2. Getting OAuth tokens from Google
  /// 3. Exchanging those tokens for Firebase credentials
  /// 
  /// Your Angular service uses signInWithPopup - Flutter's approach is similar
  /// but uses the google_sign_in package instead of Firebase's built-in popup.
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      
      // Step 1: Trigger Google Sign-In flow
      // This opens Google's account picker and authentication UI
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // User cancelled the sign-in
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }
      
      // Step 2: Get OAuth credentials from Google
      // These prove to Firebase that Google authenticated the user
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Step 3: Create Firebase credential from Google tokens
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Step 4: Sign in to Firebase with the credential
      await _firebaseAuth.signInWithCredential(credential);
      
      _setLoading(false);
      return true;
      
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in failed: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Logout
  /// 
  /// Signs out from both Firebase and Google (if signed in with Google).
  /// This ensures complete cleanup of authentication state.
  Future<void> logout() async {
    try {
      _setLoading(true);
      
      // Sign out from Google if user signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
      _currentUser = null;
      _errorMessage = null;
      _setLoading(false);
      notifyListeners();
      
    } catch (e) {
      _errorMessage = 'Logout failed: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Send Password Reset Email
  /// 
  /// Sends a password reset link to the user's email.
  /// Firebase handles the email sending and reset page automatically.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send reset email: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Update User Profile
  /// 
  /// Updates the user's display name and/or photo URL.
  /// Changes are reflected immediately in the current user object.
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    if (_currentUser == null) {
      _errorMessage = 'No user logged in';
      return false;
    }
    
    try {
      _setLoading(true);
      
      if (displayName != null) {
        await _currentUser!.updateDisplayName(displayName);
      }
      
      if (photoURL != null) {
        await _currentUser!.updatePhotoURL(photoURL);
      }
      
      // Reload user data to get the updates
      await _currentUser!.reload();
      _currentUser = _firebaseAuth.currentUser;
      
      _setLoading(false);
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Handle Firebase Auth Errors
  /// 
  /// Converts Firebase error codes into user-friendly messages.
  /// This mirrors your Angular service's handleAuthError() method.
  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        _errorMessage = 'This email is already registered';
        break;
      case 'invalid-email':
        _errorMessage = 'Invalid email address';
        break;
      case 'operation-not-allowed':
        _errorMessage = 'Operation not allowed';
        break;
      case 'weak-password':
        _errorMessage = 'Password is too weak';
        break;
      case 'user-disabled':
        _errorMessage = 'This account has been disabled';
        break;
      case 'user-not-found':
        _errorMessage = 'No account found with this email';
        break;
      case 'wrong-password':
        _errorMessage = 'Incorrect password';
        break;
      case 'invalid-credential':
        _errorMessage = 'Invalid credentials provided';
        break;
      case 'account-exists-with-different-credential':
        _errorMessage = 'An account already exists with the same email address';
        break;
      case 'invalid-verification-code':
        _errorMessage = 'Invalid verification code';
        break;
      case 'invalid-verification-id':
        _errorMessage = 'Invalid verification ID';
        break;
      default:
        _errorMessage = e.message ?? 'An authentication error occurred';
    }
    
    _setLoading(false);
    notifyListeners();
    
    if (kDebugMode) {
      print('AuthService Error: ${e.code} - $_errorMessage');
    }
  }

  /// Set Loading State
  /// 
  /// Helper method to update loading state and notify listeners.
  /// This keeps your UI in sync with async operations.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear Error Message
  /// 
  /// Call this when you want to dismiss an error message from the UI.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
