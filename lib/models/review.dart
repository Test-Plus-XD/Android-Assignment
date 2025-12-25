import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Review model (based on API.md Review structure)
///
/// Represents a restaurant review with rating, comment, and user information
class Review {
  final String id;
  final String userId;
  final String userDisplayName;
  final String? userPhotoURL;
  final String restaurantId;
  final double rating; // 1.0 to 5.0
  final String? comment;
  final String? imageUrl;
  final DateTime dateTime;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  Review({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoURL,
    required this.restaurantId,
    required this.rating,
    this.comment,
    this.imageUrl,
    required this.dateTime,
    this.createdAt,
    this.modifiedAt,
  });

  /// Creates Review from JSON (API response)
  factory Review.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return Review(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String? ?? 'Anonymous',
      userPhotoURL: json['userPhotoURL'] as String?,
      restaurantId: json['restaurantId'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      imageUrl: json['imageUrl'] as String?,
      dateTime: parseDateTime(json['dateTime'] ?? json['createdAt']),
      createdAt: json['createdAt'] != null ? parseDateTime(json['createdAt']) : null,
      modifiedAt: json['modifiedAt'] != null ? parseDateTime(json['modifiedAt']) : null,
    );
  }

  /// Converts Review to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userDisplayName': userDisplayName,
      if (userPhotoURL != null) 'userPhotoURL': userPhotoURL,
      'restaurantId': restaurantId,
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  /// Get star count as integer (1-5)
  int get starCount => rating.round();
}

/// Review statistics model (from API.md)
///
/// Aggregate statistics for restaurant reviews
class ReviewStats {
  final String restaurantId;
  final int totalReviews;
  final double averageRating;

  ReviewStats({
    required this.restaurantId,
    required this.totalReviews,
    required this.averageRating,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      restaurantId: json['restaurantId'] as String,
      totalReviews: json['totalReviews'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }
}

/// Create review request model
///
/// Request payload for creating a new review
class CreateReviewRequest {
  final String restaurantId;
  final double rating;
  final String? comment;
  final String? dateTime;

  CreateReviewRequest({
    required this.restaurantId,
    required this.rating,
    this.comment,
    this.dateTime,
    String? imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      if (dateTime != null) 'dateTime': dateTime,
    };
  }
}

/// Update review request model
///
/// Request payload for updating an existing review
class UpdateReviewRequest {
  final double? rating;
  final String? comment;

  UpdateReviewRequest({this.rating, this.comment, String? imageUrl});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (rating != null) data['rating'] = rating;
    if (comment != null) data['comment'] = comment;
    return data;
  }
}
