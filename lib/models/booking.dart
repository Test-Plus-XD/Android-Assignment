import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Booking Diner
///
/// Enriched contact information for the diner who made the booking.
/// Returned by the API when fetching restaurant bookings via
/// GET /API/Bookings/restaurant/:restaurantId — includes the diner's
/// display name, email, and phone number for the restaurant owner.
class BookingDiner {
  final String? displayName;
  final String? email;
  final String? phoneNumber;

  BookingDiner({
    this.displayName,
    this.email,
    this.phoneNumber,
  });

  factory BookingDiner.fromJson(Map<String, dynamic> json) {
    return BookingDiner(
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
}

/// Booking model
///
/// Represents a restaurant table reservation with status tracking.
/// Statuses: pending / accepted / declined / completed / cancelled
///
/// The API returns enriched data depending on the endpoint:
/// - User bookings (GET /API/Bookings): includes `restaurant` object
/// - Restaurant bookings (GET /API/Bookings/restaurant/:id): includes `diner` object
class Booking {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final DateTime dateTime;
  final int numberOfGuests;
  // Status values: pending, accepted, declined, completed, cancelled
  final String status;
  final String? specialRequests;
  // Reason provided by restaurant owner when declining a booking
  final String? declineMessage;
  // Enriched diner info (returned for restaurant bookings endpoint)
  final BookingDiner? diner;
  // Enriched restaurant info (returned for user bookings endpoint)
  final Map<String, dynamic>? restaurant;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.dateTime,
    required this.numberOfGuests,
    required this.status,
    this.specialRequests,
    this.declineMessage,
    this.diner,
    this.restaurant,
    this.createdAt,
    this.modifiedAt,
  });

  /// Getter for party size (alias for numberOfGuests used in some UI components)
  int get partySize => numberOfGuests;

  factory Booking.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return Booking(
      id: json['id'] as String,
      userId: json['userId'] as String,
      restaurantId: json['restaurantId'] as String,
      restaurantName: json['restaurantName'] as String,
      dateTime: parseDateTime(json['dateTime']),
      numberOfGuests: json['numberOfGuests'] as int,
      status: json['status'] as String? ?? 'pending',
      specialRequests: json['specialRequests'] as String?,
      declineMessage: json['declineMessage'] as String?,
      diner: json['diner'] != null
          ? BookingDiner.fromJson(json['diner'] as Map<String, dynamic>)
          : null,
      restaurant: json['restaurant'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null ? parseDateTime(json['createdAt']) : null,
      modifiedAt: json['modifiedAt'] != null ? parseDateTime(json['modifiedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'dateTime': dateTime.toIso8601String(),
      'numberOfGuests': numberOfGuests,
      'status': status,
      if (specialRequests != null) 'specialRequests': specialRequests,
      if (declineMessage != null) 'declineMessage': declineMessage,
    };
  }
}
