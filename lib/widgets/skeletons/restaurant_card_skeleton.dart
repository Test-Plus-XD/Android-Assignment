import 'package:flutter/material.dart';
import 'skeleton_box.dart';

/// Skeleton for [RestaurantSearchCard] — 220 px tall full-width card
/// that mirrors the hero-image + gradient overlay + text layout.
///
/// Wrap a list of these in [SkeletonWithLoader] to show the Eclipse.gif
/// on top while shimmer plays in the background.
class RestaurantSearchCardSkeleton extends StatelessWidget {
  const RestaurantSearchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 220,
          child: Stack(
            children: [
              // Background (image area)
              Container(color: base),
              // Simulated gradient overlay at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        (isDark ? Colors.grey[900]! : Colors.grey[400]!)
                            .withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // Text placeholders — bottom-left
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 180, height: 18, borderRadius: 4),
                    SizedBox(height: 8),
                    // Keywords row
                    Row(
                      children: [
                        SkeletonBox(width: 60, height: 22, borderRadius: 11),
                        SizedBox(width: 6),
                        SkeletonBox(width: 60, height: 22, borderRadius: 11),
                        SizedBox(width: 6),
                        SkeletonBox(width: 60, height: 22, borderRadius: 11),
                      ],
                    ),
                    SizedBox(height: 8),
                    SkeletonBox(width: 120, height: 12, borderRadius: 4),
                    SizedBox(height: 4),
                    SkeletonBox(width: 150, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              // Status badge — top-left
              const Positioned(
                top: 10,
                left: 12,
                child: SkeletonBox(width: 56, height: 22, borderRadius: 11),
              ),
              // Rating badge — top-right
              const Positioned(
                top: 10,
                right: 12,
                child: SkeletonBox(width: 56, height: 22, borderRadius: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a carousel card (85 % viewport width, 220 px tall).
/// Used on the Home page's Featured Restaurants carousel.
class RestaurantCarouselCardSkeleton extends StatelessWidget {
  const RestaurantCarouselCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final width = MediaQuery.of(context).size.width * 0.85;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: 220,
          child: Stack(
            children: [
              Container(color: base),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        (isDark ? Colors.grey[900]! : Colors.grey[400]!)
                            .withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 150, height: 16, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 100, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        SkeletonBox(width: 50, height: 18, borderRadius: 9),
                        SizedBox(width: 4),
                        SkeletonBox(width: 50, height: 18, borderRadius: 9),
                      ],
                    ),
                  ],
                ),
              ),
              // Badges
              const Positioned(
                top: 8,
                left: 10,
                child: SkeletonBox(width: 50, height: 20, borderRadius: 10),
              ),
              const Positioned(
                top: 8,
                right: 10,
                child: SkeletonBox(width: 50, height: 20, borderRadius: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [count] [RestaurantSearchCardSkeleton] items wrapped in a
/// [SkeletonWithLoader] (shimmer + Eclipse.gif on top).
class RestaurantSearchListSkeleton extends StatelessWidget {
  const RestaurantSearchListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonWithLoader(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (_) => const RestaurantSearchCardSkeleton()),
      ),
    );
  }
}

/// Shows [count] carousel card skeletons in a horizontal row wrapped in
/// a [SkeletonWithLoader].
class RestaurantCarouselSkeleton extends StatelessWidget {
  const RestaurantCarouselSkeleton({super.key, this.count = 2});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonWithLoader(
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: count,
          itemBuilder: (_, __) => const RestaurantCarouselCardSkeleton(),
        ),
      ),
    );
  }
}
