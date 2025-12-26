import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config.dart';
import '../models.dart';

/// User Service
class UserService with ChangeNotifier {
  final String _apiUrl = AppConfig.getEndpoint('API/Users');
  AuthService _authService;
  User? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastFetchedUid; // Track which UID we last fetched to avoid redundant calls

  UserService(this._authService) {
    _authService.addListener(_onAuthChanged);
  }

  User? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Update the AuthService dependency without recreating the service instance
  void updateAuth(AuthService authService) {
    if (_authService != authService) {
      _authService.removeListener(_onAuthChanged);
      _authService = authService;
      _authService.addListener(_onAuthChanged);
      // Trigger a check in case auth state changed during the transition
      _onAuthChanged();
    }
  }

  void _onAuthChanged() {
    if (_authService.isLoggedIn && _authService.uid != null) {
      // Skip if we already fetched this user's profile
      if (_lastFetchedUid == _authService.uid) {
        return;
      }

      // Use microtask to ensure this doesn't block the UI/Build cycle
      Future.microtask(() async {
        final uid = _authService.uid;
        if (uid == null) return;

        final profile = await getUserProfile(uid);
        if (profile == null && _authService.currentUser != null) {
          final newProfile = User(
            uid: uid,
            email: _authService.currentUser!.email,
            displayName: _authService.currentUser!.displayName,
            photoURL: _authService.currentUser!.photoURL,
            emailVerified: _authService.currentUser!.emailVerified,
            phoneNumber: _authService.currentUser!.phoneNumber,
            createdAt: DateTime.now(),
          );
          await createUserProfile(newProfile);
        }
        _lastFetchedUid = uid;
      });
    } else {
      _currentProfile = null;
      _lastFetchedUid = null;
      notifyListeners();
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.idToken;
    return {
      'Content-Type': 'application/json',
      'X-API-Passcode': AppConfig.apiPasscode,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> createUserProfile(User profile) async {
    try {
      _setLoading(true);
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse(_apiUrl), headers: headers, body: jsonEncode(profile.toJson()));
      if (response.statusCode == 201) {
        _currentProfile = profile;
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = '$e';
      _setLoading(false);
      return false;
    }
  }

  Future<User?> getUserProfile(String uid) async {
    try {
      _setLoading(true);
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_apiUrl/$uid'), headers: headers);
      if (response.statusCode == 200) {
        _currentProfile = User.fromJson(jsonDecode(response.body));
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return _currentProfile;
      }
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      final headers = await _getHeaders();
      final response = await http.put(Uri.parse('$_apiUrl/$uid'), headers: headers, body: jsonEncode(updates));
      if (response.statusCode == 204) {
        await getUserProfile(uid);
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateLoginMetadata(String uid) async {
    final currentCount = _currentProfile?.loginCount ?? 0;
    return await updateUserProfile(uid, {
      'lastLoginAt': DateTime.now().toIso8601String(),
      'loginCount': currentCount + 1,
    });
  }

  Future<bool> updatePreferences(String uid, Map<String, dynamic> preferences) async {
    final currentPrefs = _currentProfile?.preferences ?? {};
    final mergedPrefs = {...currentPrefs, ...preferences};
    return await updateUserProfile(uid, {'preferences': mergedPrefs});
  }

  Future<bool> deleteUserProfile(String uid) async {
    try {
      _setLoading(true);
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$_apiUrl/$uid'), headers: headers);
      if (response.statusCode == 204) {
        _currentProfile = null;
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> profileExists(String uid) async {
    final profile = await getUserProfile(uid);
    return profile != null;
  }

  void clearCache() {
    _currentProfile = null;
    _errorMessage = null;
    notifyListeners();
  }

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
