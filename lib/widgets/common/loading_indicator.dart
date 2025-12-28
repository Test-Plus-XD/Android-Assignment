import 'package:flutter/material.dart';

/// Custom Loading Indicator using Eclipse.gif
///
/// A reusable loading widget that displays the Eclipse.gif animation
/// instead of the default CircularProgressIndicator.
///
/// Usage:
/// - LoadingIndicator() - Default size (60x60)
/// - LoadingIndicator.small() - Small size (24x24)
/// - LoadingIndicator.large() - Large size (80x80)
/// - LoadingIndicator(size: 40) - Custom size
class LoadingIndicator extends StatelessWidget {
  /// Size of the loading indicator
  final double size;
  /// Optional colour overlay (not typically needed for gif)
  final Color? color;

  const LoadingIndicator({
    this.size = 60.0,
    this.color,
    super.key,
  });

  /// Small loading indicator (24x24)
  const LoadingIndicator.small({
    this.size = 24.0,
    this.color,
    super.key,
  });

  /// Large loading indicator (80x80)
  const LoadingIndicator.large({
    this.size = 80.0,
    this.color,
    super.key,
  });

  /// Extra small loading indicator (16x16) for buttons
  const LoadingIndicator.extraSmall({
    this.size = 16.0,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget loadingWidget = Image.asset(
      'assets/images/Eclipse.gif',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    // Apply colour filter if specified
    if (color != null) {
      loadingWidget = ColorFiltered(
        colorFilter: ColorFilter.mode(
          color!,
          BlendMode.srcATop,
        ),
        child: loadingWidget,
      );
    }

    return loadingWidget;
  }
}

/// Loading Indicator with Centre wrapper
///
/// Convenience widget that centres the loading indicator.
/// Useful for replacing Center(child: CircularProgressIndicator()) patterns.
class CenteredLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const CenteredLoadingIndicator({
    this.size = 60.0,
    this.color,
    super.key,
  });

  const CenteredLoadingIndicator.small({
    this.size = 24.0,
    this.color,
    super.key,
  });

  const CenteredLoadingIndicator.large({
    this.size = 80.0,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingIndicator(
        size: size,
        color: color,
      ),
    );
  }
}