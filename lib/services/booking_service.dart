import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config.dart';
import '../models.dart';
import '../utils/cache_entry.dart';

/// Booking Service
///
/// Manages restaurant table bookings through your Node.js API.
/// Supports creating, reading, updating, and cancelling bookings.
///
/// Booking status lifecycle:
///   pending  → accepted (by restaurant owner)
///   pending  → declined (by restaurant owner, with optional message)
///   pending  → cancelled (by diner)
///   accepted → completed (by restaurant owner)
///
/// Endpoints:
///   GET    /API/Bookings                  — User's bookings (enriched with restaurant)
///   GET    /API/Bookings/restaurant/:id   — Restaurant's bookings (enriched with diner)
///   GET    /API/Bookings/:id              — Single booking by ID
///   POST   /API/Bookings                  — Create new booking
///   PUT    /API/Bookings/:id              — Update booking (status, details)
///   DELETE /API/Bookings/:id              — Delete booking (30+ day old only)
class BookingService with ChangeNotifier {
  // API endpoint for bookings
  final String _apiUrl = AppConfig.getEndpoint('API/Bookings');
  // Reference to AuthService for authentication tokens
  AuthService _authService;
  // Current user's bookings
  List<Booking> _userBookings = [];
  // TTL timestamp for user bookings cache (1h)
  DateTime? _userBookingsCachedAt;
  // UID of the user whose bookings are cached
  String? _userBookingsCachedUid;
  // Loading state
  bool _isLoading = false;
  // Error message
  String? _errorMessage;

  // GETTERS
  List<Booking> get userBookings => _userBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BookingService(this._authService);

  /// Update the AuthService dependency without recreating the service instance.
  /// When auth changes, automatically refreshes bookings for logged-in users
  /// or clears cached data on logout.
  void updateAuth(AuthService authService) {
    if (_authService != authService) {
      _authService = authService;
      // When auth changes, we might want to refresh bookings if logged in
      if (_authService.isLoggedIn) {
        Future.microtask(() => getUserBookings());
      } else {
        clearCache();
      }
    }
  }

  /// Get HTTP headers with authentication.
  /// Includes the API passcode and Firebase ID token (if authenticated).
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.idToken;
    return {
      'Content-Type': 'application/json',
      'X-API-Passcode': AppConfig.apiPasscode,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Create a new booking.
  /// Sends a POST request with booking data (status defaults to 'pending').
  /// Returns the created Booking object on success, null on failure.
  Future<Booking?> createBooking({
    required String restaurantId,
    required String restaurantName,
    required DateTime dateTime,
    required int numberOfGuests,
    String? specialRequests,
  }) async {
    try {
      _setLoading(true);

      // Validate user is logged in
      if (_authService.currentUser == null) {
        _errorMessage = 'You must be logged in to make a booking';
        _setLoading(false);
        notifyListeners();
        return null;
      }

      // Prepare booking data — no payment fields, status starts as 'pending'
      final bookingData = {
        'userId': _authService.currentUser!.uid,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'dateTime': dateTime.toIso8601String(),
        'numberOfGuests': numberOfGuests,
        'status': 'pending',
        if (specialRequests != null && specialRequests.isNotEmpty) 'specialRequests': specialRequests,
      };

      // Send to API
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: jsonEncode(bookingData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final bookingId = data['id'] as String;
        final booking = await getBookingById(bookingId);
        if (booking != null) _userBookings.insert(0, booking);
        // Invalidate TTL so next full fetch reflects server state
        _userBookingsCachedAt = null;
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return booking;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['error'] ?? 'Failed to create booking';
        _setLoading(false);
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error creating booking: $e';
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  /// Get all bookings for current user (1h cache).
  /// Uses GET /API/Bookings — the API auto-filters by the authenticated
  /// user's Firebase token. Returns enriched data with restaurant info.
  Future<List<Booking>> getUserBookings({bool forceRefresh = false}) async {
    // Return cached data if still valid and belongs to the current user
    final currentUid = _authService.currentUser?.uid;
    if (!forceRefresh &&
        _userBookings.isNotEmpty &&
        _userBookingsCachedAt != null &&
        _userBookingsCachedUid == currentUid &&
        DateTime.now().difference(_userBookingsCachedAt!) < CacheTTL.short) {
      return _userBookings;
    }

    try {
      _setLoading(true);

      if (_authService.currentUser == null) {
        _errorMessage = 'You must be logged in to view bookings';
        _setLoading(false);
        notifyListeners();
        return [];
      }

      final headers = await _getHeaders();
      // API auto-filters by auth token — no userId query param needed
      final response = await http.get(Uri.parse(_apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookings = (data['data'] as List<dynamic>)
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort by date descending (most recent first)
        bookings.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        _userBookings = bookings;
        _userBookingsCachedAt = DateTime.now();
        _userBookingsCachedUid = _authService.currentUser?.uid;
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return bookings;
      } else {
        _errorMessage = 'Failed to load bookings';
        _setLoading(false);
        notifyListeners();
        return [];
      }
    } catch (e) {
      _errorMessage = 'Error loading bookings: $e';
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }

  /// Get all bookings for a specific restaurant (for owners).
  /// Uses GET /API/Bookings/restaurant/:restaurantId — returns enriched
  /// data with diner info (displayName, email, phoneNumber).
  Future<List<Booking>> getRestaurantBookings(String restaurantId) async {
    try {
      _setLoading(true);

      final headers = await _getHeaders();
      // New endpoint path: /API/Bookings/restaurant/:restaurantId
      final response = await http.get(
        Uri.parse('$_apiUrl/restaurant/$restaurantId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookings = (data['data'] as List<dynamic>)
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort by date descending (most recent first)
        bookings.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return bookings;
      } else {
        _errorMessage = 'Failed to load restaurant bookings';
        _setLoading(false);
        notifyListeners();
        return [];
      }
    } catch (e) {
      _errorMessage = 'Error loading restaurant bookings: $e';
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }

  /// Get single booking by ID.
  /// Uses GET /API/Bookings/:id — returns full booking details.
  Future<Booking?> getBookingById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_apiUrl/$id'), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('BookingService: Error getting booking - $e');
      return null;
    }
  }

  /// Update booking fields.
  /// Supports updating status, declineMessage, dateTime, numberOfGuests,
  /// and specialRequests. Only sends non-null fields to the API.
  ///
  /// Status transitions enforced by the API:
  ///   pending  → accepted / declined / cancelled
  ///   accepted → completed
  Future<bool> updateBooking(
    String bookingId, {
    String? status,
    String? declineMessage,
    DateTime? dateTime,
    int? numberOfGuests,
    String? specialRequests,
  }) async {
    try {
      _setLoading(true);

      final updates = <String, dynamic>{};
      if (status != null) updates['status'] = status;
      if (declineMessage != null) updates['declineMessage'] = declineMessage;
      if (dateTime != null) updates['dateTime'] = dateTime.toIso8601String();
      if (numberOfGuests != null) updates['numberOfGuests'] = numberOfGuests;
      if (specialRequests != null) updates['specialRequests'] = specialRequests;

      if (updates.isEmpty) {
        _setLoading(false);
        return false;
      }

      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_apiUrl/$bookingId'),
        headers: headers,
        body: jsonEncode(updates),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Refresh the booking in the local cache
        final index = _userBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          final updated = await getBookingById(bookingId);
          if (updated != null) _userBookings[index] = updated;
        }
        // Invalidate TTL so next full list fetch reflects server state
        _userBookingsCachedAt = null;
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update booking';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating booking: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Accept a pending booking (restaurant owner action).
  /// Transitions status: pending → accepted
  Future<bool> acceptBooking(String bookingId) async {
    return await updateBooking(bookingId, status: 'accepted');
  }

  /// Decline a pending booking with an optional message (restaurant owner action).
  /// Transitions status: pending → declined
  Future<bool> declineBooking(String bookingId, {String? message}) async {
    return await updateBooking(bookingId, status: 'declined', declineMessage: message);
  }

  /// Cancel a pending booking (diner action).
  /// Transitions status: pending → cancelled
  Future<bool> cancelBooking(String bookingId) async {
    return await updateBooking(bookingId, status: 'cancelled');
  }

  /// Mark an accepted booking as completed (restaurant owner action).
  /// Transitions status: accepted → completed
  Future<bool> completeBooking(String bookingId) async {
    return await updateBooking(bookingId, status: 'completed');
  }

  /// Delete a booking permanently (only allowed for bookings 30+ days old).
  /// Uses DELETE /API/Bookings/:id
  Future<bool> deleteBooking(String bookingId) async {
    try {
      _setLoading(true);

      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_apiUrl/$bookingId'),
        headers: headers,
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        _userBookings.removeWhere((b) => b.id == bookingId);
        _userBookingsCachedAt = null;
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['error'] ?? 'Failed to delete booking';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting booking: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Clear all cached booking data (called on logout)
  void clearCache() {
    _userBookings = [];
    _userBookingsCachedAt = null;
    _userBookingsCachedUid = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear the current error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Internal helper to set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
