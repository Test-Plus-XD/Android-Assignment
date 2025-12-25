import 'package:flutter/material.dart';
import '../../models.dart';
import '../reviews/review_stats.dart';

/// Restaurant Info Card Widget
///
/// Displays main restaurant information in an elegant card format.
/// Features:
/// - Restaurant name with rating
/// - Address with tap-to-navigate
/// - District and keywords
/// - Seating capacity
class RestaurantInfoCard extends StatelessWidget {
  final Restaurant restaurant;
  final String name;
  final String address;
  final String district;
  final List<String> keywords;
  final bool isTraditionalChinese;
  final VoidCallback? onAddressTap;
  final ReviewStats? reviewStats;

  const RestaurantInfoCard({
    required this.restaurant,
    required this.name,
    required this.address,
    required this.district,
    required this.keywords,
    required this.isTraditionalChinese,
    this.onAddressTap,
    this.reviewStats,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant name with rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (reviewStats != null && reviewStats!.totalReviews > 0)
                  ReviewStatsBadge(stats: reviewStats!),
              ],
            ),

            const SizedBox(height: 16),

            // Address
            InkWell(
              onTap: onAddressTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // District
            Row(
              children: [
                Icon(
                  Icons.map,
                  size: 18,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  district,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // Seating capacity
            if (restaurant.seats != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event_seat,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isTraditionalChinese ? "座位數量" : "Seats"}: ${restaurant.seats}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            // Keywords
            if (keywords.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: keywords
                    .map(
                      (keyword) => Chip(
                    label: Text(keyword),
                    backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: 12,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
