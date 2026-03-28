import 'package:flutter/material.dart';
import 'skeleton_box.dart';

// ---------------------------------------------------------------------------
// Menu preview skeleton
// ---------------------------------------------------------------------------

/// Skeleton for a single menu-item card in the horizontal preview carousel.
/// Mirrors the 120 × 160 px card layout.
class _MenuItemCardSkeleton extends StatelessWidget {
  const _MenuItemCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 120,
          height: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 120, height: 100, color: base),
              Expanded(
                child: Container(
                  width: 120,
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  padding: const EdgeInsets.all(8),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 90, height: 12, borderRadius: 4),
                      SizedBox(height: 4),
                      SkeletonBox(width: 50, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the menu-preview horizontal scroll section.
/// Shows [count] menu-item placeholders wrapped in [SkeletonWithLoader].
class MenuPreviewSkeleton extends StatelessWidget {
  const MenuPreviewSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonWithLoader(
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: count,
          itemBuilder: (_, __) => const _MenuItemCardSkeleton(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Review stats skeleton
// ---------------------------------------------------------------------------

/// Skeleton for the review-stats section (average score + star row +
/// total-count line).
class ReviewStatsSkeleton extends StatelessWidget {
  const ReviewStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonWithLoader(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Big score
            const SkeletonBox(width: 48, height: 48, borderRadius: 8),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // Stars
                Row(
                  children: [
                    SkeletonBox(width: 20, height: 18, borderRadius: 4),
                    SizedBox(width: 4),
                    SkeletonBox(width: 20, height: 18, borderRadius: 4),
                    SizedBox(width: 4),
                    SkeletonBox(width: 20, height: 18, borderRadius: 4),
                    SizedBox(width: 4),
                    SkeletonBox(width: 20, height: 18, borderRadius: 4),
                    SizedBox(width: 4),
                    SkeletonBox(width: 20, height: 18, borderRadius: 4),
                  ],
                ),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 12, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reviews carousel skeleton
// ---------------------------------------------------------------------------

/// Skeleton for a single review card in the reviews carousel.
class _ReviewCardSkeleton extends StatelessWidget {
  const _ReviewCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer row: avatar + name
          Row(
            children: const [
              SkeletonBox(width: 36, height: 36, borderRadius: 18),
              SizedBox(width: 10),
              SkeletonBox(width: 100, height: 14, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 8),
          // Star row
          const Row(
            children: [
              SkeletonBox(width: 18, height: 16, borderRadius: 4),
              SizedBox(width: 3),
              SkeletonBox(width: 18, height: 16, borderRadius: 4),
              SizedBox(width: 3),
              SkeletonBox(width: 18, height: 16, borderRadius: 4),
              SizedBox(width: 3),
              SkeletonBox(width: 18, height: 16, borderRadius: 4),
              SizedBox(width: 3),
              SkeletonBox(width: 18, height: 16, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 8),
          const SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
          const SizedBox(height: 4),
          const SkeletonBox(width: 160, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Skeleton for the reviews horizontal carousel.
/// Shows [count] review card placeholders wrapped in [SkeletonWithLoader].
class ReviewsCarouselSkeleton extends StatelessWidget {
  const ReviewsCarouselSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonWithLoader(
      child: SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: count,
          itemBuilder: (_, __) => const _ReviewCardSkeleton(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Store statistics skeleton
// ---------------------------------------------------------------------------

/// Skeleton for the two statistics cards (menu count + today's bookings)
/// on the Store page dashboard.
class StoreStatsSkeleton extends StatelessWidget {
  const StoreStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonWithLoader(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonBox(width: 40, height: 24, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonBox(width: 40, height: 24, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
