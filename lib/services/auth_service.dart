import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Authentication Service
/// 
/// This service acts as the central hub for all user identity management.
/// It provides a unified interface for:
/// - Firebase Email/Password Authentication (Sign up, Login, Reset, Profile)
/// - Google OAuth 2.0 Integration (compatible with google_sign_in 7.x)
/// - Global Authentication State (Current User, Loading Status, Errors)
/// 
/// It extends [ChangeNotifier], allowing UI components to automatically rebuild
/// whenever the authentication state changes.
class AuthService with ChangeNotifier {
  // --- Private Instances ---
  
  /// The Firebase Auth instance used for backend communication with Firebase.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  /// The Google Sign-In instance. 
  /// Note: From version 7.0.0 onwards, this is a singleton accessed via [GoogleSignIn.instance].
  /// It requires an explicit [initialize] call before any sign-in attempts.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  // --- State Variables ---
  
  /// The currently authenticated [User] from Firebase. 
  /// This is null if the user is signed out or if the app is still determining auth state.
  User? _currentUser;
  
  /// A boolean flag used to show/hide loading spinners in the UI.
  bool _isLoading = false;
  
  /// Holds the last error message encountered. This can be used to display
  /// SnackBars or Alert dialogs to the user.
  String? _errorMessage;

  // --- Getters ---
  
  /// Returns the current [User] object.
  User? get currentUser => _currentUser;
  
  /// Returns [true] if a session exists, [false] otherwise.
  bool get isLoggedIn => _currentUser != null;
  
  /// Returns the current loading status.
  bool get isLoading => _isLoading;
  
  /// Returns the descriptive error message if an operation failed.
  String? get errorMessage => _errorMessage;
  
  /// Returns the unique ID (UID) of the user, used as a key in databases like Firestore.
  String? get uid => _currentUser?.uid;

  /// Returns the Firebase ID Token for the current user.
  /// This token is often required for making authorized calls to custom backend APIs.
  /// Used by: booking_service, user_service, review_service.
  Future<String?> get idToken async => await _currentUser?.getIdToken();

  /// Returns the Firebase ID Token for the current user, optionally forcing a refresh.
  /// A force refresh is useful if the user's permissions or custom claims have changed.
  /// Used by: chat_service, docupipe_service, menu_service, store_service.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await _currentUser?.getIdToken(forceRefresh);
  }

  /// Constructor: Bootstraps the service.
  /// 1. Connects to Firebase's auth state listener.
  /// 2. Initialises Google Sign-In settings.
  AuthService() {
    _initialiseAuthStateListener();
    _initializeGoogleSignIn();
  }

  /// Initialises Google Sign-In with the required configuration.
  /// 
  /// In version 7.x, the [serverClientId] must be provided here to allow
  /// Firebase to exchange the resulting authorization for a Firebase Credential.
  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: '937491674619-r1e5di42mi8tdgkqfhe2fubdms7jks9f.apps.googleusercontent.com',
      );
      if (kDebugMode) print('AuthService: Google Sign-In initialised successfully.');
    } catch (e) {
      if (kDebugMode) print('AuthService: Failed to initialise Google Sign-In: $e');
    }
  }

  /// Establishes a permanent stream listener for Firebase Auth.
  /// 
  /// Every time a user signs in, logs out, or their token expires, Firebase
  /// broadcasts an event. We catch it here to update [_currentUser] and
  /// trigger UI updates via [notifyListeners].
  void _initialiseAuthStateListener() {
    _firebaseAuth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _errorMessage = null; // Reset errors on state change
      notifyListeners();

      if (kDebugMode) {
        if (user != null) {
          print('AuthService: User Session Active -> ${user.email}');
        } else {
          print('AuthService: User Session Terminated.');
        }
      }
    });
  }

  /// Signs in the user using the Google OAuth 2.0 flow.
  /// 
  /// THE FULL FLOW (v7.x):
  /// 1. [Sign Out]: Clear any existing Google session to ensure account picker appears.
  /// 2. [Authenticate]: Launch the native Google Account Picker via [_googleSignIn.authenticate()].
  /// 3. [ID Token]: Extract the 'idToken' from the resulting [googleUser.authentication].
  /// 4. [Access Token]: Request an OAuth 'accessToken' via [googleUser.authorizationClient.authorizeScopes].
  /// 5. [Credential]: Combine tokens into an [OAuthCredential] for Firebase.
  /// 6. [Firebase Sign In]: Hand over the credential to Firebase Auth to complete the bridge.
  /// 
  /// Returns [true] if the user successfully signed in.
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      if (kDebugMode) print('AuthService: Initiating Google Sign-In flow...');
      
      // Step 1: Sign out to force the account selector
      await _googleSignIn.signOut();
      
      // Step 2: Trigger native account selection/authentication
      final GoogleSignInAccount googleUser;
      try {
        googleUser = await _googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        // Handle case where user taps 'back' or 'cancel'
        if (e.code == GoogleSignInExceptionCode.canceled) {
          if (kDebugMode) print('AuthService: User cancelled Google selection.');
          _setLoading(false);
          return false;
        }
        rethrow;
      }

      if (kDebugMode) print('AuthService: User selected account -> ${googleUser.email}');
      
      // Step 3 & 4: Retrieve tokens from the account
      // Note: 'authentication' is a synchronous getter in 7.x
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      // Access tokens must be requested explicitly via the authorizationClient
      final GoogleSignInClientAuthorization clientAuth = 
          await googleUser.authorizationClient.authorizeScopes(['email']);
      
      // Step 5: Create the Firebase credential package
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Step 6: Authenticate with Firebase
      await _firebaseAuth.signInWithCredential(credential);
      
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (error) {
      _handleAuthError(error);
      return false;
    } catch (error) {
      if (kDebugMode) print('AuthService: Unhandled error in Google flow -> $error');
      _errorMessage = 'Google sign-in failed: $error';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Creates a new user account using Email and Password.
  /// 
  /// - Sends a verification email automatically.
  /// - Updates the [displayName] if provided.
  /// - Triggers a [reload] to ensure the local user object has the updated name.
  Future<bool> registerWithEmail({
    required String email, 
    required String password, 
    String? displayName
  }) async {
    try {
      _setLoading(true);
      
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
        _currentUser = _firebaseAuth.currentUser;
      }
      
      await credential.user?.sendEmailVerification();
      
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (error) {
      _handleAuthError(error);
      return false;
    } catch (error) {
      _errorMessage = 'Registration failed: $error';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Standard Email/Password Login.
  Future<bool> loginWithEmail({required String email, required String password}) async {
    try {
      _setLoading(true);
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (error) {
      _handleAuthError(error);
      return false;
    } catch (error) {
      _errorMessage = 'Login failed: $error';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Fully terminates the session.
  /// 
  /// Clears both the Google Sign-In instance cache and the Firebase Auth session.
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      
      _currentUser = null;
      _errorMessage = null;
      _setLoading(false);
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Logout error: $error';
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Triggers Firebase's built-in password reset flow.
  /// 
  /// User will receive an email from Firebase with a link to reset their password.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (error) {
      _handleAuthError(error);
      return false;
    } catch (error) {
      _errorMessage = 'Reset email failed: $error';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Updates the metadata (Name/Photo) for the currently logged-in user.
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    if (_currentUser == null) return false;
    try {
      _setLoading(true);
      if (displayName != null) await _currentUser!.updateDisplayName(displayName);
      if (photoURL != null) await _currentUser!.updatePhotoURL(photoURL);
      
      await _currentUser!.reload();
      _currentUser = _firebaseAuth.currentUser;
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = 'Profile update failed: $error';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // --- Helper Methods ---

  /// Internal handler to translate Firebase error codes into readable messages.
  void _handleAuthError(FirebaseAuthException error) {
    _errorMessage = error.message ?? 'An unexpected authentication error occurred.';
    _setLoading(false);
    notifyListeners();
  }

  /// Centralised method to update the loading state.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Manual error clearing for use when navigating away from login/signup screens.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
