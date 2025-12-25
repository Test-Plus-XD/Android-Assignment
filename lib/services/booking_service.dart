import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config.dart';
import '../models.dart';

/// Booking Service
/// 
/// Manages restaurant table bookings through your Node.js API.
class BookingService with ChangeNotifier {
  // API endpoint for bookings
  final String _apiUrl = AppConfig.getEndpoint('API/Bookings');
  // Reference to AuthService for authentication tokens
  AuthService _authService;
  // Current user's bookings
  List<Booking> _userBookings = [];
  // Loading state
  bool _isLoading = false;
  // Error message
  String? _errorMessage;

  // GETTERS
  List<Booking> get userBookings => _userBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BookingService(this._authService);

  /// Update the AuthService dependency without recreating the service instance
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

  /// Get HTTP headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.idToken;
    return {
      'Content-Type': 'application/json',
      'X-API-Passcode': AppConfig.apiPasscode,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Create a new booking
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

      // Prepare booking data
      final bookingData = {
        'userId': _authService.currentUser!.uid,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'dateTime': dateTime.toIso8601String(),
        'numberOfGuests': numberOfGuests,
        'status': 'pending',
        'paymentStatus': 'unpaid',
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

  /// Get all bookings for current user
  Future<List<Booking>> getUserBookings() async {
    try {
      _setLoading(true);

      if (_authService.currentUser == null) {
        _errorMessage = 'You must be logged in to view bookings';
        _setLoading(false);
        notifyListeners();
        return [];
      }

      final userId = _authService.currentUser!.uid;
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_apiUrl?userId=$userId'), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookings = (data['data'] as List<dynamic>)
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();

        bookings.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        _userBookings = bookings;
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

  /// Get single booking by ID
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

  /// Update booking status
  Future<bool> updateBooking(
    String bookingId, {
    String? status,
    String? paymentStatus,
    String? paymentIntentId,
  }) async {
    try {
      _setLoading(true);

      final updates = <String, dynamic>{};
      if (status != null) updates['status'] = status;
      if (paymentStatus != null) updates['paymentStatus'] = paymentStatus;
      if (paymentIntentId != null) updates['paymentIntentId'] = paymentIntentId;

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
        final index = _userBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          final updated = await getBookingById(bookingId);
          if (updated != null) _userBookings[index] = updated;
        }
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

  Future<bool> cancelBooking(String bookingId) async {
    return await updateBooking(bookingId, status: 'cancelled');
  }

  Future<bool> completeBooking(String bookingId) async {
    return await updateBooking(bookingId, status: 'completed');
  }

  void clearCache() {
    _userBookings = [];
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
