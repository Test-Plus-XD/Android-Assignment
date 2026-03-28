import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A single rectangular placeholder used inside skeleton layouts.
/// Must be a descendant of a [Shimmer] widget to animate.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Wraps [child] in a shimmer animation sized to fill its parent.
/// Applies theme-aware base/highlight colours.
///
/// Use this as the outer wrapper when an entire section needs to shimmer
/// (e.g. a full card or a list of items). Individual placeholder boxes
/// inside the child should be plain [SkeletonBox] widgets.
class SkeletonShimmer extends StatelessWidget {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: child,
    );
  }
}

/// Convenience: wraps content in [SkeletonShimmer] and stacks the
/// Eclipse.gif [LoadingIndicator] on top, centred.
///
/// Use this at the top-level skeleton for a section so the branded
/// gif plays while the shimmer shows the structural placeholder.
class SkeletonWithLoader extends StatelessWidget {
  const SkeletonWithLoader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SkeletonShimmer(child: child),
        // Eclipse.gif stays on top
        Image.asset(
          'assets/images/Eclipse.gif',
          width: 60,
          height: 60,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
