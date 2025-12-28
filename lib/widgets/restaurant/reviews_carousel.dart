import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models.dart';
import '../reviews/star_rating.dart';

/// Reviews Carousel Section Widget
///
/// Displays a horizontal scrollable preview of recent reviews.
/// Shows up to 5 reviews with user avatar, rating, comment, and date.
class ReviewsCarousel extends StatelessWidget {
  final Future<List<Review>>? reviewsFuture;
  final bool isTraditionalChinese;

  const ReviewsCarousel({
    required this.reviewsFuture,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          // Log error but don't show to user
          debugPrint('Error loading reviews: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(isTraditionalChinese ? '暫無評論' : 'No reviews yet', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(isTraditionalChinese ? '暫無評論' : 'No reviews yet', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }
        final reviews = snapshot.data!.take(5).toList();
        return SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _ReviewPreviewCard(review: reviews[index], isTraditionalChinese: isTraditionalChinese),
          ),
        );
      },
    );
  }
}

/// Review Preview Card for carousel display
class _ReviewPreviewCard extends StatelessWidget {
  final Review review;
  final bool isTraditionalChinese;

  const _ReviewPreviewCard({required this.review, required this.isTraditionalChinese});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: review.userPhotoURL != null ? NetworkImage(review.userPhotoURL!) : null,
                child: review.userPhotoURL == null ? const Icon(Icons.person, size: 20) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userDisplayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    StarRating(rating: review.rating, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              review.comment ?? (isTraditionalChinese ? '無評論內容' : 'No comment'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(DateFormat('yyyy-MM-dd').format(review.dateTime), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}
