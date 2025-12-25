import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Hero Image Section Widget
///
/// Displays restaurant's hero image with overlay gradient and floating info badge.
/// Features:
/// - Large hero image with aspect ratio control
/// - Gradient overlay for better text readability
/// - Distance badge overlay
/// - Smooth loading with placeholder
class HeroImageSection extends StatelessWidget {
  final String? imageUrl;
  final String? distanceText;
  final bool isTraditionalChinese;

  const HeroImageSection({
    required this.imageUrl,
    this.distanceText,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hero image
        CachedNetworkImage(
          imageUrl: imageUrl ?? '',
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade400,
                ],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade400,
                ],
              ),
            ),
            child: const Center(
              child: Icon(Icons.restaurant, size: 80, color: Colors.white),
            ),
          ),
        ),

        // Bottom gradient overlay for better contrast
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),

        // Distance badge overlay
        if (distanceText != null)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    distanceText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
