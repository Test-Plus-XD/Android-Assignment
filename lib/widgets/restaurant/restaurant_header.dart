import 'package:flutter/material.dart';
import '../../models.dart';

/// Restaurant Header Widget
///
/// Displays restaurant name, rating, and distance information
class RestaurantHeader extends StatelessWidget {
  final String restaurantName;
  final ReviewStats? reviewStats;
  final String? distanceText;
  final bool isTraditionalChinese;

  const RestaurantHeader({
    required this.restaurantName,
    this.reviewStats,
    this.distanceText,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = reviewStats?.averageRating ?? 0.0;
    final count = reviewStats?.totalReviews ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurantName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Half-star row + numeric rating + review count + vegetarian tag
              Row(
                children: [
                  ..._buildHalfStarIcons(rating),
                  const SizedBox(width: 6),
                  Text(
                    rating > 0
                        ? rating.toStringAsFixed(1)
                        : (isTraditionalChinese ? '新開張' : 'New'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '($count ${isTraditionalChinese ? '評論' : 'reviews'})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  const Text('•'),
                  const SizedBox(width: 8),
                  Text(
                    isTraditionalChinese ? '素食' : 'Vegetarian',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Distance indicator
        if (distanceText != null)
          Chip(
            avatar: const Icon(Icons.location_on, size: 16),
            label: Text(distanceText!),
            backgroundColor: theme.colorScheme.primaryContainer,
          ),
      ],
    );
  }

  /// Builds a row of 5 star icons rounded to nearest 0.5
  List<Widget> _buildHalfStarIcons(double rating) {
    if (rating <= 0) return [];
    final rounded = (rating * 2).round() / 2;
    final full = rounded.floor();
    final hasHalf = rounded - full > 0;
    final empty = 5 - full - (hasHalf ? 1 : 0);
    return [
      for (int i = 0; i < full; i++)
        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
      if (hasHalf)
        const Icon(Icons.star_half_rounded, color: Colors.amber, size: 18),
      for (int i = 0; i < empty; i++)
        const Icon(Icons.star_outline_rounded, color: Colors.amber, size: 18),
    ];
  }
}