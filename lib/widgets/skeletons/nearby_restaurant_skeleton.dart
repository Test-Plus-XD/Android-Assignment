import 'package:flutter/material.dart';
import 'skeleton_box.dart';

/// Skeleton for a single nearby-restaurant card on the Home page.
/// Mirrors the 160 × 200 px horizontal-scroll card layout:
///  - 100 px image area
///  - distance badge (top-right)
///  - two text lines below
class NearbyRestaurantCardSkeleton extends StatelessWidget {
  const NearbyRestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 160,
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              Stack(
                children: [
                  Container(width: 160, height: 100, color: base),
                  // Distance badge top-right
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: SkeletonBox(width: 44, height: 22, borderRadius: 11),
                  ),
                ],
              ),
              // Text area
              Container(
                width: 160,
                height: 100,
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                padding: const EdgeInsets.all(10),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 120, height: 14, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [count] nearby-restaurant skeleton cards in a horizontal row
/// wrapped in a [SkeletonWithLoader] (shimmer + Eclipse.gif on top).
class NearbyRestaurantsSkeleton extends StatelessWidget {
  const NearbyRestaurantsSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonWithLoader(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: count,
          itemBuilder: (_, __) => const NearbyRestaurantCardSkeleton(),
        ),
      ),
    );
  }
}
