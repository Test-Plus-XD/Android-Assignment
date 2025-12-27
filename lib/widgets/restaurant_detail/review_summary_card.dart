import 'package:flutter/material.dart';
import '../../models.dart';

/// Review Summary Card
///
/// Displays aggregated review statistics for a restaurant including:
/// - Average rating with star visualization
/// - Total review count
/// - Tap to view all reviews
class ReviewSummaryCard extends StatelessWidget {
  final ReviewStats? reviewStats;
  final bool isTraditionalChinese;
  final VoidCallback onTap;

  const ReviewSummaryCard({
    required this.reviewStats,
    required this.isTraditionalChinese,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewStats == null || reviewStats!.totalReviews == 0) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                isTraditionalChinese ? '尚無評論' : 'No reviews yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isTraditionalChinese ? '成為第一個評論的人！' : 'Be the first to review!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final avgRating = reviewStats!.averageRating;
    final totalReviews = reviewStats!.totalReviews;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Rating Circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getRatingColor(avgRating).withOpacity(0.1),
                  border: Border.all(
                    color: _getRatingColor(avgRating),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    avgRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(avgRating),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Rating Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stars
                    Row(
                      children: List.generate(5, (index) {
                        if (index < avgRating.floor()) {
                          return Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 24,
                          );
                        } else if (index < avgRating) {
                          return Icon(
                            Icons.star_half,
                            color: Colors.amber,
                            size: 24,
                          );
                        } else {
                          return Icon(
                            Icons.star_border,
                            color: Colors.grey,
                            size: 24,
                          );
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    // Review Count
                    Text(
                      isTraditionalChinese
                          ? '$totalReviews 則評論'
                          : '$totalReviews review${totalReviews != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    // Tap to view
                    Row(
                      children: [
                        Text(
                          isTraditionalChinese ? '查看所有評論' : 'View all reviews',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.blue;
    if (rating >= 2.5) return Colors.orange;
    return Colors.red;
  }
}
