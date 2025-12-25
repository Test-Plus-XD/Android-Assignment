import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Booking model
///
/// Represents a restaurant table reservation with status tracking and payment information
class Booking {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final DateTime dateTime;
  final int numberOfGuests;
  final String status; // pending/confirmed/completed/cancelled
  final String paymentStatus; // unpaid/paid/refunded
  final String? paymentIntentId; // Stripe payment ID for tracking and refunds
  final String? specialRequests;
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
    required this.paymentStatus,
    this.paymentIntentId,
    this.specialRequests,
    this.createdAt,
    this.modifiedAt,
  });

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
      paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
      paymentIntentId: json['paymentIntentId'] as String?,
      specialRequests: json['specialRequests'] as String?,
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
      'paymentStatus': paymentStatus,
      if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
      if (specialRequests != null) 'specialRequests': specialRequests,
    };
  }
}
