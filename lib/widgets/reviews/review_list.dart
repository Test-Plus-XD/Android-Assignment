import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';
import '../../config/app_state.dart';
import 'review_card.dart';
import 'review_form.dart';

/// Review List Widget
///
/// Displays a list of reviews with pull-to-refresh and empty state.
/// Supports edit/delete for user's own reviews.
class ReviewList extends StatefulWidget {
  final String restaurantId;

  const ReviewList({
    super.key,
    required this.restaurantId,
  });

  @override
  State<ReviewList> createState() => _ReviewListState();
}

class _ReviewListState extends State<ReviewList> {
  @override
  void initState() {
    super.initState();
    // Load reviews on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  Future<void> _loadReviews() async {
    final reviewService = context.read<ReviewService>();
    await reviewService.getReviews(restaurantId: widget.restaurantId);
  }

  Future<void> _handleEdit(Review review) async {
    final reviewService = context.read<ReviewService>();
    final isTC = context.read<AppState>().isTraditionalChinese;

    await showReviewForm(
      context: context,
      restaurantId: widget.restaurantId,
      existingReview: review,
      isTraditionalChinese: isTC,
      onSubmit: (rating, comment, imageUrl) async {
        final request = UpdateReviewRequest(
          rating: rating,
          comment: comment,
          imageUrl: imageUrl,
        );

        final success = await reviewService.updateReview(review.id, request);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isTC ? '評價已更新' : 'Review updated successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${isTC ? '更新失敗' : 'Failed to update review'}: ${reviewService.error}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _handleDelete(Review review) async {
    final isTC = context.read<AppState>().isTraditionalChinese;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTC ? '刪除評價' : 'Delete Review'),
        content: Text(isTC ? '您確定要刪除此評價嗎？' : 'Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isTC ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(isTC ? '刪除' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reviewService = context.read<ReviewService>();
      final success = await reviewService.deleteReview(review.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTC ? '評價已刪除' : 'Review deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isTC ? '刪除失敗' : 'Failed to delete review'}: ${reviewService.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isTC = appState.isTraditionalChinese;

    return Consumer2<ReviewService, AuthService>(
      builder: (context, reviewService, authService, child) {
        if (reviewService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (reviewService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  '${isTC ? '錯誤' : 'Error'}: ${reviewService.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadReviews,
                  child: Text(isTC ? '重試' : 'Retry'),
                ),
              ],
            ),
          );
        }

        if (reviewService.reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  isTC ? '暫無評價' : 'No reviews yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  isTC ? '成為第一個評價的人！' : 'Be the first to write a review!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadReviews,
          child: ListView.builder(
            itemCount: reviewService.reviews.length,
            itemBuilder: (context, index) {
              final review = reviewService.reviews[index];
              final isOwnReview = authService.uid == review.userId;

              return ReviewCard(
                review: review,
                isOwnReview: isOwnReview,
                onEdit: () => _handleEdit(review),
                onDelete: () => _handleDelete(review),
              );
            },
          ),
        );
      },
    );
  }
}
