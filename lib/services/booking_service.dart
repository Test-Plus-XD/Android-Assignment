import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config.dart';
import '../models.dart';

/// Booking Service
/// 
/// Manages restaurant table bookings through your Node.js API.
/// This service coordinates with:
/// - Your Node.js API (for Firestore operations)
/// - AuthService (for user authentication)
/// - Stripe (for payment processing, through separate service)
/// 
/// Why bookings go through your API instead of directly to Firestore:
/// 1. Security: Your API validates that users can only book for themselves
/// 2. Business logic: Your API can check restaurant capacity, validate times
/// 3. Consistency: Same booking logic for both Angular and Flutter apps
/// 4. Audit trail: Server-side logging of all booking operations
class BookingService with ChangeNotifier {
  // API endpoint for bookings
  final String _apiUrl = AppConfig.getEndpoint('API/Bookings');
  // Reference to AuthService for authentication tokens
  final AuthService _authService;
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
  /// 
  /// This method creates a booking reservation in Firestore.
  /// The booking starts with status='pending' and paymentStatus='unpaid'.
  /// After payment is completed, these statuses will be updated.
  /// 
  /// Process flow:
  /// 1. User selects date/time and number of guests
  /// 2. This method creates the booking record (pending/unpaid)
  /// 3. Payment screen shows with booking ID
  /// 4. After payment, booking is updated to confirmed/paid
  /// 
  /// Why create booking before payment:
  /// - Reserve the time slot immediately
  /// - Allow payment to reference the booking
  /// - Enable abandoned booking cleanup (cancel unpaid bookings after timeout)
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
        // Booking created successfully
        final data = jsonDecode(response.body);
        final bookingId = data['id'] as String;
        if (kDebugMode) print('BookingService: Booking created with ID: $bookingId');
        // Fetch the complete booking record
        final booking = await getBookingById(bookingId);
        // Add to local cache
        if (booking != null) _userBookings.insert(0, booking);
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return booking;
      } else {
        // Handle error response
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
  /// 
  /// Fetches all bookings belonging to the authenticated user.
  /// Results are sorted by date (newest first) for display in booking history.
  Future<List<Booking>> getUserBookings() async {
    try {
      _setLoading(true);

      // Validate authentication
      if (_authService.currentUser == null) {
        _errorMessage = 'You must be logged in to view bookings';
        _setLoading(false);
        notifyListeners();
        return [];
      }

      final userId = _authService.currentUser!.uid;
      final headers = await _getHeaders();
      // Call API with user ID filter
      final response = await http.get(Uri.parse('$_apiUrl?userId=$userId'), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookings = (data['data'] as List<dynamic>)
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort by date descending (newest first)
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

  /// Update booking status and payment information
  /// 
  /// Called after payment is completed to mark booking as confirmed and paid.
  /// Also used to cancel bookings or mark them as completed after the meal.
  /// 
  /// Status lifecycle:
  /// pending -> confirmed (after payment) -> completed (after dining) or cancelled
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
        // Update local cache
        final index = _userBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          // Reload the updated booking
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

  /// Cancel a booking
  /// 
  /// Marks booking as cancelled. In a real system, you'd also:
  /// - Process refund through Stripe (if paid)
  /// - Send cancellation notification email
  /// - Release the time slot for other customers
  Future<bool> cancelBooking(String bookingId) async {
    return await updateBooking(bookingId, status: 'cancelled');
  }

  /// Complete a booking
  /// 
  /// Called after customer has dined. This closes the booking lifecycle.
  /// You might trigger this automatically after the booking time has passed.
  Future<bool> completeBooking(String bookingId) async {
    return await updateBooking(bookingId, status: 'completed');
  }

  /// Clear cached bookings
  void clearCache() {
    _userBookings = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}