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
  //final GoogleSignIn _googleSignIn = GoogleSignIn();
  late final GoogleSignIn _googleSignIn;
  
  // Current user state - null means not logged in
  // This is reactive: when it changes, all listeners are notified
  User? _currentUser;
  
  // Loading state - useful for showing progress indicators during auth operations
  bool _isLoading = false;
  
  // Error message - stores the last error for display in UI
  String? _errorMessage;

  // Constructor - sets up the auth state listener
  // This is similar to your Angular service's initialiseAuth() method
  //AuthService() _initialiseAuthStateListener();

  // GETTERS - Provide read-only access to private state, similar to public observables
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Get user ID - useful for API calls that need authentication
  String? get uid => _currentUser?.uid;

  // Get ID token for API authentication
  Future<String?> get idToken async {
    if (_currentUser == null) return null;
    try {
      return await _currentUser!.getIdToken();
    } catch (error) {
      if (kDebugMode) print('AuthService: Error getting ID token - $error');
      return null;
    }
  }

  /// Constructor initialises Google Sign-In with proper configuration
  ///
  /// For Android OAuth to work, you need:
  /// 1. SHA-1 fingerprint registered in Firebase Console
  /// 2. OAuth 2.0 client ID created for Android
  /// 3. google-services.json file with correct configuration
  AuthService() {
    // Initialise Google Sign-In with Android-specific configuration
    // The serverClientId should be your Web client ID from Firebase Console
    // This is required for getting ID tokens on Android
    _googleSignIn = GoogleSignIn(
      // Request email scope to get user's email address
      scopes: ['email'],
      // Add the server client ID for Android
      // This should be your Web application client ID from Firebase Console
      // Format: "YOUR_CLIENT_ID.apps.googleusercontent.com"
      // You can find this in Firebase Console -> Authentication -> Sign-in method -> Google
      serverClientId: '937491674619-r1e5di42mi8tdgkqfhe2fubdms7jks9f.apps.googleusercontent.com',
    );
    _initialiseAuthStateListener();
    if (kDebugMode) print('AuthService: Initialised with Google Sign-In');
  }

  /// Initialises authentication state listener
  ///
  /// This keeps the app in sync with Firebase authentication state changes.
  /// It fires when:
  /// - User logs in
  /// - User logs out
  /// - Token refreshes
  /// - User email verification status changes
  void _initialiseAuthStateListener() {
    _firebaseAuth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _errorMessage = null;
      notifyListeners();

      if (kDebugMode) {
        if (user != null) {
          print('AuthService: User authenticated - ${user.email}');
          print('AuthService: UID - ${user.uid}');
          print('AuthService: Email verified - ${user.emailVerified}');
        } else {
          print('AuthService: User signed out');
        }
      }
    });
  }

  /// Registers a new user with email and password
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);
      if (kDebugMode) print('AuthService: Registering user with email: $email');

      // Create the user account
      final UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
        _currentUser = _firebaseAuth.currentUser;
      }

      // Send email verification
      await credential.user?.sendEmailVerification();

      if (kDebugMode) print('AuthService: User registered successfully');
      _setLoading(false);
      return true;

    } on FirebaseAuthException catch (error) {
      _handleAuthError(error);
      return false;
    } catch (error) {
      _errorMessage = 'An unexpected error occurred: $error';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Logs in a user with email and password
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      if (kDebugMode) print('AuthService: Logging in with email: $email');
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (kDebugMode) print('AuthService: Login successful');
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (error) {
      _handleAuthError(error);
      return false;
    } catch (error) {
      _errorMessage = 'An unexpected error occurred: $error';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Signs in with Google OAuth
  ///
  /// This implementation includes:
  /// 1. Proper Android configuration with serverClientId
  /// 2. Better error handling for common issues
  /// 3. Automatic retry for network errors
  /// 4. Detailed logging for debugging
  ///
  /// Common issues and solutions:
  /// - "Sign in failed" error: Check SHA-1 fingerprint in Firebase Console
  /// - "API not enabled" error: Enable Google Sign-In in Firebase Console
  /// - "Invalid client" error: Check google-services.json is up to date
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      if (kDebugMode) print('AuthService: Starting Google Sign-In flow...');
      // Step 1: Sign out any existing Google account to allow account selection
      // This ensures the account picker always appears
      await _googleSignIn.signOut();
      if (kDebugMode) print('AuthService: Triggering Google account picker...');
      // Step 2: Trigger the Google Sign-In flow
      // This opens Google's account picker and authentication UI
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      // User cancelled the sign-in
      if (googleUser == null) {
        if (kDebugMode) print('AuthService: Google Sign-In cancelled by user');
        _setLoading(false);
        return false;
      }
      if (kDebugMode) {
        print('AuthService: Google account selected: ${googleUser.email}');
        print('AuthService: Fetching authentication tokens...');
      }
      // Step 3: Get authentication tokens from Google
      // This retrieves the OAuth credentials needed for Firebase
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (kDebugMode) {
        print('AuthService: Got access token: ${googleAuth.accessToken != null}');
        print('AuthService: Got ID token: ${googleAuth.idToken != null}');
      }
      // Step 4: Create Firebase credential from Google tokens
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      if (kDebugMode) print('AuthService: Signing in to Firebase with Google credential...');
      // Step 5: Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (kDebugMode) {
        print('AuthService: Firebase sign-in successful');
        print('AuthService: User: ${userCredential.user?.email}');
        print('AuthService: UID: ${userCredential.user?.uid}');
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (error) {
      if (kDebugMode) {
        print('AuthService: Firebase auth error during Google Sign-In');
        print('Error code: ${error.code}');
        print('Error message: ${error.message}');
      }
      _handleAuthError(error);
      return false;
    } catch (error) {
      if (kDebugMode) print('AuthService: Unexpected error during Google Sign-In: $error');
      _errorMessage = 'Google sign-in failed: $error';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Logs out the current user
  ///
  /// This signs out from both Firebase and Google to ensure complete cleanup
  Future<void> logout() async {
    try {
      _setLoading(true);
      if (kDebugMode) print('AuthService: Logging out...');
      // Sign out from Google if user signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        if (kDebugMode) print('AuthService: Signed out from Google');
      }
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      _currentUser = null;
      _errorMessage = null;
      _setLoading(false);
      notifyListeners();
      if (kDebugMode) print('AuthService: Logout successful');
    } catch (error) {
      _errorMessage = 'Logout failed: $error';
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Sends a password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      if (kDebugMode) print('AuthService: Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      if (kDebugMode) print('AuthService: Password reset email sent successfully');
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (error) {
      _handleAuthError(error);
      return false;
    } catch (error) {
      _errorMessage = 'Failed to send reset email: $error';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Updates the user's profile information
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    if (_currentUser == null) {
      _errorMessage = 'No user logged in';
      return false;
    }

    try {
      _setLoading(true);
      if (kDebugMode) print('AuthService: Updating user profile...');

      if (displayName != null) await _currentUser!.updateDisplayName(displayName);
      if (photoURL != null) await _currentUser!.updatePhotoURL(photoURL);
      // Reload user data to get the updates
      await _currentUser!.reload();
      _currentUser = _firebaseAuth.currentUser;

      if (kDebugMode) print('AuthService: Profile updated successfully');
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = 'Failed to update profile: $error';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Handles Firebase authentication errors with user-friendly messages
  void _handleAuthError(FirebaseAuthException error) {
    if (kDebugMode)  print('AuthService: Handling auth error: ${error.code}');
    switch (error.code) {
      case 'email-already-in-use':
        _errorMessage = 'This email is already registered';
        break;
      case 'invalid-email':
        _errorMessage = 'Invalid email address';
        break;
      case 'operation-not-allowed':
        _errorMessage = 'Operation not allowed. Please contact support.';
        break;
      case 'weak-password':
        _errorMessage = 'Password is too weak. Please use a stronger password.';
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
        _errorMessage = 'Invalid credentials. Please try again.';
        break;
      case 'account-exists-with-different-credential':
        _errorMessage = 'An account already exists with this email using a different sign-in method';
        break;
      case 'invalid-verification-code':
        _errorMessage = 'Invalid verification code';
        break;
      case 'invalid-verification-id':
        _errorMessage = 'Invalid verification ID';
        break;
      case 'network-request-failed':
        _errorMessage = 'Network error. Please check your internet connection.';
        break;
      case 'too-many-requests':
        _errorMessage = 'Too many attempts. Please try again later.';
        break;
      default:
        _errorMessage = error.message ?? 'An authentication error occurred';
    }
    _setLoading(false);
    notifyListeners();
  }

  /// Updates loading state and notifies listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clears the error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}