import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';

/// User Profile Model
/// 
/// This matches your Firestore user schema and TypeScript UserProfile interface.
/// In Flutter, we use classes instead of interfaces, but the concept is identical.
class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final String? phoneNumber;
  final String? type;
  final String? bio;
  final Map<String, dynamic>? preferences;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final DateTime? lastLoginAt;
  final int? loginCount;

  UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.emailVerified,
    this.phoneNumber,
    this.type,
    this.bio,
    this.preferences,
    this.createdAt,
    this.modifiedAt,
    this.lastLoginAt,
    this.loginCount,
  });

  /// Create UserProfile from JSON
  /// 
  /// This converts the JSON response from your API into a Dart object.
  /// Your API returns user data in this format from Firestore.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneNumber: json['phoneNumber'] as String?,
      type: json['type'] as String?,
      bio: json['bio'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      loginCount: json['loginCount'] as int?,
    );
  }

  /// Convert UserProfile to JSON
  /// 
  /// This prepares the user data to send to your API.
  /// We exclude certain fields that shouldn't be sent (like uid, createdAt).
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (type != null) 'type': type,
      if (bio != null) 'bio': bio,
      if (preferences != null) 'preferences': preferences,
    };
  }
}

/// User Service - Flutter Implementation
/// 
/// This service communicates with your Node.js API to manage user profiles.
/// It mirrors your Angular UserService but uses Flutter's HTTP package.
/// 
/// Architecture:
/// - AuthService handles authentication (login/logout)
/// - UserService handles user profile data (CRUD operations)
/// - They work together: AuthService provides the ID token, UserService uses it for API calls
class UserService with ChangeNotifier {
  // Your Node.js API endpoint from AppConfig
  final String _apiUrl = AppConfig.getEndpoint('API/Users');
  
  // Reference to AuthService to get authentication tokens
  final AuthService _authService;
  
  // Cached user profile - reduces API calls
  UserProfile? _currentProfile;
  
  // Loading state for profile operations
  bool _isLoading = false;
  
  // Error message for UI display
  String? _errorMessage;

  // Constructor requires AuthService dependency
  UserService(this._authService) {
    // Listen to auth state changes
    // When user logs in/out, we need to update profile state
    _authService.addListener(_onAuthChanged);
  }

  // GETTERS
  UserProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Handle Authentication State Changes
  /// 
  /// When auth state changes, we need to:
  /// - Load profile if user logged in
  /// - Clear profile if user logged out
  void _onAuthChanged() {
    if (_authService.isLoggedIn && _authService.uid != null) {
      // User just logged in, load their profile
      getUserProfile(_authService.uid!);
    } else {
      // User logged out, clear profile
      _currentProfile = null;
      notifyListeners();
    }
  }

  /// Get HTTP Headers with Authentication
  /// 
  /// Your API.js expects an Authorization header with Bearer token.
  /// This is the same pattern your Angular service uses.
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.idToken;
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Create User Profile
  /// 
  /// Calls POST /API/Users endpoint to create a new user profile in Firestore.
  /// Your API.js authenticate middleware verifies the token and checks ownership.
  /// 
  /// This matches your Angular service's createUserProfile() method.
  Future<bool> createUserProfile(UserProfile profile) async {
    try {
      _setLoading(true);
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: jsonEncode(profile.toJson()),
      );
      
      if (response.statusCode == 201) {
        // Profile created successfully
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print('UserService: Profile created with ID: ${data['id']}');
        }
        
        // Load the newly created profile
        await getUserProfile(profile.uid);
        
        _setLoading(false);
        return true;
      } else if (response.statusCode == 409) {
        // Profile already exists - this is okay, just load it
        if (kDebugMode) {
          print('UserService: Profile already exists, loading...');
        }
        await getUserProfile(profile.uid);
        _setLoading(false);
        return true;
      } else {
        // Error creating profile
        final error = jsonDecode(response.body);
        _errorMessage = error['error'] ?? 'Failed to create profile';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create profile: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Get User Profile
  /// 
  /// Calls GET /API/Users/:uid to fetch a user profile from Firestore.
  /// Caches the result to reduce API calls.
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      _setLoading(true);
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_apiUrl/$uid'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentProfile = UserProfile.fromJson(data);
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return _currentProfile;
      } else if (response.statusCode == 404) {
        // Profile doesn't exist - this is normal for new users
        if (kDebugMode) {
          print('UserService: Profile not found for uid: $uid');
        }
        _currentProfile = null;
        _setLoading(false);
        notifyListeners();
        return null;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['error'] ?? 'Failed to load profile';
        _setLoading(false);
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  /// Update User Profile
  /// 
  /// Calls PUT /API/Users/:uid to update profile fields.
  /// Your API.js verifies ownership before allowing updates.
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_apiUrl/$uid'),
        headers: headers,
        body: jsonEncode(updates),
      );
      
      if (response.statusCode == 204) {
        // Update successful, refresh cached profile
        await getUserProfile(uid);
        _setLoading(false);
        return true;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['error'] ?? 'Failed to update profile';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Update Login Metadata
  /// 
  /// Called after successful login to track last login time and count.
  /// This helps you understand user engagement.
  Future<bool> updateLoginMetadata(String uid) async {
    final currentCount = _currentProfile?.loginCount ?? 0;
    return await updateUserProfile(uid, {
      'lastLoginAt': DateTime.now().toIso8601String(),
      'loginCount': currentCount + 1,
    });
  }

  /// Update User Preferences
  /// 
  /// Updates just the preferences object (language, theme, notifications).
  /// This is a convenience method for a common operation.
  Future<bool> updatePreferences(String uid, Map<String, dynamic> preferences) async {
    final currentPrefs = _currentProfile?.preferences ?? {};
    final mergedPrefs = {...currentPrefs, ...preferences};
    
    return await updateUserProfile(uid, {
      'preferences': mergedPrefs,
    });
  }

  /// Delete User Profile
  /// 
  /// Calls DELETE /API/Users/:uid to remove the profile from Firestore.
  /// Note: This doesn't delete the Firebase Auth account, only the Firestore document.
  Future<bool> deleteUserProfile(String uid) async {
    try {
      _setLoading(true);
      
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_apiUrl/$uid'),
        headers: headers,
      );
      
      if (response.statusCode == 204) {
        _currentProfile = null;
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['error'] ?? 'Failed to delete profile';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete profile: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Check if Profile Exists
  /// 
  /// Useful for determining if a new user needs a profile created.
  Future<bool> profileExists(String uid) async {
    final profile = await getUserProfile(uid);
    return profile != null;
  }

  /// Clear Cache
  /// 
  /// Clears the cached profile, forcing a fresh load on next access.
  void clearCache() {
    _currentProfile = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear Error Message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set Loading State
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}
