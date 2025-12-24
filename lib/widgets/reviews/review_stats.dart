import 'package:flutter/material.dart';
import '../../models.dart';
import 'star_rating.dart';

/// Review Statistics Widget
///
/// Displays aggregate review statistics including average rating and total count.
class ReviewStatsWidget extends StatelessWidget {
  final ReviewStats stats;
  final VoidCallback? onTap;

  const ReviewStatsWidget({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Average rating and stars
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      stats.averageRating.toStringAsFixed(1),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ 5.0',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                StarRating(
                  rating: stats.averageRating,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Total reviews count
            Expanded(
              child: Text(
                '${stats.totalReviews} ${stats.totalReviews == 1 ? 'review' : 'reviews'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Arrow icon if tappable
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact Review Stats Badge
///
/// A smaller version showing just the rating and count.
class ReviewStatsBadge extends StatelessWidget {
  final ReviewStats stats;

  const ReviewStatsBadge({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stats.totalReviews == 0) {
      return Text(
        'No reviews yet',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          stats.averageRating.toStringAsFixed(1),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${stats.totalReviews})',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
