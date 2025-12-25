import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../models.dart';
import '../widgets/reviews/review_stats.dart';
import '../widgets/reviews/review_list.dart';
import '../widgets/reviews/review_form.dart';

/// Reviews Page
///
/// Full-screen page for viewing and managing restaurant reviews.
/// Displays review statistics at the top and a scrollable list of reviews.
/// Authenticated users can write new reviews via the floating action button.
class RestaurantReviewsPage extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final bool isTraditionalChinese;

  const RestaurantReviewsPage({
    required this.restaurantId,
    required this.restaurantName,
    required this.isTraditionalChinese,
    super.key,
  });

  /// Show add review form
  ///
  /// Opens a bottom sheet with the review form for authenticated users.
  /// Unauthenticated users are prompted to sign in.
  Future<void> _showAddReviewForm(BuildContext context) async {
    final authService = context.read<AuthService>();
    final reviewService = context.read<ReviewService>();

    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTraditionalChinese ? '請先登入以撰寫評價' : 'Please sign in to write a review',
          ),
          action: SnackBarAction(
            label: isTraditionalChinese ? '登入' : 'Sign In',
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ),
      );
      return;
    }

    await showReviewForm(
      context: context,
      restaurantId: restaurantId,
      isTraditionalChinese: isTraditionalChinese,
      onSubmit: (rating, comment, imageUrl) async {
        final request = CreateReviewRequest(
          restaurantId: restaurantId,
          rating: rating,
          comment: comment,
          imageUrl: imageUrl,
          dateTime: DateTime.now().toIso8601String(),
        );

        final reviewId = await reviewService.createReview(request);

        if (context.mounted) {
          if (reviewId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isTraditionalChinese ? '評價已提交' : 'Review submitted successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh stats
            await reviewService.getReviewStats(restaurantId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${isTraditionalChinese ? '提交失敗' : 'Failed to submit review'}: ${reviewService.error}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTraditionalChinese ? '評價' : 'Reviews',
        ),
      ),
      body: Column(
        children: [
          // Review stats at the top
          Consumer<ReviewService>(
            builder: (context, reviewService, child) {
              return FutureBuilder(
                future: reviewService.getReviewStats(restaurantId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return ReviewStatsWidget(stats: snapshot.data!);
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
          const Divider(),
          // Reviews list
          Expanded(
            child: ReviewList(restaurantId: restaurantId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReviewForm(context),
        icon: const Icon(Icons.rate_review),
        label: Text(
          isTraditionalChinese ? '撰寫評價' : 'Write Review',
        ),
      ),
    );
  }
}
