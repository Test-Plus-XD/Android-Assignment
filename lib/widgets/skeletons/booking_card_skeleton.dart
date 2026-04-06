import 'package:flutter/material.dart';
import 'skeleton_box.dart';

/// Skeleton for [BookingCard].
/// Mirrors the card layout: status badge, restaurant name, date/time rows,
/// guests row, and two action buttons.
class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg =
        isDark ? Colors.grey[850]! : Theme.of(context).cardColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surfaceBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 80, height: 24, borderRadius: 12),
                SkeletonBox(width: 24, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 12),
            // Restaurant name
            const SkeletonBox(width: 200, height: 20, borderRadius: 4),
            const SizedBox(height: 10),
            // Date row
            Row(
              children: const [
                SkeletonBox(width: 18, height: 18, borderRadius: 4),
                SizedBox(width: 8),
                SkeletonBox(width: 140, height: 14, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 8),
            // Time row
            Row(
              children: const [
                SkeletonBox(width: 18, height: 18, borderRadius: 4),
                SizedBox(width: 8),
                SkeletonBox(width: 80, height: 14, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 8),
            // Guests row
            Row(
              children: const [
                SkeletonBox(width: 18, height: 18, borderRadius: 4),
                SizedBox(width: 8),
                SkeletonBox(width: 60, height: 14, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: const [
                Expanded(
                  child: SkeletonBox(height: 36, width: double.infinity, borderRadius: 8),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SkeletonBox(height: 36, width: double.infinity, borderRadius: 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows [count] [BookingCardSkeleton] items wrapped in a
/// [SkeletonWithLoader] (shimmer + Eclipse.gif).
class BookingListSkeleton extends StatelessWidget {
  const BookingListSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonWithLoader(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (_) => const BookingCardSkeleton()),
      ),
    );
  }
}
